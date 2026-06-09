import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../navigation/app_router.dart';
import '../../../models/lecture_assignment_model.dart';
import '../../../models/timetable_day_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/faculty_provider.dart';
import '../../../providers/substitution_provider.dart';
import '../../../providers/subject_provider.dart';
import '../../../providers/timetable_provider.dart';
import '../../../services/timetable_export_service.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/loading_overlay_widget.dart';
import '../widgets/timetable_grid_widget.dart';
import '../widgets/lecture_detail_sheet.dart';
import '../utils/slot_grouping.dart';
import '../../../models/time_slot_model.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  int _selectedDayIndex = 0;

  int? _selectedBranch;
  int? _selectedSemester;
  String? _selectedDivision;
  bool _dragEditMode = false;

  static const _branches = {1: 'CS', 2: 'IT', 3: 'EXTC', 4: 'Mech'};
  static const _semesters = [1, 2, 3, 4, 5, 6, 7, 8];
  static const _divisions = ['A', 'B'];

  static final _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  @override
  void initState() {
    super.initState();

    // Default to today's tab
    final dayOfWeek = DateTime.now().weekday; // 1=Mon … 7=Sun
    _selectedDayIndex = (dayOfWeek <= 5) ? dayOfWeek - 1 : 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTimetable();
    });
  }

  void _loadTimetable() {
    final user = ref.read(currentUserProvider);
    final isFaculty = user?.isFaculty ?? false;

    if (isFaculty && user != null) {
      ref.read(timetableProvider.notifier).loadFacultyTimetable(user.uid);
    } else {
      ref
          .read(timetableProvider.notifier)
          .loadWeeklyTimetable(
            branchId: _selectedBranch,
            semester: _selectedSemester,
            division: _selectedDivision,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timetableState = ref.watch(timetableProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final isLoading =
        timetableState.status == TimetableStatus.loading &&
        timetableState.weeklyTimetable.isEmpty;

    int occupiedCountForDay(String dayName) {
      final dayData = _getDayData(timetableState.weeklyTimetable, dayName);
      if (dayData == null) return 0;
      final slots = collapseConsecutiveLabSlots(dayData.slots);
      return slots.where((s) => s.lectures.isNotEmpty).length;
    }

    final selectedDayName = _days[_selectedDayIndex];
    final selectedDayData = _getDayData(
      timetableState.weeklyTimetable,
      selectedDayName,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Timetable' : 'My Timetable'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          if (isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Substitution records',
              onPressed: () => context.push(AppRoutes.substitutions),
            ),
            IconButton(
              icon: Icon(
                _dragEditMode
                    ? Icons.pan_tool_alt_rounded
                    : Icons.open_with_rounded,
              ),
              tooltip: _dragEditMode
                  ? 'Disable Drag & Drop Editing'
                  : 'Enable Drag & Drop Editing',
              onPressed: () {
                setState(() => _dragEditMode = !_dragEditMode);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _dragEditMode
                          ? 'Drag mode enabled. Long-press a lecture and drop into another slot.'
                          : 'Drag mode disabled.',
                    ),
                  ),
                );
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF',
            onPressed: _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.table_view_outlined),
            tooltip: 'Export Excel (CSV)',
            onPressed: _exportExcelCsv,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadTimetable,
          ),
        ],
      ),
      body: Column(
        children: [
          if (isAdmin)
            _TimetableSummaryHeader(
              selectedBranch: _selectedBranch != null
                  ? (_branches[_selectedBranch] ?? 'Unknown Branch')
                  : 'All Branches',
              selectedSemester: _selectedSemester != null
                  ? 'Sem $_selectedSemester'
                  : 'All Semesters',
              selectedDivision: _selectedDivision != null
                  ? 'Div $_selectedDivision'
                  : 'All Divisions',
            )
          else
            _FacultyTimetableHeader(dayName: selectedDayName),
          const SizedBox(height: 10),
          SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final day = _days[index];
                return _DaySelectorChip(
                  label: day.substring(0, 3),
                  lectureCount: occupiedCountForDay(day),
                  selected: index == _selectedDayIndex,
                  onTap: () => setState(() => _selectedDayIndex = index),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemCount: _days.length,
            ),
          ),
          const SizedBox(height: 10),
          if (isAdmin && _dragEditMode)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: AppColors.warning.withValues(alpha: 0.12),
              child: const Row(
                children: [
                  Icon(Icons.touch_app_outlined, color: AppColors.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Drag mode is ON: long-press any lecture card and drop it on another slot to move/swap.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          if (isAdmin && _dragEditMode) const SizedBox(height: 10),
          if (isAdmin)
            _FilterBar(
              selectedBranch: _selectedBranch,
              selectedSemester: _selectedSemester,
              selectedDivision: _selectedDivision,
              branches: _branches,
              semesters: _semesters,
              divisions: _divisions,
              onResetFilters: () {
                setState(() {
                  _selectedBranch = null;
                  _selectedSemester = null;
                  _selectedDivision = null;
                });
                _loadTimetable();
              },
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
                : _DayTimetableView(
                    dayName: selectedDayName,
                    timetableDay: selectedDayData,
                    onSlotTap: (slot) =>
                        _showLectureDetail(context, slot, selectedDayName),
                    enableDragDrop: isAdmin && _dragEditMode,
                    onMoveLecture: (lecture, targetSlot) =>
                        _moveLectureToSlot(lecture, targetSlot),
                    isAdmin: isAdmin,
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

  void _showLectureDetail(
    BuildContext context,
    TimeSlotModel slot,
    String dayName,
  ) {
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
        onSubstitute: isAdmin
            ? (lec) => _showSubstitutionDialog(
                  context,
                  lecture: lec,
                  slot: slot,
                  dayName: dayName,
                )
            : null,
      ),
    );
  }

  Future<void> _showSubstitutionDialog(
    BuildContext context, {
    required LectureAssignmentModel lecture,
    required TimeSlotModel slot,
    required String dayName,
  }) async {
    final timetableState = ref.read(timetableProvider);

    await showDialog<void>(
      context: context,
      builder: (_) => _SubstitutionDialog(
        lecture: lecture,
        slot: slot,
        dayName: dayName,
        weeklyTimetable: timetableState.weeklyTimetable,
      ),
    );
  }

  void _showEditDialog(BuildContext context, LectureAssignmentModel lecture) {
    showDialog(
      context: context,
      builder: (_) =>
          _EditLectureDialog(lecture: lecture, onSaved: _loadTimetable),
    );
  }

  Future<void> _exportPdf() async {
    final timetableState = ref.read(timetableProvider);
    if (timetableState.weeklyTimetable.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No timetable data to export. Load a timetable first.',
            ),
          ),
        );
      }
      return;
    }
    final divLabel = _selectedDivision != null ? '_Div$_selectedDivision' : '';
    final branchLabel = _selectedBranch != null
        ? '_${_branches[_selectedBranch]}'
        : '';
    final semLabel = _selectedSemester != null ? '_Sem$_selectedSemester' : '';
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

  Future<void> _exportExcelCsv() async {
    final timetableState = ref.read(timetableProvider);
    if (timetableState.weeklyTimetable.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No timetable data to export. Load a timetable first.',
            ),
          ),
        );
      }
      return;
    }

    final csv = buildTimetableCsv(
      timetableState.weeklyTimetable,
      branchId: _selectedBranch,
      semester: _selectedSemester,
      division: _selectedDivision,
    );

    final divLabel = _selectedDivision != null ? '_Div$_selectedDivision' : '';
    final branchLabel = _selectedBranch != null
        ? '_${_branches[_selectedBranch]}'
        : '';
    final semLabel = _selectedSemester != null ? '_Sem$_selectedSemester' : '';
    final fileName = 'Timetable$branchLabel$semLabel$divLabel.csv';

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(utf8.encode(csv), flush: true);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Timetable export (Excel-compatible CSV)',
        subject: 'Timetable Export',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export CSV: $e')));
    }
  }

  Future<void> _moveLectureToSlot(
    LectureAssignmentModel lecture,
    TimeSlotModel targetSlot,
  ) async {
    if (lecture.timeTableDetailedId == targetSlot.id) return;

    final ok = await ref
        .read(timetableProvider.notifier)
        .moveLecture(
          lectureId: lecture.id,
          targetSlotId: targetSlot.id,
          swap: true,
        );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lecture moved successfully.')),
      );
      _loadTimetable();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(timetableProvider).errorMessage ??
                'Failed to move lecture. Check conflicts and try again.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
    _roomController = TextEditingController(
      text: widget.lecture.roomNumber ?? '',
    );

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
              initialValue:
                  subjects.any((s) => s.subjectCode == _selectedSubjectCode)
                  ? _selectedSubjectCode
                  : null,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: subjects
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.subjectCode,
                      child: Text(
                        '${s.subjectName} (${s.subjectCode})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedSubjectCode = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue:
                  faculty.any((f) => f.facultyId == _selectedFacultyId)
                  ? _selectedFacultyId
                  : null,
              decoration: const InputDecoration(labelText: 'Faculty'),
              items: faculty
                  .map(
                    (f) => DropdownMenuItem(
                      value: f.facultyId,
                      child: Text(
                        f.name.isNotEmpty ? f.name : 'Faculty ${f.facultyId}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedFacultyId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _lectureType,
              decoration: const InputDecoration(labelText: 'Lecture Type'),
              items: [
                'Lecture',
                'Lab',
                'Tutorial',
              ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
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

class _SubstitutionDialog extends ConsumerStatefulWidget {
  final LectureAssignmentModel lecture;
  final TimeSlotModel slot;
  final String dayName;
  final List<TimetableDay> weeklyTimetable;

  const _SubstitutionDialog({
    required this.lecture,
    required this.slot,
    required this.dayName,
    required this.weeklyTimetable,
  });

  @override
  ConsumerState<_SubstitutionDialog> createState() => _SubstitutionDialogState();
}

class _SubstitutionDialogState extends ConsumerState<_SubstitutionDialog> {
  late DateTime _selectedDate;
  late final TextEditingController _reasonController;
  int? _selectedFacultyId;
  bool _isPreviewing = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = _nextDateForWeekday(widget.dayName);
    _reasonController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(facultyProvider).faculty.isEmpty) {
        ref.read(facultyProvider.notifier).loadFaculty();
      }
      _runPreview();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    ref.read(substitutionProvider.notifier).clearPreview();
    super.dispose();
  }

  DateTime _nextDateForWeekday(String dayName) {
    const dayIndex = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };

    final target = dayIndex[dayName.toLowerCase()] ?? DateTime.monday;
    final now = DateTime.now();
    var candidate = DateTime(now.year, now.month, now.day);
    while (candidate.weekday != target || candidate.isBefore(DateTime(now.year, now.month, now.day))) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) return;
    setState(() => _selectedDate = picked);
    await _runPreview();
  }

  Future<void> _runPreview() async {
    setState(() => _isPreviewing = true);
    var faculty = ref.read(facultyProvider).faculty;
    if (faculty.isEmpty) {
      await ref.read(facultyProvider.notifier).loadFaculty();
      faculty = ref.read(facultyProvider).faculty;
    }

    if (faculty.isEmpty) {
      if (mounted) {
        setState(() => _isPreviewing = false);
      }
      return;
    }

    await ref
        .read(substitutionProvider.notifier)
        .previewCandidates(
          lecture: widget.lecture,
          slot: widget.slot,
          dayName: widget.dayName,
          date: _selectedDate,
          weeklyTimetable: widget.weeklyTimetable,
          faculty: faculty,
        );

    final preview = ref.read(substitutionProvider).previewCandidates;
    if (_selectedFacultyId == null && preview.isNotEmpty) {
      final recommended = preview.firstWhere(
        (e) => !e.hasConflict,
        orElse: () => preview.first,
      );
      _selectedFacultyId = recommended.facultyId;
    }
    if (mounted) {
      setState(() => _isPreviewing = false);
    }
  }

  Future<void> _approveSubstitution() async {
    if (_selectedFacultyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a substitute faculty first.')),
      );
      return;
    }

    final facultyState = ref.read(facultyProvider);
    final selectedFaculty = facultyState.faculty.where(
      (f) => f.facultyId == _selectedFacultyId,
    );
    if (selectedFaculty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected faculty is no longer available.')),
      );
      return;
    }
    final currentUser = ref.read(currentUserProvider);

    final record = await ref
        .read(substitutionProvider.notifier)
        .createAndApprove(
          lecture: widget.lecture,
          slot: widget.slot,
          dayName: widget.dayName,
          date: _selectedDate,
          substituteFacultyId: _selectedFacultyId!,
          substituteFacultyName: selectedFaculty.first.name,
          reason: _reasonController.text.trim().isEmpty
              ? null
              : _reasonController.text.trim(),
          approvedBy: currentUser?.uid,
        );

    if (!mounted) return;
    if (record == null) {
      final msg = ref.read(substitutionProvider).errorMessage ??
          'Failed to create substitution.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
      return;
    }

    try {
      await ref
          .read(notificationServiceProvider)
          .pushInAppNotification(
            title: 'Substitution Approved',
            body:
                '${selectedFaculty.first.name} assigned on ${widget.dayName} (${widget.slot.timeRangeDisplay})',
            data: {
              'type': 'substitution',
              'substitutionId': record.id,
              'lectureId': widget.lecture.id,
            },
          );
    } catch (_) {}

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Substitution approved for selected date. Weekly timetable remains unchanged.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final substitutionState = ref.watch(substitutionProvider);
    final facultyState = ref.watch(facultyProvider);
    final preview = substitutionState.previewCandidates;
    final dateLabel =
        '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: const Text('Temporary Substitution'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.lecture.subjectName ??
                    widget.lecture.subjectCode ??
                    'Lecture',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.dayName} • ${widget.slot.timeRangeDisplay}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Apply Date'),
                      child: Text(dateLabel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                    label: const Text('Change'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _reasonController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'Faculty unavailable due to urgent work',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'What-if Preview',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: _isPreviewing ? null : _runPreview,
                    icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
                    label: const Text('Refresh Preview'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isPreviewing)
                const Center(child: CircularProgressIndicator())
              else if (facultyState.faculty.isEmpty)
                const Text(
                  'Faculty list is empty. Add faculty first.',
                  style: TextStyle(color: AppColors.error),
                )
              else if (preview.isEmpty)
                const Text(
                  'No preview candidates found for this slot.',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else
                ...preview.map((candidate) {
                  return RadioListTile<int>(
                    value: candidate.facultyId,
                    groupValue: _selectedFacultyId,
                    onChanged: (value) => setState(() => _selectedFacultyId = value),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      candidate.facultyName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${candidate.summary}  Score: ${candidate.score.toStringAsFixed(1)}',
                    ),
                    secondary: Icon(
                      candidate.hasConflict
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      color: candidate.hasConflict
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: substitutionState.isSubmitting ? null : _approveSubstitution,
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('One-tap Approve'),
        ),
      ],
    );
  }
}

// ── Faculty-specific timetable header ────────────────────────────────────────
class _FacultyTimetableHeader extends StatelessWidget {
  final String dayName;

  const _FacultyTimetableHeader({required this.dayName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5E87F7), Color(0xFF79A1FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Timetable',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$dayName — Your weekly teaching schedule',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimetableSummaryHeader extends StatelessWidget {
  final String selectedBranch;
  final String selectedSemester;
  final String selectedDivision;

  const _TimetableSummaryHeader({
    required this.selectedBranch,
    required this.selectedSemester,
    required this.selectedDivision,
  });

  @override
  Widget build(BuildContext context) {
    final currentView =
        '$selectedBranch • $selectedSemester • $selectedDivision';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5E87F7), Color(0xFF79A1FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              currentView,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySelectorChip extends StatelessWidget {
  final String label;
  final int lectureCount;
  final bool selected;
  final VoidCallback onTap;

  const _DaySelectorChip({
    required this.label,
    required this.lectureCount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$lectureCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
  final VoidCallback onResetFilters;
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
    required this.onResetFilters,
    required this.onBranchChanged,
    required this.onSemesterChanged,
    required this.onDivisionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final branchLabel = selectedBranch != null
        ? (branches[selectedBranch] ?? 'Unknown Branch')
        : 'All Branches';
    final semesterLabel = selectedSemester != null
        ? 'Sem $selectedSemester'
        : 'All Semesters';
    final divisionLabel = selectedDivision != null
        ? 'Div $selectedDivision'
        : 'All Divisions';
    final hasAnyFilter =
        selectedBranch != null ||
        selectedSemester != null ||
        selectedDivision != null;
    final isFocusedClass =
        selectedBranch != null &&
        selectedSemester != null &&
        selectedDivision != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFocusedClass
                    ? AppColors.primary.withValues(alpha: 0.38)
                    : AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isFocusedClass
                      ? Icons.check_circle_outline_rounded
                      : Icons.tune_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFocusedClass
                            ? 'Now showing one class timetable'
                            : 'Currently viewing',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$branchLabel • $semesterLabel • $divisionLabel',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (!isFocusedClass)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            'Tip: choose Branch + Semester + Division for one exact timetable.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasAnyFilter)
                  TextButton(
                    onPressed: onResetFilters,
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: selectedBranch,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Branch',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...branches.entries.map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ),
                  ],
                  onChanged: onBranchChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: selectedSemester,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
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
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedDivision,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Division',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
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
        ],
      ),
    );
  }
}

class _DayTimetableView extends StatelessWidget {
  final String dayName;
  final TimetableDay? timetableDay;
  final void Function(TimeSlotModel) onSlotTap;
  final bool enableDragDrop;
  final void Function(LectureAssignmentModel, TimeSlotModel)? onMoveLecture;
  final bool isAdmin;

  const _DayTimetableView({
    required this.dayName,
    required this.timetableDay,
    required this.onSlotTap,
    this.enableDragDrop = false,
    this.onMoveLecture,
    this.isAdmin = true,
  });

  @override
  Widget build(BuildContext context) {
    if (timetableDay == null || timetableDay!.slots.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.event_busy_outlined,
        title: 'No lectures on $dayName',
        subtitle:
            'Either no timetable configured for this day or it\'s a free day.',
      );
    }

    final visibleSlots = enableDragDrop
        ? timetableDay!.slots
        : collapseConsecutiveLabSlots(timetableDay!.slots);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: visibleSlots.length,
      itemBuilder: (context, index) {
        final slot = visibleSlots[index];
        final colorIndex = index % AppColors.subjectColors.length;
        final hasLecture = slot.lectures.isNotEmpty;
        final lecture = hasLecture ? slot.lectures.first : null;

        final baseCard = TimetableGridWidget(
          slot: slot,
          color: hasLecture ? AppColors.subjectColors[colorIndex] : null,
          onTap: hasLecture ? () => onSlotTap(slot) : null,
        );

        Widget card = baseCard;

        if (isAdmin && enableDragDrop) {
          card = DragTarget<LectureAssignmentModel>(
            onWillAcceptWithDetails: (details) {
              final incoming = details.data;
              return incoming.timeTableDetailedId != slot.id;
            },
            onAcceptWithDetails: (details) {
              onMoveLecture?.call(details.data, slot);
            },
            builder: (context, candidates, _) {
              final isHighlighted = candidates.isNotEmpty;

              Widget visual = AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: isHighlighted
                      ? Border.all(color: AppColors.warning, width: 2)
                      : null,
                ),
                child: baseCard,
              );

              if (lecture != null) {
                visual = LongPressDraggable<LectureAssignmentModel>(
                  data: lecture,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 260,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '${lecture.subjectName ?? lecture.subjectCode ?? 'Lecture'} • ${lecture.facultyName ?? ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(opacity: 0.45, child: visual),
                  child: visual,
                );
              }

              return visual;
            },
          );
        }

        return Padding(padding: const EdgeInsets.only(bottom: 8), child: card);
      },
    );
  }
}
