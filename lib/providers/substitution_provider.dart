import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/faculty_model.dart';
import '../models/lecture_assignment_model.dart';
import '../models/substitution_model.dart';
import '../models/timetable_day_model.dart';
import '../models/time_slot_model.dart';
import '../services/substitution_service.dart';

enum SubstitutionStatus { initial, loading, loaded, error }

class SubstitutionState {
  final SubstitutionStatus status;
  final List<SubstitutionRecordModel> records;
  final List<SubstitutionCandidateModel> previewCandidates;
  final DateTime selectedDate;
  final bool isSubmitting;
  final String? errorMessage;

  SubstitutionState({
    this.status = SubstitutionStatus.initial,
    this.records = const [],
    this.previewCandidates = const [],
    DateTime? selectedDate,
    this.isSubmitting = false,
    this.errorMessage,
  }) : selectedDate = selectedDate ?? DateTime.now();

  SubstitutionState copyWith({
    SubstitutionStatus? status,
    List<SubstitutionRecordModel>? records,
    List<SubstitutionCandidateModel>? previewCandidates,
    DateTime? selectedDate,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return SubstitutionState(
      status: status ?? this.status,
      records: records ?? this.records,
      previewCandidates: previewCandidates ?? this.previewCandidates,
      selectedDate: selectedDate ?? this.selectedDate,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  List<SubstitutionRecordModel> approvedForDate(DateTime date) {
    return records
        .where((e) => e.isApproved && e.matchesDate(date))
        .toList(growable: false);
  }

  SubstitutionRecordModel? approvedForLectureOnDate({
    required int lectureId,
    required DateTime date,
  }) {
    try {
      return records.firstWhere(
        (e) => e.lectureId == lectureId && e.isApproved && e.matchesDate(date),
      );
    } catch (_) {
      return null;
    }
  }
}

class SubstitutionNotifier extends StateNotifier<SubstitutionState> {
  final SubstitutionService _service;

  SubstitutionNotifier(this._service) : super(SubstitutionState());

  Future<void> loadForDate(DateTime date, {int? facultyId}) async {
    state = state.copyWith(
      status: SubstitutionStatus.loading,
      selectedDate: date,
      errorMessage: null,
    );

    try {
      final records = await _service.fetchSubstitutions(
        date: date,
        facultyId: facultyId,
      );
      state = state.copyWith(
        status: SubstitutionStatus.loaded,
        records: records,
        selectedDate: date,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: SubstitutionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadRecent({int? facultyId}) async {
    state = state.copyWith(status: SubstitutionStatus.loading, errorMessage: null);
    try {
      final records = await _service.fetchSubstitutions(facultyId: facultyId);
      state = state.copyWith(
        status: SubstitutionStatus.loaded,
        records: records,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: SubstitutionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> previewCandidates({
    required LectureAssignmentModel lecture,
    required TimeSlotModel slot,
    required String dayName,
    required DateTime date,
    required List<TimetableDay> weeklyTimetable,
    required List<FacultyModel> faculty,
  }) async {
    try {
      final candidates = await _service.previewCandidates(
        lecture: lecture,
        slot: slot,
        dayName: dayName,
        date: date,
        facultyPool: faculty,
        weeklyTimetable: weeklyTimetable,
      );
      state = state.copyWith(
        previewCandidates: candidates,
        selectedDate: date,
        errorMessage: null,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        previewCandidates: const [],
        errorMessage: e.toString(),
      );
    }
  }

  Future<SubstitutionRecordModel?> createAndApprove({
    required LectureAssignmentModel lecture,
    required TimeSlotModel slot,
    required String dayName,
    required DateTime date,
    required int substituteFacultyId,
    required String substituteFacultyName,
    String? reason,
    int? approvedBy,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final created = await _service.createSubstitution(
        lecture: lecture,
        slot: slot,
        dayName: dayName,
        date: date,
        substituteFacultyId: substituteFacultyId,
        substituteFacultyName: substituteFacultyName,
        reason: reason,
        autoApprove: true,
        approvedBy: approvedBy,
      );

      final next = [...state.records];
      final index = next.indexWhere((e) => e.id == created.id);
      if (index == -1) {
        next.insert(0, created);
      } else {
        next[index] = created;
      }

      state = state.copyWith(
        isSubmitting: false,
        records: next,
        previewCandidates: const [],
        selectedDate: date,
      );
      return created;
    } on Exception catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<SubstitutionRecordModel?> approveSubstitution(
    int substitutionId, {
    int? approvedBy,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final updated = await _service.approveSubstitution(
        substitutionId,
        approvedBy: approvedBy,
      );

      final next = [...state.records];
      final index = next.indexWhere((e) => e.id == updated.id);
      if (index == -1) {
        next.insert(0, updated);
      } else {
        next[index] = updated;
      }

      state = state.copyWith(isSubmitting: false, records: next);
      return updated;
    } on Exception catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return null;
    }
  }

  void clearPreview() {
    state = state.copyWith(previewCandidates: const []);
  }
}

final substitutionProvider =
    StateNotifierProvider<SubstitutionNotifier, SubstitutionState>((ref) {
  final service = ref.watch(substitutionServiceProvider);
  return SubstitutionNotifier(service);
});
