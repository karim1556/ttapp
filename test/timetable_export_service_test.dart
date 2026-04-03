import 'package:flutter_test/flutter_test.dart';

import 'package:ttapp/models/lecture_assignment_model.dart';
import 'package:ttapp/models/time_slot_model.dart';
import 'package:ttapp/models/timetable_day_model.dart';
import 'package:ttapp/models/timetable_model.dart';
import 'package:ttapp/services/timetable_export_service.dart';

void main() {
  TimetableDay sampleDay() {
    final lecture = LectureAssignmentModel(
      id: 1,
      timeTableDetailedId: 101,
      typeOfLecture: 'Lecture',
      subjectCode: 'CS501',
      subjectName: 'Distributed Systems',
      facultyName: 'Dr. Patel',
      roomNumber: 'R-204',
      facultyId: 12,
    );

    final slot = TimeSlotModel(
      id: 101,
      timetableId: 11,
      startTimeHr: 9,
      startTimeMinutes: 0,
      endTimeHr: 10,
      endTimeMinutes: 0,
      lectures: [lecture],
    );

    return TimetableDay(
      timetable: TimetableModel(
        id: 11,
        dateOfWeek: 'Monday',
        branchId: 1,
        sem: 5,
        division: 'A',
      ),
      slots: [slot],
    );
  }

  test('CSV export contains room and lecture data', () {
    final csv = buildTimetableCsv(
      [sampleDay()],
      branchId: 1,
      semester: 5,
      division: 'A',
    );

    expect(csv, contains('Weekly Timetable'));
    expect(csv, contains('Distributed Systems'));
    expect(csv, contains('Dr. Patel'));
    expect(csv, contains('R-204'));
  });

  test('PDF export generates non-empty bytes', () async {
    final bytes = await buildTimetablePdf(
      [sampleDay()],
      branchId: 1,
      semester: 5,
      division: 'A',
    );

    expect(bytes, isNotEmpty);
  });
}
