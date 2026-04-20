import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/faculty_model.dart';
import '../models/lecture_assignment_model.dart';
import '../models/substitution_model.dart';
import '../models/timetable_day_model.dart';
import '../models/time_slot_model.dart';
import 'storage_service.dart';

class SubstitutionService {
  final ApiClient _apiClient;
  final StorageService _storageService;

  SubstitutionService(this._apiClient, this._storageService);

  Future<List<SubstitutionRecordModel>> fetchSubstitutions({
    DateTime? date,
    int? facultyId,
    String? status,
  }) async {
    final query = <String, dynamic>{
      if (date != null) 'date': _formatDate(date),
      if (facultyId != null) 'facultyId': facultyId,
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
    };

    try {
      final response = await _apiClient.get(
        ApiEndpoints.substitutions,
        queryParameters: query.isEmpty ? null : query,
      );

      final list = _extractList(response.data);
      final records = list
          .whereType<Map>()
          .map((e) => SubstitutionRecordModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      records.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
      await _storageService.saveSubstitutionRecords(
        records.map((e) => e.toJson()).toList(growable: false),
      );
      return _filterRecords(records, date: date, facultyId: facultyId, status: status);
    } catch (_) {
      final cached = await _storageService.getSubstitutionRecords();
      final records = (cached ?? const <Map<String, dynamic>>[])
          .map(SubstitutionRecordModel.fromJson)
          .toList();
      return _filterRecords(records, date: date, facultyId: facultyId, status: status);
    }
  }

  Future<List<SubstitutionCandidateModel>> previewCandidates({
    required LectureAssignmentModel lecture,
    required TimeSlotModel slot,
    required String dayName,
    required DateTime date,
    required List<FacultyModel> facultyPool,
    required List<TimetableDay> weeklyTimetable,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.substitutionsPreview,
        data: {
          'lectureId': lecture.id,
          'slotId': slot.id,
          'dayName': dayName,
          'date': _formatDate(date),
          if (lecture.facultyId != null) 'unavailableFacultyId': lecture.facultyId,
        },
      );

      final list = _extractList(response.data);
      final candidates = list
          .whereType<Map>()
          .map((e) => SubstitutionCandidateModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (candidates.isNotEmpty) {
        candidates.sort((a, b) => b.score.compareTo(a.score));
        return candidates;
      }
    } catch (_) {
      // Fallback to local heuristic preview.
    }

    return _buildHeuristicCandidates(
      lecture: lecture,
      slot: slot,
      dayName: dayName,
      facultyPool: facultyPool,
      weeklyTimetable: weeklyTimetable,
    );
  }

  Future<SubstitutionRecordModel> createSubstitution({
    required LectureAssignmentModel lecture,
    required TimeSlotModel slot,
    required String dayName,
    required DateTime date,
    required int substituteFacultyId,
    required String substituteFacultyName,
    String? reason,
    bool autoApprove = true,
    int? approvedBy,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final payload = <String, dynamic>{
      'lectureId': lecture.id,
      'slotId': slot.id,
      'date': _formatDate(date),
      'dayName': dayName,
      'temporaryOnly': true,
      'autoApprove': autoApprove,
      'substituteFacultyId': substituteFacultyId,
      'substituteFacultyName': substituteFacultyName,
      if (lecture.facultyId != null) 'originalFacultyId': lecture.facultyId,
      if (lecture.facultyName != null) 'originalFacultyName': lecture.facultyName,
      if (lecture.subjectCode != null) 'subjectCode': lecture.subjectCode,
      if (lecture.subjectName != null) 'subjectName': lecture.subjectName,
      if (lecture.typeOfLecture != null) 'lectureType': lecture.typeOfLecture,
      if (lecture.roomNumber != null) 'roomNumber': lecture.roomNumber,
      if (lecture.batch != null) 'batch': lecture.batch,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      'notifyAssignedFaculty': true,
      if (approvedBy != null) 'approvedBy': approvedBy,
    };

    try {
      final response = await _apiClient.post(
        ApiEndpoints.substitutions,
        data: payload,
      );

      final body = response.data;
      final raw = body is Map<String, dynamic> ? body['data'] : null;
      SubstitutionRecordModel record;

      if (raw is Map<String, dynamic>) {
        record = SubstitutionRecordModel.fromJson(raw);
      } else {
        record = _buildLocalRecord(
          lecture: lecture,
          slot: slot,
          dayName: dayName,
          date: date,
          substituteFacultyId: substituteFacultyId,
          substituteFacultyName: substituteFacultyName,
          reason: reason,
          createdAt: nowIso,
          status: autoApprove ? 'approved' : 'pending',
          approvedBy: approvedBy,
          approvedAt: autoApprove ? nowIso : null,
        );
      }

      if (autoApprove && !record.isApproved) {
        record = await approveSubstitution(record.id, approvedBy: approvedBy);
      }

      await _upsertLocalRecord(record);
      return record;
    } catch (_) {
      var local = _buildLocalRecord(
        lecture: lecture,
        slot: slot,
        dayName: dayName,
        date: date,
        substituteFacultyId: substituteFacultyId,
        substituteFacultyName: substituteFacultyName,
        reason: reason,
        createdAt: nowIso,
        status: autoApprove ? 'approved' : 'pending',
        approvedBy: approvedBy,
        approvedAt: autoApprove ? nowIso : null,
      );

      if (autoApprove && !local.isApproved) {
        local = local.copyWith(
          status: 'approved',
          approvedBy: approvedBy,
          approvedAt: nowIso,
        );
      }

      await _upsertLocalRecord(local);
      return local;
    }
  }

  Future<SubstitutionRecordModel> approveSubstitution(
    int substitutionId, {
    int? approvedBy,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    try {
      final response = await _apiClient.post(
        '${ApiEndpoints.substitutions}/$substitutionId/approve',
        data: {
          if (approvedBy != null) 'approvedBy': approvedBy,
        },
      );

      final body = response.data;
      final raw = body is Map<String, dynamic> ? body['data'] : null;

      if (raw is Map<String, dynamic>) {
        final record = SubstitutionRecordModel.fromJson(raw);
        await _upsertLocalRecord(record);
        return record;
      }
    } catch (_) {
      // Fallback to local cache update.
    }

    final cached = await _storageService.getSubstitutionRecords();
    final list = (cached ?? const <Map<String, dynamic>>[])
        .map(SubstitutionRecordModel.fromJson)
        .toList();

    final index = list.indexWhere((e) => e.id == substitutionId);
    if (index == -1) {
      final synthetic = SubstitutionRecordModel(
        id: substitutionId,
        lectureId: 0,
        slotId: 0,
        date: _formatDate(DateTime.now()),
        dayName: '',
        substituteFacultyId: 0,
        status: 'approved',
        approvedBy: approvedBy,
        approvedAt: nowIso,
      );
      await _upsertLocalRecord(synthetic);
      return synthetic;
    }

    final updated = list[index].copyWith(
      status: 'approved',
      approvedBy: approvedBy,
      approvedAt: nowIso,
    );

    list[index] = updated;
    await _storageService.saveSubstitutionRecords(
      list.map((e) => e.toJson()).toList(growable: false),
    );
    return updated;
  }

  List<SubstitutionCandidateModel> _buildHeuristicCandidates({
    required LectureAssignmentModel lecture,
    required TimeSlotModel slot,
    required String dayName,
    required List<FacultyModel> facultyPool,
    required List<TimetableDay> weeklyTimetable,
  }) {
    final unavailableFacultyId = lecture.facultyId;

    final weeklyLoadByFaculty = <int, int>{};
    for (final day in weeklyTimetable) {
      for (final timeslot in day.slots) {
        for (final assigned in timeslot.lectures) {
          final fid = assigned.facultyId;
          if (fid == null) continue;
          weeklyLoadByFaculty[fid] = (weeklyLoadByFaculty[fid] ?? 0) + 1;
        }
      }
    }

    final candidates = facultyPool
        .where((f) => f.facultyId != unavailableFacultyId)
        .map((f) {
          final fid = f.facultyId;
          final load = weeklyLoadByFaculty[fid] ?? 0;
          final hasConflict = _facultyHasConflictOnSlot(
            facultyId: fid,
            dayName: dayName,
            targetSlot: slot,
            weeklyTimetable: weeklyTimetable,
          );

          final score = 100 - (hasConflict ? 80 : 0) - (load * 1.5);
          final summary = hasConflict
              ? 'Already assigned around this slot. Load: $load/week.'
              : 'No immediate conflict detected. Load: $load/week.';

          return SubstitutionCandidateModel(
            facultyId: fid,
            facultyName: f.name,
            score: score,
            hasConflict: hasConflict,
            weeklyLoad: load,
            summary: summary,
          );
        })
        .toList();

    candidates.sort((a, b) {
      if (a.hasConflict != b.hasConflict) {
        return a.hasConflict ? 1 : -1;
      }
      return b.score.compareTo(a.score);
    });

    return candidates.take(8).toList(growable: false);
  }

  bool _facultyHasConflictOnSlot({
    required int facultyId,
    required String dayName,
    required TimeSlotModel targetSlot,
    required List<TimetableDay> weeklyTimetable,
  }) {
    TimetableDay? selectedDay;
    try {
      selectedDay = weeklyTimetable.firstWhere(
        (d) => d.dayName.toLowerCase() == dayName.toLowerCase(),
      );
    } catch (_) {
      selectedDay = null;
    }

    if (selectedDay == null) return false;

    for (final slot in selectedDay.slots) {
      if (!_isTimeOverlap(slot, targetSlot)) continue;
      for (final lecture in slot.lectures) {
        if (lecture.facultyId == facultyId) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isTimeOverlap(TimeSlotModel a, TimeSlotModel b) {
    final aStart = (a.startTimeHr * 60) + a.startTimeMinutes;
    final aEnd = (a.endTimeHr * 60) + a.endTimeMinutes;
    final bStart = (b.startTimeHr * 60) + b.startTimeMinutes;
    final bEnd = (b.endTimeHr * 60) + b.endTimeMinutes;
    return aStart < bEnd && bStart < aEnd;
  }

  List<SubstitutionRecordModel> _filterRecords(
    List<SubstitutionRecordModel> records, {
    DateTime? date,
    int? facultyId,
    String? status,
  }) {
    return records.where((record) {
      final matchesDate = date == null || record.matchesDate(date);
      final matchesFaculty =
          facultyId == null ||
          record.originalFacultyId == facultyId ||
          record.substituteFacultyId == facultyId;
      final matchesStatus =
          status == null ||
          status.trim().isEmpty ||
          record.normalizedStatus == status.trim().toLowerCase();
      return matchesDate && matchesFaculty && matchesStatus;
    }).toList(growable: false);
  }

  Future<void> _upsertLocalRecord(SubstitutionRecordModel record) async {
    final cached = await _storageService.getSubstitutionRecords();
    final list = (cached ?? const <Map<String, dynamic>>[])
        .map(SubstitutionRecordModel.fromJson)
        .toList();

    final index = list.indexWhere((e) => e.id == record.id);
    if (index == -1) {
      list.add(record);
    } else {
      list[index] = record;
    }

    list.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

    await _storageService.saveSubstitutionRecords(
      list.map((e) => e.toJson()).toList(growable: false),
    );
  }

  SubstitutionRecordModel _buildLocalRecord({
    required LectureAssignmentModel lecture,
    required TimeSlotModel slot,
    required String dayName,
    required DateTime date,
    required int substituteFacultyId,
    required String substituteFacultyName,
    required String? reason,
    required String createdAt,
    required String status,
    required int? approvedBy,
    required String? approvedAt,
  }) {
    return SubstitutionRecordModel(
      id: -DateTime.now().microsecondsSinceEpoch,
      lectureId: lecture.id,
      slotId: slot.id,
      date: _formatDate(date),
      dayName: dayName,
      originalFacultyId: lecture.facultyId,
      originalFacultyName: lecture.facultyName,
      substituteFacultyId: substituteFacultyId,
      substituteFacultyName: substituteFacultyName,
      subjectCode: lecture.subjectCode,
      subjectName: lecture.subjectName,
      roomNumber: lecture.roomNumber,
      batch: lecture.batch,
      lectureType: lecture.typeOfLecture,
      reason: reason,
      status: status,
      createdAt: createdAt,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      temporaryOnly: true,
    );
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final candidates = body['candidates'];
      if (candidates is List) return candidates;

      final data = body['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        final nestedCandidates = data['candidates'];
        if (nestedCandidates is List) return nestedCandidates;

        final rows = data['rows'];
        if (rows is List) return rows;
      }
    }
    return const [];
  }

  String _formatDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

final substitutionServiceProvider = Provider<SubstitutionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storageService = ref.watch(storageServiceProvider);
  return SubstitutionService(apiClient, storageService);
});
