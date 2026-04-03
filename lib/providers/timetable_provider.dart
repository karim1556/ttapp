import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timetable_day_model.dart';
import '../services/timetable_service.dart';
import '../services/storage_service.dart';

enum TimetableStatus { initial, loading, loaded, error }

class TimetableState {
  final TimetableStatus status;
  final List<TimetableDay> weeklyTimetable;
  final TimetableDay? todayTimetable;
  final String? errorMessage;
  final bool isGenerating;
  final String? generateMessage;

  const TimetableState({
    this.status = TimetableStatus.initial,
    this.weeklyTimetable = const [],
    this.todayTimetable,
    this.errorMessage,
    this.isGenerating = false,
    this.generateMessage,
  });

  TimetableState copyWith({
    TimetableStatus? status,
    List<TimetableDay>? weeklyTimetable,
    TimetableDay? todayTimetable,
    String? errorMessage,
    bool? isGenerating,
    String? generateMessage,
  }) {
    return TimetableState(
      status: status ?? this.status,
      weeklyTimetable: weeklyTimetable ?? this.weeklyTimetable,
      todayTimetable: todayTimetable ?? this.todayTimetable,
      errorMessage: errorMessage ?? this.errorMessage,
      isGenerating: isGenerating ?? this.isGenerating,
      generateMessage: generateMessage ?? this.generateMessage,
    );
  }
}

class TimetableNotifier extends StateNotifier<TimetableState> {
  final TimetableService _timetableService;
  final StorageService _storageService;

  TimetableNotifier(this._timetableService, this._storageService)
      : super(const TimetableState());

  Future<void> loadWeeklyTimetable({
    int? branchId,
    int? semester,
    String? division,
    String? academicYear,
  }) async {
    state = state.copyWith(status: TimetableStatus.loading);
    try {
      // Only use the cache when no filters are applied (generic load).
      // When a specific division/branch/semester is selected we always go
      // straight to the API so stale data from a different division never
      // flashes on screen.
      final hasFilters = branchId != null || semester != null || division != null;

      if (!hasFilters) {
        final cached = await _storageService.getTimetableCache();
        if (cached != null && cached.isNotEmpty) {
          final cachedDays = cached
              .map((e) => TimetableDay.fromJson(e))
              .toList();
          state = state.copyWith(
            status: TimetableStatus.loaded,
            weeklyTimetable: cachedDays,
          );
        }
      }

      // Fetch fresh from API
      final days = await _timetableService.fetchWeeklyTimetable(
        branchId: branchId,
        semester: semester,
        division: division,
        academicYear: academicYear,
      );

      // Cache the result
      await _storageService.saveTimetableCache(
        days.map((e) => e.toJson()).toList(),
      );

      state = state.copyWith(
        status: TimetableStatus.loaded,
        weeklyTimetable: days,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: state.weeklyTimetable.isEmpty
            ? TimetableStatus.error
            : TimetableStatus.loaded,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadTodayTimetable({
    int? branchId,
    int? semester,
    String? division,
  }) async {
    try {
      final today = await _timetableService.fetchTodayTimetable(
        branchId: branchId,
        semester: semester,
        division: division,
      );
      state = state.copyWith(todayTimetable: today);
    } catch (_) {
      // Today screen falls back to weekly data if today endpoint fails
    }
  }

  Future<void> loadFacultyTimetable(int facultyId) async {
    state = state.copyWith(status: TimetableStatus.loading);
    try {
      final days = await _timetableService.fetchFacultyTimetable(facultyId);
      state = state.copyWith(
        status: TimetableStatus.loaded,
        weeklyTimetable: days,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: TimetableStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> generateTimetable({
    required int branchId,
    required int semester,
    required String division,
    required String academicYear,
  }) async {
    state = state.copyWith(isGenerating: true, generateMessage: null);
    try {
      final result = await _timetableService.generateTimetable(
        branchId: branchId,
        semester: semester,
        division: division,
        academicYear: academicYear,
      );
      final message = result['message']?.toString() ?? 'Timetable generated successfully!';
      state = state.copyWith(isGenerating: false, generateMessage: message);

      // Reload timetable after generation
      await loadWeeklyTimetable(
        branchId: branchId,
        semester: semester,
        division: division,
        academicYear: academicYear,
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        isGenerating: false,
        generateMessage: 'Generation failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> updateSlot(int slotId, Map<String, dynamic> updates) async {
    try {
      await _timetableService.updateLectureSlot(
        slotId: slotId,
        updates: updates,
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> moveLecture({
    required int lectureId,
    required int targetSlotId,
    bool swap = true,
  }) async {
    try {
      await _timetableService.moveLectureSlot(
        lectureId: lectureId,
        targetSlotId: targetSlotId,
        swap: swap,
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> generateAllTimetables({
    required String academicYear,
  }) async {
    state = state.copyWith(isGenerating: true, generateMessage: null);
    try {
      final result = await _timetableService.generateAllTimetables(
        academicYear: academicYear,
      );

      final message = result['message']?.toString() ??
          'All classes timetable generated successfully!';

      state = state.copyWith(
        isGenerating: false,
        generateMessage: message,
      );

      // Reload unfiltered weekly data so admin can inspect fresh output.
      await loadWeeklyTimetable();
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        isGenerating: false,
        generateMessage: 'Generation failed: ${e.toString()}',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(status: TimetableStatus.initial, errorMessage: null);
  }
}

final timetableProvider =
    StateNotifierProvider<TimetableNotifier, TimetableState>((ref) {
  final timetableService = ref.watch(timetableServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return TimetableNotifier(timetableService, storageService);
});
