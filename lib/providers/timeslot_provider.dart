import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timeslot_template_model.dart';
import '../services/timeslot_service.dart';

enum TimeslotStatus { initial, loading, loaded, error }

class TimeslotState {
  final TimeslotStatus status;
  final List<TimeSlotTemplateModel> timeslots;
  final String? errorMessage;

  const TimeslotState({
    this.status = TimeslotStatus.initial,
    this.timeslots = const [],
    this.errorMessage,
  });

  TimeslotState copyWith({
    TimeslotStatus? status,
    List<TimeSlotTemplateModel>? timeslots,
    String? errorMessage,
  }) {
    return TimeslotState(
      status: status ?? this.status,
      timeslots: timeslots ?? this.timeslots,
      errorMessage: errorMessage,
    );
  }
}

class TimeslotNotifier extends StateNotifier<TimeslotState> {
  final TimeslotService _timeslotService;

  TimeslotNotifier(this._timeslotService) : super(const TimeslotState());

  Future<void> loadTimeslots() async {
    state = state.copyWith(status: TimeslotStatus.loading);
    try {
      final list = await _timeslotService.fetchAllTimeslots();
      state = state.copyWith(status: TimeslotStatus.loaded, timeslots: list);
    } on Exception catch (e) {
      state = state.copyWith(
        status: TimeslotStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> createTimeslot(Map<String, dynamic> data) async {
    try {
      final created = await _timeslotService.createTimeslot(data);
      state = state.copyWith(timeslots: [...state.timeslots, created]);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateTimeslot(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _timeslotService.updateTimeslot(id, data);
      final newList =
          state.timeslots.map((t) => t.id == id ? updated : t).toList();
      state = state.copyWith(timeslots: newList);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteTimeslot(int id) async {
    try {
      await _timeslotService.deleteTimeslot(id);
      state = state.copyWith(
        timeslots: state.timeslots.where((t) => t.id != id).toList(),
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Seed the 8 default 1-hour slots (8 AM – 5 PM) into the DB.
  Future<void> seedDefaults() async {
    final defaults = [
      {'label': 'Period 1', 'startTimeHr': 8,  'startTimeMinutes': 0, 'endTimeHr': 9,  'endTimeMinutes': 0, 'is_break': 0, 'sort_order': 1,  'is_active': 1},
      {'label': 'Period 2', 'startTimeHr': 9,  'startTimeMinutes': 0, 'endTimeHr': 10, 'endTimeMinutes': 0, 'is_break': 0, 'sort_order': 2,  'is_active': 1},
      {'label': 'Period 3', 'startTimeHr': 10, 'startTimeMinutes': 0, 'endTimeHr': 11, 'endTimeMinutes': 0, 'is_break': 0, 'sort_order': 3,  'is_active': 1},
      {'label': 'Period 4', 'startTimeHr': 11, 'startTimeMinutes': 0, 'endTimeHr': 12, 'endTimeMinutes': 0, 'is_break': 0, 'sort_order': 4,  'is_active': 1},
      {'label': 'Lunch Break','startTimeHr': 12,'startTimeMinutes': 0,'endTimeHr': 13,'endTimeMinutes': 0, 'is_break': 1, 'sort_order': 5, 'is_active': 1},
      {'label': 'Period 5', 'startTimeHr': 13, 'startTimeMinutes': 0, 'endTimeHr': 14, 'endTimeMinutes': 0, 'is_break': 0, 'sort_order': 6,  'is_active': 1},
      {'label': 'Period 6', 'startTimeHr': 14, 'startTimeMinutes': 0, 'endTimeHr': 15, 'endTimeMinutes': 0, 'is_break': 0, 'sort_order': 7,  'is_active': 1},
      {'label': 'Period 7', 'startTimeHr': 15, 'startTimeMinutes': 0, 'endTimeHr': 16, 'endTimeMinutes': 0, 'is_break': 0, 'sort_order': 8,  'is_active': 1},
      {'label': 'Period 8', 'startTimeHr': 16, 'startTimeMinutes': 0, 'endTimeHr': 17, 'endTimeMinutes': 0, 'is_break': 0, 'sort_order': 9,  'is_active': 1},
    ];
    for (final d in defaults) {
      await createTimeslot(d);
    }
  }
}

final timeslotProvider =
    StateNotifierProvider<TimeslotNotifier, TimeslotState>((ref) {
  final timeslotService = ref.watch(timeslotServiceProvider);
  return TimeslotNotifier(timeslotService);
});
