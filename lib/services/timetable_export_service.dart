import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/time_slot_model.dart';
import '../models/timetable_day_model.dart';

const _orderedDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

const _defaultTimeKeys = [
  '08:00',
  '09:00',
  '10:00',
  '11:00',
  '12:00',
  '13:00',
  '14:00',
  '15:00',
  '16:00',
];

const _timeEndMap = {
  '08:00': '09:00',
  '09:00': '10:00',
  '10:00': '11:00',
  '11:00': '12:00',
  '12:00': '13:00',
  '13:00': '14:00',
  '14:00': '15:00',
  '15:00': '16:00',
  '16:00': '17:00',
};

Future<Uint8List> buildTimetablePdf(
  List<TimetableDay> week, {
  int? branchId,
  int? semester,
  String? division,
}) async {
  final pdf = pw.Document();
  final generatedAt = DateTime.now();
  final generatedStamp =
      '${generatedAt.day.toString().padLeft(2, '0')}/${generatedAt.month.toString().padLeft(2, '0')}/${generatedAt.year} '
      '${generatedAt.hour.toString().padLeft(2, '0')}:${generatedAt.minute.toString().padLeft(2, '0')}';

  final daySlotMap = <String, Map<String, TimeSlotModel>>{};
  final endByStart = <String, String>{};
  final allTimeKeys = <String>{};

  var totalLectureItems = 0;
  var totalLabItems = 0;

  for (final day in week) {
    final dayName = day.dayName;
    daySlotMap[dayName] ??= {};

    for (final slot in day.slots) {
      final key =
          '${slot.startTimeHr.toString().padLeft(2, '0')}:${slot.startTimeMinutes.toString().padLeft(2, '0')}';
      final endKey =
          '${slot.endTimeHr.toString().padLeft(2, '0')}:${slot.endTimeMinutes.toString().padLeft(2, '0')}';

      daySlotMap[dayName]![key] = slot;
      endByStart[key] = endKey;
      allTimeKeys.add(key);

      for (final lecture in slot.lectures) {
        totalLectureItems += 1;
        final isLab =
            lecture.isLabLecture || (lecture.typeOfLecture ?? '').toLowerCase() == 'lab';
        if (isLab) totalLabItems += 1;
      }
    }
  }

  final sortedTimes = allTimeKeys.toList()..sort();
  if (sortedTimes.isEmpty) {
    sortedTimes.addAll(_defaultTimeKeys);
  }

  final availableDays = [
    ..._orderedDays.where((d) => daySlotMap.containsKey(d)),
    ...daySlotMap.keys.where((d) => !_orderedDays.contains(d)),
  ];

  if (availableDays.isEmpty) {
    pdf.addPage(
      pw.Page(
        build: (ctx) => pw.Center(child: pw.Text('No timetable data available')),
      ),
    );
    return pdf.save();
  }

  var occupiedCells = 0;
  for (final dayName in availableDays) {
    for (final startKey in sortedTimes) {
      final slot = daySlotMap[dayName]?[startKey];
      if (slot != null && slot.lectures.isNotEmpty) occupiedCells += 1;
    }
  }

  final totalGridCells = availableDays.length * sortedTimes.length;
  final occupancyPercent =
      totalGridCells == 0 ? 0 : ((occupiedCells * 100) / totalGridCells).round();

  const brandColor = PdfColor.fromInt(0xFF123261);
  const accentColor = PdfColor.fromInt(0xFF1E67C5);
  const panelBg = PdfColor.fromInt(0xFFF7FAFF);
  const borderColor = PdfColor.fromInt(0xFFD2DFF2);
  const mutedText = PdfColor.fromInt(0xFF4E5E7B);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      build: (ctx) {
        // Build a classic portrait timetable layout similar to the provided image.
        final timeHeaders = sortedTimes.map((t) {
          final endKey = endByStart[t] ?? _timeEndMap[t] ?? '';
          return endKey.isNotEmpty ? '$t - ${endKey}' : t;
        }).toList();

        // Header block matching college timetable style
        final header = pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1.2)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                "VASANTDADA PATIL PRATISHTHAN'S COLLEGE OF ENGINEERING & VISUAL ARTS, MUMBAI - 22",
                style: pw.TextStyle(fontSize: 12.5, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'TITLE : TIMETABLE (FH-2026)',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('DEPT: Computer Engineering', style: pw.TextStyle(fontSize: 9)),
                  pw.Text('Class Advisor: Prof. -', style: pw.TextStyle(fontSize: 9)),
                  pw.Text('Rooms: -', style: pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),
        );

        // Timetable grid: days as rows, time slots as columns
        final tableHeader = [ 'DAYS/TIME', ...timeHeaders ];

        final tableData = <List<String>>[];
        for (final dayName in availableDays) {
          final row = <String>[];
          row.add(dayName.toUpperCase());
          for (final startKey in sortedTimes) {
            final slot = daySlotMap[dayName]?[startKey];
            if (slot == null || slot.lectures.isEmpty) {
              row.add(startKey == '12:00' ? 'Lunch' : '');
            } else {
              // Shorten content to subject initials + room
              final cell = slot.lectures.map((lec) {
                final subj = (lec.subjectCode ?? lec.subjectName ?? '').toString();
                final room = (lec.roomNumber ?? '').toString();
                final short = subj.length > 12 ? '${subj.substring(0, 12)}' : subj;
                return room.isNotEmpty ? '$short\nR:$room' : short;
              }).join('\n');
              row.add(cell);
            }
          }
          tableData.add(row);
        }

        // Subject - Teacher summary
        final subjectMap = <String, Map<String, dynamic>>{};
        for (final day in week) {
          for (final slot in day.slots) {
            for (final lec in slot.lectures) {
              final subj = (lec.subjectName ?? lec.subjectCode ?? 'Untitled').trim();
              final teacher = (lec.facultyName ?? '').trim();
              final isLab = lec.isLabLecture || (lec.typeOfLecture ?? '').toLowerCase() == 'lab';
              final entry = subjectMap.putIfAbsent(subj, () => {'teachers': <String>{}, 'theory': 0, 'lab': 0});
              if (teacher.isNotEmpty) entry['teachers'].add(teacher);
              if (isLab) {
                entry['lab'] = (entry['lab'] as int) + 1;
              } else {
                entry['theory'] = (entry['theory'] as int) + 1;
              }
            }
          }
        }

        final summaryRows = subjectMap.entries.map((e) {
          final teachers = (e.value['teachers'] as Set<String>).join(', ');
          final theory = e.value['theory'] as int;
          final lab = e.value['lab'] as int;
          return [e.key, teachers, theory.toString(), lab.toString()];
        }).toList();

        return [
          header,
          pw.SizedBox(height: 8),
          // Timetable grid box
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.8)),
            child: pw.Table.fromTextArray(
              headers: tableHeader,
              data: tableData,
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              cellStyle: pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.center,
              columnWidths: {
                0: const pw.FixedColumnWidth(70),
                for (var i = 1; i <= timeHeaders.length; i++) i: const pw.FlexColumnWidth(1),
              },
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            ),
          ),
          pw.SizedBox(height: 10),
          // Summary table
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.6)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('SUBJECT - TEACHER', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Table.fromTextArray(
                  headers: ['Subject', 'Teacher(s)', 'Theory', 'Lab'],
                  data: summaryRows,
                  headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                  cellStyle: pw.TextStyle(fontSize: 8),
                  columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(3), 2: const pw.FlexColumnWidth(1), 3: const pw.FlexColumnWidth(1)},
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.4),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Generated: $generatedStamp', style: pw.TextStyle(fontSize: 8)),
              pw.Text('Generated by TTAPP', style: pw.TextStyle(fontSize: 8)),
            ],
          ),
        ];
      },
    ),
  );

  return pdf.save();
}

