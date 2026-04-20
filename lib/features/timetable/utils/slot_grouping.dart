import '../../../models/lecture_assignment_model.dart';
import '../../../models/time_slot_model.dart';

/// Collapses back-to-back lab slots that represent the same lab block.
///
/// Example: 09:00-10:00 + 10:00-11:00 (same lab lectures) becomes
/// a single 09:00-11:00 visual slot.
List<TimeSlotModel> collapseConsecutiveLabSlots(List<TimeSlotModel> slots) {
  if (slots.length < 2) return List<TimeSlotModel>.from(slots);

  final ordered = List<TimeSlotModel>.from(slots)
    ..sort((a, b) => _slotStartMinutes(a).compareTo(_slotStartMinutes(b)));

  final collapsed = <TimeSlotModel>[];
  var i = 0;

  while (i < ordered.length) {
    final current = ordered[i];

    if (i + 1 < ordered.length) {
      final next = ordered[i + 1];
      if (_canMergeLabSlots(current, next)) {
        collapsed.add(
          TimeSlotModel(
            id: current.id,
            timetableId: current.timetableId,
            startTimeHr: current.startTimeHr,
            startTimeMinutes: current.startTimeMinutes,
            endTimeHr: next.endTimeHr,
            endTimeMinutes: next.endTimeMinutes,
            createdBy: current.createdBy,
            createdAt: current.createdAt,
            updatedAt: next.updatedAt ?? current.updatedAt,
            lectures: _mergeLectures(current.lectures, next.lectures),
          ),
        );
        i += 2;
        continue;
      }
    }

    collapsed.add(current);
    i += 1;
  }

  return collapsed;
}

bool _canMergeLabSlots(TimeSlotModel first, TimeSlotModel second) {
  if (!_isPureLabSlot(first) || !_isPureLabSlot(second)) return false;
  if (!_isConsecutive(first, second)) return false;

  final firstSet = _slotLectureSignatureSet(first);
  final secondSet = _slotLectureSignatureSet(second);

  if (firstSet.isEmpty || secondSet.isEmpty) return false;
  return firstSet.length == secondSet.length && firstSet.containsAll(secondSet);
}

bool _isPureLabSlot(TimeSlotModel slot) {
  return slot.lectures.isNotEmpty &&
      slot.lectures.every((lec) => lec.isLabLecture);
}

bool _isConsecutive(TimeSlotModel first, TimeSlotModel second) {
  return first.endTimeHr == second.startTimeHr &&
      first.endTimeMinutes == second.startTimeMinutes;
}

int _slotStartMinutes(TimeSlotModel slot) {
  return (slot.startTimeHr * 60) + slot.startTimeMinutes;
}

Set<String> _slotLectureSignatureSet(TimeSlotModel slot) {
  return slot.lectures.map(_lectureSignature).toSet();
}

List<LectureAssignmentModel> _mergeLectures(
  List<LectureAssignmentModel> first,
  List<LectureAssignmentModel> second,
) {
  final merged = <String, LectureAssignmentModel>{};
  for (final lecture in [...first, ...second]) {
    merged.putIfAbsent(_lectureSignature(lecture), () => lecture);
  }
  return merged.values.toList();
}

String _lectureSignature(LectureAssignmentModel lecture) {
  return [
    lecture.subjectCode ?? '',
    lecture.facultyId?.toString() ?? lecture.facultyName ?? '',
    lecture.batch ?? '',
    lecture.roomNumber ?? '',
    (lecture.typeOfLecture ?? '').toLowerCase(),
  ].join('|');
}
