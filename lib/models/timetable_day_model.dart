/// Aggregated view model combining timetable day + time slots + lectures
/// Used for display in the weekly grid and today's view.

import 'timetable_model.dart';
import 'time_slot_model.dart';

class TimetableDay {
  final TimetableModel timetable;
  final List<TimeSlotModel> slots;

  TimetableDay({required this.timetable, required this.slots});

  String get dayName => timetable.dateOfWeek;

  /// Parse from the nested format: { timetable: {...}, slots: [...] }
  factory TimetableDay.fromJson(Map<String, dynamic> json) {
    return TimetableDay(
      timetable: TimetableModel.fromJson(json['timetable'] as Map<String, dynamic>),
      slots: (json['slots'] as List<dynamic>?)
              ?.map((e) => TimeSlotModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Parse from the flat API format returned by the backend:
  /// { id, dateOfWeek, branch_id, sem, division, ..., slots: [ {id, startTimeHr, ..., lectures: [...]} ] }
  factory TimetableDay.fromApiEntry(Map<String, dynamic> entry) {
    final timetable = TimetableModel.fromJson(entry);
    final rawSlots = entry['slots'] as List<dynamic>? ?? [];
    final slots = rawSlots.map((s) {
      final slotMap = s as Map<String, dynamic>;
      return TimeSlotModel.fromJson(slotMap);
    }).toList();
    return TimetableDay(timetable: timetable, slots: slots);
  }

  Map<String, dynamic> toJson() => {
        'timetable': timetable.toJson(),
        'slots': slots.map((e) => e.toJson()).toList(),
      };
}