String _dayLabel(String day) => day.length > 3 ? day.substring(0, 3) : day;

pw.Widget _metricCard({
  required String label,
  required String value,
  required PdfColor background,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: pw.BoxDecoration(
      color: background,
      borderRadius: pw.BorderRadius.circular(9),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFFDCE9FF)),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _legendItem({required PdfColor color, required String label}) {
  return pw.Row(
    children: [
      pw.Container(
        width: 10,
        height: 10,
        decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
      ),
      pw.SizedBox(width: 6),
      pw.Text(
        label,
        style: const pw.TextStyle(fontSize: 8.5, color: PdfColor.fromInt(0xFF2F3C56)),
      ),
    ],
  );
}

String _pdfCellContent(TimeSlotModel slot) {
  final lines = slot.lectures.map((lec) {
    final subject = (lec.subjectName ?? lec.subjectCode ?? 'Untitled').trim();
    final faculty = (lec.facultyName ?? '').trim();
    final room = (lec.roomNumber ?? '').trim();
    final batch = (lec.batch ?? '').trim();
    final isLab = lec.isLabLecture || (lec.typeOfLecture ?? '').toLowerCase() == 'lab';
    final type = isLab ? 'Lab Session' : 'Lecture';

    final details = <String>[
      if (faculty.isNotEmpty) faculty,
      if (room.isNotEmpty) 'Room $room',
      if (batch.isNotEmpty) 'Batch $batch',
      type,
    ];

    return details.isEmpty ? subject : '$subject (${details.join(' | ')})';
  }).toList();

  return lines.join('\n');
}

String _csvEscape(String value) {
  final needsQuotes = value.contains(',') || value.contains('"') || value.contains('\n');
  final escaped = value.replaceAll('"', '""');
  return needsQuotes ? '"$escaped"' : escaped;
}

/// Build CSV text that can be opened directly in Excel.
String buildTimetableCsv(
  List<TimetableDay> week, {
  int? branchId,
  int? semester,
  String? division,
}) {
  final daySlotMap = <String, Map<String, TimeSlotModel>>{};
  final endByStart = <String, String>{};
  final allTimeKeys = <String>{};

  for (final day in week) {
    final dayName = day.dayName;
    daySlotMap[dayName] ??= {};

    for (final slot in day.slots) {
      final key =
          '${slot.startTimeHr.toString().padLeft(2, '0')}:${slot.startTimeMinutes.toString().padLeft(2, '0')}';
      final endKey =
          '${slot.endTimeHr.toString().padLeft(2, '0')}:${slot.endTimeMinutes.toString().padLeft(2, '0')}';

      daySlotMap[dayName]![key] = slot;
      endByStart[key] = endKey;
      allTimeKeys.add(key);
    }
  }

  final sortedTimes = allTimeKeys.toList()..sort();
  if (sortedTimes.isEmpty) {
    sortedTimes.addAll(_defaultTimeKeys);
  }

  final availableDays = [
    ..._orderedDays.where((d) => daySlotMap.containsKey(d)),
    ...daySlotMap.keys.where((d) => !_orderedDays.contains(d)),
  ];

  final header = ['Time', ...availableDays];
  final rows = <List<String>>[];

  final titleParts = [
    'Weekly Timetable',
    if (branchId != null) 'Branch $branchId',
    if (semester != null) 'Semester $semester',
    if (division != null) 'Division $division',
  ];

  rows.add([titleParts.join(' | ')]);
  rows.add(['Generated: ${DateTime.now().toIso8601String()}']);
  rows.add(const ['']);
  rows.add(header);

  for (final startKey in sortedTimes) {
    final endKey = endByStart[startKey] ?? _timeEndMap[startKey] ?? '';
    final timeLabel = endKey.isNotEmpty ? '$startKey-$endKey' : startKey;

    final row = <String>[timeLabel];
    for (final dayName in availableDays) {
      final slot = daySlotMap[dayName]?[startKey];
      if (slot == null || slot.lectures.isEmpty) {
        row.add('');
        continue;
      }

      final lectureSegments = slot.lectures.map((lec) {
        final subject = lec.subjectName ?? lec.subjectCode ?? '';
        final faculty = lec.facultyName ?? '';
        final room = lec.roomNumber ?? '';
        final batch = lec.batch ?? '';
        final type = lec.isLabLecture ? 'Lab' : (lec.typeOfLecture ?? 'Lecture');
        return [subject, faculty, room, batch, type]
            .where((e) => e.isNotEmpty)
            .join(' | ');
      }).toList();

      row.add(lectureSegments.join(' || '));
    }
    rows.add(row);
  }

  return rows.map((row) => row.map(_csvEscape).join(',')).join('\n');
}
