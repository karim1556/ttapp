import '../../../models/lecture_assignment_model.dart';
import '../../../models/substitution_model.dart';
import '../../../models/time_slot_model.dart';

List<TimeSlotModel> applyApprovedSubstitutionsToSlots({
  required List<TimeSlotModel> slots,
  required List<SubstitutionRecordModel> substitutions,
  required DateTime date,
}) {
  if (slots.isEmpty || substitutions.isEmpty) {
    return List<TimeSlotModel>.from(slots);
  }

  final approvedByLectureId = <int, SubstitutionRecordModel>{};
  for (final record in substitutions) {
    if (!record.isApproved || !record.matchesDate(date)) continue;
    approvedByLectureId[record.lectureId] = record;
  }

  if (approvedByLectureId.isEmpty) {
    return List<TimeSlotModel>.from(slots);
  }

  return slots.map((slot) {
    if (slot.lectures.isEmpty) return slot;

    final replacedLectures = slot.lectures.map((lecture) {
      final record = approvedByLectureId[lecture.id];
      if (record == null) return lecture;

      return lecture.copyWith(
        facultyId: record.substituteFacultyId,
        facultyName: record.substituteFacultyName ?? lecture.facultyName,
        lectOnBehalf: 1,
        reason: record.reason ?? lecture.reason,
      );
    }).toList(growable: false);

    return TimeSlotModel(
      id: slot.id,
      timetableId: slot.timetableId,
      startTimeHr: slot.startTimeHr,
      startTimeMinutes: slot.startTimeMinutes,
      endTimeHr: slot.endTimeHr,
      endTimeMinutes: slot.endTimeMinutes,
      createdBy: slot.createdBy,
      createdAt: slot.createdAt,
      updatedAt: slot.updatedAt,
      lectures: replacedLectures,
    );
  }).toList(growable: false);
}
