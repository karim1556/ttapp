import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/lecture_assignment_model.dart';
import '../../../models/timetable_day_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/faculty_provider.dart';
import '../../../providers/subject_provider.dart';
import '../../../providers/timetable_provider.dart';
import '../../../services/timetable_export_service.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/loading_overlay_widget.dart';
import '../widgets/timetable_grid_widget.dart';
import '../widgets/lecture_detail_sheet.dart';
import '../../../models/time_slot_model.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDayIndex = 0;

  int? _selectedBranch;
  int? _selectedSemester;
  String? _selectedDivision;

  static const _branches = {1: 'CS', 2: 'IT', 3: 'EXTC', 4: 'Mech'};
  static const _semesters = [1, 2, 3, 4, 5, 6, 7, 8];
  static const _divisions = ['A', 'B', 'C', 'D'];

  static final _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();

    // Default to today's tab
    final dayOfWeek = DateTime.now().weekday; // 1=Mon … 7=Sun
    _selectedDayIndex = (dayOfWeek <= 6) ? dayOfWeek - 1 : 0;

    _tabController = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: _selectedDayIndex,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTimetable();
    });
  }

  void _loadTimetable() {
    ref.read(timetableProvider.notifier).loadWeeklyTimetable(
          branchId: _selectedBranch,
          semester: _selectedSemester,
          division: _selectedDivision,
        );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timetableState = ref.watch(timetableProvider);
    final isLoading = timetableState.status == TimetableStatus.loading &&
        timetableState.weeklyTimetable.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Timetable'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF',
            onPressed: _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadTimetable,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: _days
              .map((d) => Tab(text: d.substring(0, 3)))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          _FilterBar(
            selectedBranch: _selectedBranch,
            selectedSemester: _selectedSemester,
            selectedDivision: _selectedDivision,
            branches: _branches,
            semesters: _semesters,
            divisions: _divisions,
            onBranchChanged: (val) {
              setState(() => _selectedBranch = val);
              _loadTimetable();
            },
            onSemesterChanged: (val) {
              setState(() => _selectedSemester = val);
              _loadTimetable();
            },
            onDivisionChanged: (val) {
              setState(() => _selectedDivision = val);
              _loadTimetable();
            },
          ),
          Expanded(
            child: isLoading
                ? const FullScreenLoader(message: 'Loading timetable...')
                : timetableState.status == TimetableStatus.error &&
                        timetableState.weeklyTimetable.isEmpty
                    ? ErrorStateWidget(
                        message: timetableState.errorMessage,
                        onRetry: _loadTimetable,
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: _days.map((dayName) {
                          final dayData = _getDayData(
                            timetableState.weeklyTimetable,
                            dayName,
                          );
                          return _DayTimetableView(
                            dayName: dayName,
                            timetableDay: dayData,
                            onSlotTap: (slot) =>
                                _showLectureDetail(context, slot),
                          );
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }

  TimetableDay? _getDayData(List<TimetableDay> weekly, String dayName) {
    try {
      return weekly.firstWhere(
        (d) => d.dayName.toLowerCase() == dayName.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  void _showLectureDetail(BuildContext context, TimeSlotModel slot) {
    if (slot.lectures.isEmpty) return;
    final isAdmin = ref.read(currentUserProvider)?.isAdmin ?? false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LectureDetailSheet(
        slot: slot,
        onEdit: isAdmin ? (lec) => _showEditDialog(context, lec) : null,
      ),
    );
  }

  void _showEditDialog(BuildContext context, LectureAssignmentModel lecture) {
    showDialog(
      context: context,
      builder: (_) => _EditLectureDialog(
        lecture: lecture,
        onSaved: _loadTimetable,
      ),
    );
  }

  Future<void> _exportPdf() async {
    final timetableState = ref.read(timetableProvider);
    if (timetableState.weeklyTimetable.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No timetable data to export. Load a timetable first.')),
        );
      }
      return;
    }
    final divLabel = _selectedDivision != null ? '_Div${_selectedDivision}' : '';
    final branchLabel = _selectedBranch != null ? '_${_branches[_selectedBranch]}' : '';
    final semLabel = _selectedSemester != null ? '_Sem${_selectedSemester}' : '';
    await Printing.layoutPdf(
      name: 'Timetable$branchLabel$semLabel$divLabel',
      onLayout: (_) => buildTimetablePdf(
        timetableState.weeklyTimetable,
        branchId: _selectedBranch,
        semester: _selectedSemester,
        division: _selectedDivision,
      ),
    );
  }
}

// ── Admin: slot editing dialog ───────────────────────────────────────────────
class _EditLectureDialog extends ConsumerStatefulWidget {
  final LectureAssignmentModel lecture;
  final VoidCallback onSaved;

  const _EditLectureDialog({required this.lecture, required this.onSaved});

  @override
  ConsumerState<_EditLectureDialog> createState() => _EditLectureDialogState();
}

class _EditLectureDialogState extends ConsumerState<_EditLectureDialog> {
  String? _selectedSubjectCode;
  int? _selectedFacultyId;
  String? _lectureType;
  late TextEditingController _roomController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedSubjectCode = widget.lecture.subjectCode;
    _selectedFacultyId = widget.lecture.facultyId;
    _lectureType = widget.lecture.typeOfLecture ?? 'Lecture';
    _roomController =
        TextEditingController(text: widget.lecture.roomNumber ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(subjectProvider).subjects.isEmpty) {
        ref.read(subjectProvider.notifier).loadSubjects();
      }
      if (ref.read(facultyProvider).faculty.isEmpty) {
        ref.read(facultyProvider.notifier).loadFaculty();
      }
    });
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updates = <String, dynamic>{
      if (_selectedSubjectCode != null) 'subjectCode': _selectedSubjectCode,
      if (_selectedFacultyId != null) 'facultyid': _selectedFacultyId,
      if (_lectureType != null) 'typeOfLecture': _lectureType,
      'room_number': _roomController.text.trim().isNotEmpty
          ? _roomController.text.trim()
          : null,
    };
    final ok = await ref
        .read(timetableProvider.notifier)
        .updateSlot(widget.lecture.id, updates);
    setState(() => _saving = false);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(timetableProvider).errorMessage ?? 'Failed to update slot',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectProvider).subjects;
    final faculty = ref.watch(facultyProvider).faculty;

    return AlertDialog(
      title: const Text('Edit Lecture'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: subjects.any((s) => s.subjectCode == _selectedSubjectCode)
                  ? _selectedSubjectCode
                  : null,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: subjects
                  .map((s) => DropdownMenuItem(
                        value: s.subjectCode,
                        child: Text(
                          '${s.subjectName ?? s.subjectCode} (${s.subjectCode})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSubjectCode = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: faculty.any((f) => f.facultyId == _selectedFacultyId)
                  ? _selectedFacultyId
                  : null,
              decoration: const InputDecoration(labelText: 'Faculty'),
              items: faculty
                  .map((f) => DropdownMenuItem(
                        value: f.facultyId,
                        child: Text(f.name ?? 'Faculty ${f.facultyId}'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFacultyId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _lectureType,
              decoration: const InputDecoration(labelText: 'Lecture Type'),
              items: ['Lecture', 'Lab', 'Tutorial']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _lectureType = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _roomController,
              decoration: const InputDecoration(
                labelText: 'Room Number',
                hintText: 'e.g. 204',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final int? selectedBranch;
  final int? selectedSemester;
  final String? selectedDivision;
  final Map<int, String> branches;
  final List<int> semesters;
  final List<String> divisions;
  final ValueChanged<int?> onBranchChanged;
  final ValueChanged<int?> onSemesterChanged;
  final ValueChanged<String?> onDivisionChanged;

  const _FilterBar({
    required this.selectedBranch,
    required this.selectedSemester,
    required this.selectedDivision,
    required this.branches,
    required this.semesters,
    required this.divisions,
    required this.onBranchChanged,
    required this.onSemesterChanged,
    required this.onDivisionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: selectedBranch,
              decoration: const InputDecoration(
                labelText: 'Branch',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...branches.entries.map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                ),
              ],
              onChanged: onBranchChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: selectedSemester,
              decoration: const InputDecoration(
                labelText: 'Semester',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...semesters.map(
                  (s) => DropdownMenuItem(value: s, child: Text('Sem $s')),
                ),
              ],
              onChanged: onSemesterChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedDivision,
              decoration: const InputDecoration(
                labelText: 'Division',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...divisions.map(
                  (d) => DropdownMenuItem(value: d, child: Text('Div $d')),
                ),
              ],
              onChanged: onDivisionChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayTimetableView extends StatelessWidget {
  final String dayName;
  final TimetableDay? timetableDay;
  final void Function(TimeSlotModel) onSlotTap;

  const _DayTimetableView({
    required this.dayName,
    required this.timetableDay,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    if (timetableDay == null || timetableDay!.slots.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.event_busy_outlined,
        title: 'No lectures on $dayName',
        subtitle: 'Either no timetable configured for this day or it\'s a free day.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: timetableDay!.slots.length,
      itemBuilder: (context, index) {
        final slot = timetableDay!.slots[index];
        final colorIndex = index % AppColors.subjectColors.length;
        final hasLecture = slot.lectures.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TimetableGridWidget(
            slot: slot,
            color: hasLecture ? AppColors.subjectColors[colorIndex] : null,
            onTap: hasLecture ? () => onSlotTap(slot) : null,
          ),
        );
      },
    );
  }
}
