import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/timetable_day_model.dart';
import '../models/time_slot_model.dart';

const _orderedDays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
];

const _timeEndMap = {
  '08:00': '09:00', '09:00': '10:00', '10:00': '11:00', '11:00': '12:00',
  '13:00': '14:00', '14:00': '15:00', '15:00': '16:00', '16:00': '17:00',
};

Future<Uint8List> buildTimetablePdf(
  List<TimetableDay> week, {
  int? branchId,
  int? semester,
  String? division,
}) async {
  final pdf = pw.Document();

  // Build: dayName → timeKey → slot
  final Map<String, Map<String, TimeSlotModel>> daySlotMap = {};
  final Set<String> allTimeKeys = {};

  for (final day in week) {
    final name = day.dayName;
    daySlotMap[name] ??= {};
    for (final slot in day.slots) {
      final key =
          '${slot.startTimeHr.toString().padLeft(2, '0')}:${slot.startTimeMinutes.toString().padLeft(2, '0')}';
      allTimeKeys.add(key);
      daySlotMap[name]![key] = slot;
    }
  }

  final sortedTimes = allTimeKeys.toList()..sort();
  if (sortedTimes.isEmpty) {
    sortedTimes.addAll(
        ['08:00', '09:00', '10:00', '11:00', '13:00', '14:00', '15:00', '16:00']);
  }

  final availableDays =
      _orderedDays.where((d) => daySlotMap.containsKey(d)).toList();

  if (availableDays.isEmpty) {
    pdf.addPage(
      pw.Page(
        build: (ctx) => pw.Center(child: pw.Text('No timetable data available')),
      ),
    );
    return pdf.save();
  }

  final Map<int, pw.TableColumnWidth> colWidths = {
    0: const pw.FixedColumnWidth(58),
  };

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      build: (ctx) {
        final headerRow = [
          'Time',
          ...availableDays.map((d) => d.substring(0, 3)),
        ];

        final dataRows = sortedTimes.map((startKey) {
          final endKey = _timeEndMap[startKey] ?? '';
          final timeLabel = endKey.isNotEmpty ? '$startKey\n─\n$endKey' : startKey;

          return [
            timeLabel,
            ...availableDays.map((day) {
              final slot = daySlotMap[day]?[startKey];
              if (slot == null || slot.lectures.isEmpty) return '─';
              final lec = slot.lectures.first;
              final subject = lec.subjectName ?? lec.subjectCode ?? '';
              final faculty = lec.facultyName ?? '';
              final labTag = lec.isLabLecture ? ' [Lab]' : '';
              final room = lec.roomNumber != null ? '\n🚪 ${lec.roomNumber}' : '';
              return '$subject$labTag\n$faculty$room'.trim();
            }),
          ];
        }).toList();

        final titleParts = [
          'Weekly Timetable',
          if (branchId != null) 'Branch $branchId',
          if (semester != null) 'Semester $semester',
          if (division != null) 'Division $division',
        ];

        return [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(titleParts.join('  |  '),
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                'Generated ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: headerRow,
            data: dataRows,
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle:
                pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1A73E8)),
            oddRowDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F9FF)),
            cellHeight: 50,
            columnWidths: colWidths,
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellAlignments: {
              0: pw.Alignment.center,
              for (int i = 1; i <= availableDays.length; i++)
                i: pw.Alignment.center,
            },
          ),
        ];
      },
    ),
  );

  return pdf.save();
}
