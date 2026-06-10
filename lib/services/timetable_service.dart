import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/timetable_model.dart';
import '../models/time_slot_model.dart';
import '../models/timetable_day_model.dart';

class TimetableService {
  final ApiClient _apiClient;

  TimetableService(this._apiClient);

  /// Fetch full weekly timetable.
  /// Returns list of [TimetableDay] (one per weekday).
  Future<List<TimetableDay>> fetchWeeklyTimetable({
    int? branchId,
    int? semester,
    String? division,
    String? academicYear,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.timetableWeekly,
      queryParameters: {
        if (branchId != null) 'branchId': branchId,
        if (semester != null) 'sem': semester,
        if (division != null) 'division': division,
      },
    );

    final data = response.data as Map<String, dynamic>;
    // Backend returns { success: true, data: [ {id, dateOfWeek, slots: [...]} ] }
    final List<dynamic> rawList = data['data'] as List<dynamic>? ?? [];
    return rawList.map((e) {
      final entry = e as Map<String, dynamic>;
      // Convert flat timetable entry with slots into TimetableDay format
      return TimetableDay.fromApiEntry(entry);
    }).toList();
  }

  /// Fetch today's timetable only.
  Future<TimetableDay?> fetchTodayTimetable({
    int? branchId,
    int? semester,
    String? division,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.timetableToday,
      queryParameters: {
        if (branchId != null) 'branchId': branchId,
        if (semester != null) 'sem': semester,
        if (division != null) 'division': division,
      },
    );

    final body = response.data as Map<String, dynamic>;
    final raw = body['data'];
    if (raw == null) return null;
    if (raw is List) {
      if (raw.isEmpty) return null;
      return TimetableDay.fromApiEntry(raw.first as Map<String, dynamic>);
    }
    return TimetableDay.fromApiEntry(raw as Map<String, dynamic>);
  }

  /// Fetch faculty personal timetable (for logged-in teacher).
  Future<List<TimetableDay>> fetchFacultyTimetable(int facultyId) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.facultyTimetable}/$facultyId',
    );
    final body = response.data as Map<String, dynamic>;
    final raw = body['data'];
    final List<dynamic> days = raw is List
        ? raw
        : raw is Map<String, dynamic>
            ? raw.entries
                .map((e) {
                  final dayVal = e.value as Map<String, dynamic>;
                  final rawSlots = dayVal['slots'];
                  List<dynamic> slotList = [];
                  if (rawSlots is List) {
                    slotList = rawSlots;
                  } else if (rawSlots is Map<String, dynamic>) {
                    slotList = rawSlots.values.map((s) {
                      final sMap = s as Map<String, dynamic>;
                      final slotDetails = sMap['slot'] as Map<String, dynamic>? ?? {};
                      final lecs = sMap['lectures'] as List<dynamic>? ?? [];
                      return {
                        ...slotDetails,
                        'lectures': lecs,
                      };
                    }).toList();
                  }
                  return {
                    'timetable': dayVal['timetable'],
                    'slots': slotList,
                  };
                })
                .toList()
            : [];
    return days
        .map((e) => TimetableDay.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch all timetable entries (admin view).
  Future<List<TimetableModel>> fetchAllTimetables() async {
    final response = await _apiClient.get(ApiEndpoints.timetable);
    final body = response.data as Map<String, dynamic>;
    final raw = body['data'];
    final List<dynamic> list = raw is List ? raw : [];
    return list
        .map((e) => TimetableModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch weekly timetable for a specific room.
  Future<List<TimetableDay>> fetchRoomWeeklyTimetable(
    String roomNumber, {
    int? branchId,
    int? semester,
    String? division,
  }) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.timetableRoomWeekly}/${Uri.encodeComponent(roomNumber)}/weekly',
      queryParameters: {
        if (branchId != null) 'branchId': branchId,
        if (semester != null) 'sem': semester,
        if (division != null) 'division': division,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final List<dynamic> rawList = data['data'] as List<dynamic>? ?? [];
    return rawList
        .map((e) => TimetableDay.fromApiEntry(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch room occupancy analytics for classroom usage reporting.
  Future<List<Map<String, dynamic>>> fetchClassroomUsageReport() async {
    final response = await _apiClient.get(ApiEndpoints.timetableClassroomUsageReport);
    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final rooms = data['rooms'];
      if (rooms is List) {
        return rooms
            .map((e) => (e as Map).map(
                  (k, v) => MapEntry(k.toString(), v),
                ))
            .toList();
      }
    }
    return const [];
  }

  /// Get time slots for a given timetable entry.
  Future<List<TimeSlotModel>> fetchTimeSlots(int timetableId) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.timeSlots}/$timetableId',
    );
    final body = response.data as Map<String, dynamic>;
    final raw = body['data'];
    final List<dynamic> list = raw is List ? raw : [];
    return list
        .map((e) => TimeSlotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Admin action: trigger timetable generation.
  Future<Map<String, dynamic>> generateTimetable({
    required int branchId,
    required int semester,
    required String division,
    required String academicYear,
    bool force = false,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.timetableGenerate,
      data: {
        'branchId': branchId,
        'sem': semester.toString(),
        'division': division,
        'academicYear': academicYear,
        if (force) 'force': true,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Admin action: generate all classes in one optimization run.
  Future<Map<String, dynamic>> generateAllTimetables({
    required String academicYear,
    List<String>? divisions,
    List<int>? branchIds,
    List<int>? semesters,
    String? termType,
    bool force = false,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.timetableGenerateAll,
      data: {
        'academicYear': academicYear,
        if (divisions != null && divisions.isNotEmpty) 'divisions': divisions,
        if (branchIds != null && branchIds.isNotEmpty) 'branchIds': branchIds,
        if (semesters != null && semesters.isNotEmpty) 'semesters': semesters,
        if (termType != null && termType.isNotEmpty) 'termType': termType,
        if (force) 'force': true,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Update a lecture assignment (admin/editor).
  Future<void> updateLectureSlot({
    required int slotId,
    required Map<String, dynamic> updates,
  }) async {
    await _apiClient.put(
      '${ApiEndpoints.timetableUpdateSlot}/$slotId',
      data: updates,
    );
  }

  /// Move/swap a lecture to another slot (used by drag-drop editing).
  Future<void> moveLectureSlot({
    required int lectureId,
    required int targetSlotId,
    bool swap = true,
  }) async {
    await _apiClient.put(
      '${ApiEndpoints.timetableMoveSlot}/$lectureId/move',
      data: {
        'targetSlotId': targetSlotId,
        'swap': swap,
      },
    );
  }
}

final timetableServiceProvider = Provider<TimetableService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TimetableService(apiClient);
});
