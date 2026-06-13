import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/room_model.dart';
import '../../../models/timetable_day_model.dart';
import '../../../providers/room_provider.dart';
import '../../../services/timetable_service.dart';
import '../../../services/timetable_export_service.dart';
import '../../../widgets/loading_overlay_widget.dart';

const _labOrderedDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

class LabTimetableScreen extends ConsumerStatefulWidget {
  const LabTimetableScreen({super.key});

  @override
  ConsumerState<LabTimetableScreen> createState() => _LabTimetableScreenState();
}

class _LabTimetableScreenState extends ConsumerState<LabTimetableScreen> {
  RoomModel? _selectedLab;
  List<TimetableDay> _weeklyData = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(roomProvider.notifier).loadRooms();
    });
  }

  Future<void> _loadLabTimetable(RoomModel lab) async {
    setState(() {
      _loading = true;
      _error = null;
      _weeklyData = [];
    });
    try {
      final service = ref.read(timetableServiceProvider);
      final days = await service.fetchRoomWeeklyTimetable(lab.roomNumber);
      setState(() {
        _weeklyData = days;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    if (_selectedLab == null || _weeklyData.isEmpty) return;
    try {
      final bytes = await buildTimetablePdf(_weeklyData);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'lab_${_selectedLab!.roomNumber}_timetable.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('PDF Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    // Only show Lab-type rooms
    final labs = roomState.rooms
        .where((r) => r.active && r.roomType == 'Lab')
        .toList()
      ..sort((a, b) => a.roomNumber.compareTo(b.roomNumber));

    return LoadingOverlayWidget(
      isLoading: _loading,
      message: 'Loading lab timetable...',
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(_selectedLab != null
              ? 'Lab ${_selectedLab!.roomNumber} — Timetable'
              : 'Lab Timetable'),
          actions: [
            if (_weeklyData.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Export PDF',
                onPressed: _exportPdf,
              ),
          ],
        ),
        body: Column(
          children: [
            // Lab selector card
            Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.computer_outlined,
                        color: Colors.indigo, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: labs.isEmpty
                        ? Text(
                            'No labs configured. Add rooms with type "Lab".',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13),
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<RoomModel>(
                              isExpanded: true,
                              hint: const Text(
                                'Select a Lab',
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xFF8590A5)),
                              ),
                              value: _selectedLab,
                              items: labs.map((r) {
                                return DropdownMenuItem<RoomModel>(
                                  value: r,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.science_outlined,
                                          size: 16, color: Colors.indigo),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${r.roomNumber}${r.name != null && r.name!.isNotEmpty ? ' — ${r.name}' : ''}',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (r.capacity != null)
                                        Text(
                                          'Cap: ${r.capacity}',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF8590A5)),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (lab) {
                                if (lab == null) return;
                                setState(() => _selectedLab = lab);
                                _loadLabTimetable(lab);
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Error
            if (_error != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Timetable or placeholder
            Expanded(
              child: _selectedLab == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.science_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Select a lab to view its timetable',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 14)),
                        ],
                      ),
                    )
                  : _weeklyData.isEmpty && !_loading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_busy_outlined,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('No timetable data for this lab',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14)),
                            ],
                          ),
                        )
                      : _LabWeekGrid(
                          weeklyData: _weeklyData,
                          labLabel: _selectedLab!.roomNumber,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Lab weekly grid
// ─────────────────────────────────────────────────────────

class _LabWeekGrid extends StatelessWidget {
  final List<TimetableDay> weeklyData;
  final String labLabel;

  const _LabWeekGrid({
    required this.weeklyData,
    required this.labLabel,
  });

  @override
  Widget build(BuildContext context) {
    final allStartKeys = <String>{};
    final daySlotMap = <String, Map<String, dynamic>>{};

    for (final day in weeklyData) {
      final name = day.dayName;
      daySlotMap[name] ??= {};
      for (final slot in day.slots) {
        final key =
            '${slot.startTimeHr.toString().padLeft(2, '0')}:${slot.startTimeMinutes.toString().padLeft(2, '0')}';
        final endKey =
            '${slot.endTimeHr.toString().padLeft(2, '0')}:${slot.endTimeMinutes.toString().padLeft(2, '0')}';
        allStartKeys.add(key);
        daySlotMap[name]![key] = {'slot': slot, 'endKey': endKey};
      }
    }

    final sortedTimes = allStartKeys.toList()..sort();
    final availableDays = _labOrderedDays
        .where((d) => weeklyData.any((w) => w.dayName == d))
        .toList();

    if (sortedTimes.isEmpty || availableDays.isEmpty) {
      return Center(
        child: Text('No lab sessions found for $labLabel',
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: availableDays.map((d) {
              final count = daySlotMap[d]
                      ?.values
                      .where((v) =>
                          ((v['slot'] as dynamic).lectures as List).isNotEmpty)
                      .length ??
                  0;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: count > 0
                      ? Colors.indigo.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: count > 0
                        ? Colors.indigo.withValues(alpha: 0.3)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  '${d.substring(0, 3)} · $count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: count > 0 ? Colors.indigo : Colors.grey.shade500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        ...availableDays.map((dayName) {
          final daySlots = daySlotMap[dayName] ?? {};
          final hasLectures = daySlots.values.any(
              (v) => ((v['slot'] as dynamic).lectures as List).isNotEmpty);
          if (!hasLectures) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.indigo,
                        Colors.indigo.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.science_outlined,
                          color: Colors.white70, size: 15),
                      const SizedBox(width: 8),
                      Text(dayName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: sortedTimes.where((timeKey) {
                      final entry = daySlots[timeKey];
                      if (entry == null) return false;
                      return ((entry['slot'] as dynamic).lectures as List)
                          .isNotEmpty;
                    }).map((timeKey) {
                      final entry = daySlots[timeKey]!;
                      final slot = entry['slot'] as dynamic;
                      final endKey = entry['endKey'] as String;
                      final lectures = slot.lectures as List;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.indigo.withValues(alpha: 0.18)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 72,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(timeKey,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo)),
                                  Text('to $endKey',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF8590A5))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: lectures.map<Widget>((lec) {
                                  final subject =
                                      (lec.subjectName ?? lec.subjectCode ?? '')
                                          .toString();
                                  final teacher =
                                      (lec.facultyName ?? '').toString();
                                  final batch = (lec.batch ?? '').toString();
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subject.isNotEmpty ? subject : 'Lab',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: Color(0xFF1A237E)),
                                      ),
                                      if (teacher.isNotEmpty ||
                                          batch.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            if (teacher.isNotEmpty) ...[
                                              const Icon(
                                                  Icons.person_outline_rounded,
                                                  size: 11,
                                                  color: Color(0xFF8590A5)),
                                              const SizedBox(width: 3),
                                              Text(teacher,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Color(0xFF5A657A))),
                                            ],
                                            if (teacher.isNotEmpty &&
                                                batch.isNotEmpty)
                                              const Text(' · ',
                                                  style: TextStyle(
                                                      color:
                                                          Color(0xFF8590A5))),
                                            if (batch.isNotEmpty)
                                              Text('Batch $batch',
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.indigo,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                          ],
                                        ),
                                      ],
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
