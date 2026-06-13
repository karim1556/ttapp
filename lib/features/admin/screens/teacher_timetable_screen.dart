import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/faculty_model.dart';
import '../../../models/timetable_day_model.dart';
import '../../../providers/faculty_provider.dart';
import '../../../services/timetable_service.dart';
import '../../../services/timetable_export_service.dart';
import '../../../widgets/loading_overlay_widget.dart';

const _teacherOrderedDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday'
];

class TeacherTimetableScreen extends ConsumerStatefulWidget {
  const TeacherTimetableScreen({super.key});

  @override
  ConsumerState<TeacherTimetableScreen> createState() =>
      _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState
    extends ConsumerState<TeacherTimetableScreen> {
  FacultyModel? _selectedTeacher;
  List<TimetableDay> _weeklyData = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(facultyProvider.notifier).loadFaculty();
    });
  }

  Future<void> _loadTeacherTimetable(FacultyModel teacher) async {
    setState(() {
      _loading = true;
      _error = null;
      _weeklyData = [];
    });
    try {
      final service = ref.read(timetableServiceProvider);
      final days = await service.fetchFacultyTimetable(teacher.facultyId);
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
    if (_selectedTeacher == null || _weeklyData.isEmpty) return;
    try {
      final bytes = await buildTimetablePdf(_weeklyData);
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'teacher_${_selectedTeacher!.name.replaceAll(' ', '_')}_timetable.pdf',
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
    final facultyState = ref.watch(facultyProvider);
    final teachers = facultyState.faculty.where((f) => f.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return LoadingOverlayWidget(
      isLoading: _loading,
      message: 'Loading teacher timetable...',
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(_selectedTeacher != null
              ? '${_selectedTeacher!.name} — Timetable'
              : 'Teacher Timetable'),
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
            // Teacher selector card
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
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_outlined,
                        color: AppColors.secondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: teachers.isEmpty
                        ? Text(
                            'No active teachers found.',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13),
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<FacultyModel>(
                              isExpanded: true,
                              hint: const Text(
                                'Select a Teacher',
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xFF8590A5)),
                              ),
                              value: _selectedTeacher,
                              items: teachers.map((t) {
                                return DropdownMenuItem<FacultyModel>(
                                  value: t,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppColors.secondary
                                            .withValues(alpha: 0.15),
                                        child: Text(
                                          t.name.isNotEmpty
                                              ? t.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              t.name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (t.email.isNotEmpty)
                                              Text(
                                                t.email,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF8590A5),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (teacher) {
                                if (teacher == null) return;
                                setState(() => _selectedTeacher = teacher);
                                _loadTeacherTimetable(teacher);
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

            // Content
            Expanded(
              child: _selectedTeacher == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Select a teacher to view their schedule',
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
                              Text(
                                  'No scheduled lectures for ${_selectedTeacher!.name}',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14)),
                            ],
                          ),
                        )
                      : _TeacherWeekGrid(
                          weeklyData: _weeklyData,
                          teacherName: _selectedTeacher!.name,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Teacher weekly grid
// ─────────────────────────────────────────────────────────

class _TeacherWeekGrid extends StatelessWidget {
  final List<TimetableDay> weeklyData;
  final String teacherName;

  const _TeacherWeekGrid({
    required this.weeklyData,
    required this.teacherName,
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
    final availableDays = _teacherOrderedDays
        .where((d) => weeklyData.any((w) => w.dayName == d))
        .toList();

    // Compute total weekly lecture count
    int totalLectures = 0;
    for (final day in weeklyData) {
      for (final slot in day.slots) {
        totalLectures += slot.lectures.length;
      }
    }

    if (sortedTimes.isEmpty || availableDays.isEmpty) {
      return Center(
        child: Text('No lectures found for $teacherName',
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      children: [
        // Summary bar
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary,
                AppColors.secondary.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  teacherName[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(teacherName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Text('$totalLectures lectures this week',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Day chips summary
        Wrap(
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: count > 0
                    ? AppColors.secondary.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: count > 0
                      ? AppColors.secondary.withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                '${d.substring(0, 3)} · $count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: count > 0 ? AppColors.secondary : Colors.grey.shade500,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        // Day-by-day blocks
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary,
                        AppColors.secondary.withValues(alpha: 0.75),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
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
                          color: AppColors.secondary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  AppColors.secondary.withValues(alpha: 0.2)),
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
                                          color: AppColors.secondary)),
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
                                  final room =
                                      (lec.roomNumber ?? '').toString();
                                  final batch = (lec.batch ?? '').toString();
                                  final type =
                                      (lec.typeOfLecture ?? 'Lecture').toString();
                                  final isLab = type.toLowerCase() == 'lab';
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              subject.isNotEmpty
                                                  ? subject
                                                  : 'Subject',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isLab
                                                  ? Colors.indigo.withValues(
                                                      alpha: 0.12)
                                                  : AppColors.success
                                                      .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              type,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: isLab
                                                    ? Colors.indigo
                                                    : AppColors.success,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (room.isNotEmpty ||
                                          batch.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            if (room.isNotEmpty) ...[
                                              const Icon(
                                                  Icons.meeting_room_outlined,
                                                  size: 11,
                                                  color: Color(0xFF8590A5)),
                                              const SizedBox(width: 3),
                                              Text('Room $room',
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Color(0xFF5A657A))),
                                            ],
                                            if (room.isNotEmpty &&
                                                batch.isNotEmpty)
                                              const Text(' · ',
                                                  style: TextStyle(
                                                      color:
                                                          Color(0xFF8590A5))),
                                            if (batch.isNotEmpty)
                                              Text('Batch $batch',
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.secondary,
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
