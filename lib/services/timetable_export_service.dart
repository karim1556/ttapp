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
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      build: (ctx) {
        final headerRow = ['Time', ...availableDays.map(_dayLabel)];

        final dataRows = sortedTimes.map((startKey) {
          final endKey = endByStart[startKey] ?? _timeEndMap[startKey] ?? '';
          final timeLabel = endKey.isNotEmpty ? '$startKey\n-\n$endKey' : startKey;

          final row = <String>[timeLabel];
          for (final dayName in availableDays) {
            final slot = daySlotMap[dayName]?[startKey];
            if (slot == null || slot.lectures.isEmpty) {
              row.add(startKey == '12:00' ? 'Lunch Break' : 'Free');
            } else {
              row.add(_pdfCellContent(slot));
            }
          }
          return row;
        }).toList();

        final colWidths = <int, pw.TableColumnWidth>{
          0: const pw.FixedColumnWidth(70),
        };

        return [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: brandColor,
              borderRadius: pw.BorderRadius.circular(14),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Weekly Timetable',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Academic schedule overview with room and faculty allocation',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColor.fromInt(0xFFE7EEFA),
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFF0A2449),
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Text(
                        'Generated $generatedStamp',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColor.fromInt(0xFFF2F6FF),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _metricCard(
                        label: 'Branch',
                        value: branchId?.toString() ?? 'All',
                        background: accentColor,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: _metricCard(
                        label: 'Semester / Division',
                        value: '${semester?.toString() ?? '-'} / ${division ?? '-'}',
                        background: accentColor,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: _metricCard(
                        label: 'Lecture Slots',
                        value: '$totalLectureItems total | $totalLabItems lab',
                        background: accentColor,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: _metricCard(
                        label: 'Grid Occupancy',
                        value: '$occupancyPercent%',
                        background: accentColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: panelBg,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: borderColor, width: 1),
            ),
            child: pw.TableHelper.fromTextArray(
              headers: headerRow,
              data: dataRows,
              cellStyle: const pw.TextStyle(fontSize: 8.5, color: PdfColor.fromInt(0xFF1B2C48)),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: accentColor),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF2F7FF)),
              cellHeight: 62,
              columnWidths: colWidths,
              border: pw.TableBorder.all(color: borderColor, width: 0.7),
              cellAlignments: {
                0: pw.Alignment.center,
                for (int i = 1; i <= availableDays.length; i++) i: pw.Alignment.topLeft,
              },
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: borderColor, width: 0.8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _legendItem(
                  color: const PdfColor.fromInt(0xFF1F5FB6),
                  label: 'Lecture / Theory',
                ),
                _legendItem(
                  color: const PdfColor.fromInt(0xFF13795B),
                  label: 'Lab Session (2 slots)',
                ),
                _legendItem(
                  color: const PdfColor.fromInt(0xFF8A99B3),
                  label: 'Free / Break',
                ),
                pw.Text(
                  'Generated by TTAPP',
                  style: const pw.TextStyle(fontSize: 8, color: mutedText),
                ),
              ],
            ),
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
