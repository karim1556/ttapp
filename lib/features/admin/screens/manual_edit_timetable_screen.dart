import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/timetable_day_model.dart';
import '../../../models/time_slot_model.dart';
import '../../../models/lecture_assignment_model.dart';
import '../../../providers/timetable_provider.dart';
import '../../../providers/subject_provider.dart';
import '../../../providers/faculty_provider.dart';
import '../../../core/utils/academic_year.dart';

class ManualEditTimetableScreen extends ConsumerStatefulWidget {
  const ManualEditTimetableScreen({super.key});

  @override
  ConsumerState<ManualEditTimetableScreen> createState() => _ManualEditTimetableScreenState();
}

class _ManualEditTimetableScreenState extends ConsumerState<ManualEditTimetableScreen> {
  int? _selectedBranch;
  int? _selectedSemester;
  String? _selectedDivision;
  String _selectedAcadYear = '';

  static const _branches = {1: 'CS', 2: 'IT', 3: 'EXTC', 4: 'Mech'};
  static const _semesters = [1, 2, 3, 4, 5, 6, 7, 8];
  static const _divisions = ['A', 'B'];

  @override
  void initState() {
    super.initState();
    _selectedAcadYear = currentAcademicYear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subjectProvider.notifier).loadSubjects();
      ref.read(facultyProvider.notifier).loadFaculty();
    });
  }

  void _loadTimetable() {
    if (_selectedBranch != null && _selectedSemester != null && _selectedDivision != null) {
      ref.read(timetableProvider.notifier).loadWeeklyTimetable(
            branchId: _selectedBranch,
            semester: _selectedSemester,
            division: _selectedDivision,
            academicYear: _selectedAcadYear,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timetableState = ref.watch(timetableProvider);
    final isTimetableLoaded = timetableState.weeklyTimetable.isNotEmpty;
    final isLoading = timetableState.status == TimetableStatus.loading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Manual Timetable Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadTimetable,
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar Filter Panel
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Select Class',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: _selectedAcadYear,
                  decoration: const InputDecoration(labelText: 'Academic Year', prefixIcon: Icon(Icons.calendar_today_outlined, size: 18)),
                  items: academicYearOptions().map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedAcadYear = val);
                      _loadTimetable();
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedBranch,
                  decoration: const InputDecoration(labelText: 'Branch', prefixIcon: Icon(Icons.lan_outlined, size: 18)),
                  items: _branches.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedBranch = val);
                    _loadTimetable();
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedSemester,
                  decoration: const InputDecoration(labelText: 'Semester', prefixIcon: Icon(Icons.school_outlined, size: 18)),
                  items: _semesters.map((s) => DropdownMenuItem(value: s, child: Text('Sem $s'))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedSemester = val);
                    _loadTimetable();
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedDivision,
                  decoration: const InputDecoration(labelText: 'Division', prefixIcon: Icon(Icons.grid_view_rounded, size: 18)),
                  items: _divisions.map((d) => DropdownMenuItem(value: d, child: Text('Div $d'))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedDivision = val);
                    _loadTimetable();
                  },
                ),
                const Spacer(),
                if (isLoading)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Updating database...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Click Switch on any lecture to relocate or swap it with another slot across any weekday.',
                            style: TextStyle(fontSize: 11, height: 1.3, color: Colors.blueGrey),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Main Editor View
          Expanded(
            child: isLoading && !isTimetableLoaded
                ? const Center(child: CircularProgressIndicator())
                : !isTimetableLoaded
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_calendar_rounded, size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text(
                              'Select Branch, Semester & Division to load timetable',
                              style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : _buildWeeklyGrid(timetableState.weeklyTimetable),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyGrid(List<TimetableDay> weekly) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: weekly.length,
      itemBuilder: (context, index) {
        final dayData = weekly[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      dayData.dayName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${dayData.slots.where((s) => s.lectures.isNotEmpty).length} Periods',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              // Time slots list
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dayData.slots.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, sIdx) {
                  final slot = dayData.slots[sIdx];
                  final hasLecture = slot.lectures.isNotEmpty;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    color: hasLecture ? Colors.white : const Color(0xFFFAF9F6),
                    child: Row(
                      children: [
                        // Time column
                        SizedBox(
                          width: 120,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slot.startTimeDisplay,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                              ),
                              Text(
                                'to ${slot.endTimeDisplay}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        // Lecture contents
                        Expanded(
                          child: hasLecture
                              ? _buildLecturesSection(slot, dayData.dayName, weekly)
                              : Row(
                                  children: [
                                    Icon(Icons.free_breakfast_outlined, size: 16, color: Colors.grey.shade400),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Recess / Free Period',
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLecturesSection(TimeSlotModel slot, String dayName, List<TimetableDay> weekly) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: slot.lectures.map((lec) {
        final isLab = lec.isLabLecture;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          lec.subjectName ?? lec.subjectCode ?? 'No Subject',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLab ? AppColors.labBackground : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isLab ? 'Lab' : 'Lecture',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isLab ? AppColors.labText : AppColors.primary,
                            ),
                          ),
                        ),
                        if (lec.batch != null && lec.batch!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Batch ${lec.batch}',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 16,
                      children: [
                        _infoRow(Icons.person_outline, lec.facultyName ?? 'Unassigned'),
                        _infoRow(Icons.room_outlined, lec.roomNumber != null ? 'Room ${lec.roomNumber}' : 'No Room'),
                      ],
                    ),
                  ],
                ),
              ),
              // Action buttons (Edit & Switch)
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showEditDialog(lec),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showSwitchDialog(lec, dayName, slot, weekly),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                    label: const Text('Switch'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: const BorderSide(color: Colors.deepPurple),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  void _showEditDialog(LectureAssignmentModel lecture) {
    showDialog(
      context: context,
      builder: (_) => _EditDetailsDialog(
        lecture: lecture,
        onSaved: _loadTimetable,
      ),
    );
  }

  void _showSwitchDialog(LectureAssignmentModel lecture, String currentDayName, TimeSlotModel currentSlot, List<TimetableDay> weekly) {
    showDialog(
      context: context,
      builder: (_) => _SwitchSlotDialog(
        lecture: lecture,
        currentDayName: currentDayName,
        currentSlot: currentSlot,
        weeklyTimetable: weekly,
        onSaved: _loadTimetable,
      ),
    );
  }
}

// ── Dialog 1: Edit Details (Only text/meta info) ─────────────────────────────
class _EditDetailsDialog extends ConsumerStatefulWidget {
  final LectureAssignmentModel lecture;
  final VoidCallback onSaved;

  const _EditDetailsDialog({required this.lecture, required this.onSaved});

  @override
  ConsumerState<_EditDetailsDialog> createState() => _EditDetailsDialogState();
}

class _EditDetailsDialogState extends ConsumerState<_EditDetailsDialog> {
  String? _selectedSubjectCode;
  int? _selectedFacultyId;
  String? _lectureType;
  late TextEditingController _roomController;
  String? _selectedBatch;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedSubjectCode = widget.lecture.subjectCode;
    _selectedFacultyId = widget.lecture.facultyId;
    _lectureType = widget.lecture.typeOfLecture ?? 'Lecture';
    _selectedBatch = widget.lecture.batch;
    _roomController = TextEditingController(text: widget.lecture.roomNumber ?? '');

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
      'room_number': _roomController.text.trim().isNotEmpty ? _roomController.text.trim() : null,
      'batch': _selectedBatch,
    };

    final ok = await ref.read(timetableProvider.notifier).updateSlot(widget.lecture.id, updates);
    setState(() => _saving = false);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lecture details updated successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(timetableProvider).errorMessage ?? 'Failed to update details'),
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
      title: const Text('Edit Lecture Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: subjects.any((s) => s.subjectCode == _selectedSubjectCode) ? _selectedSubjectCode : null,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: subjects
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.subjectCode,
                      child: Text('${s.subjectName} (${s.subjectCode})', overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedSubjectCode = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: faculty.any((f) => f.facultyId == _selectedFacultyId) ? _selectedFacultyId : null,
              decoration: const InputDecoration(labelText: 'Faculty'),
              items: faculty
                  .map(
                    (f) => DropdownMenuItem(
                      value: f.facultyId,
                      child: Text(f.name.isNotEmpty ? f.name : 'Faculty ${f.facultyId}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedFacultyId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _lectureType,
              decoration: const InputDecoration(labelText: 'Lecture Type'),
              items: ['Lecture', 'Lab'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _lectureType = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedBatch,
              decoration: const InputDecoration(labelText: 'Batch (Optional)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Whole Division')),
                const DropdownMenuItem(value: 'A', child: Text('Batch A')),
                const DropdownMenuItem(value: 'B', child: Text('Batch B')),
                const DropdownMenuItem(value: 'C', child: Text('Batch C')),
              ],
              onChanged: (v) => setState(() => _selectedBatch = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _roomController,
              decoration: const InputDecoration(labelText: 'Room Number', hintText: 'e.g. 204'),
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
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }
}

// ── Dialog 2: Switch / Move Slot (Relocating lectures across days) ───────────
class _SwitchSlotDialog extends ConsumerStatefulWidget {
  final LectureAssignmentModel lecture;
  final String currentDayName;
  final TimeSlotModel currentSlot;
  final List<TimetableDay> weeklyTimetable;
  final VoidCallback onSaved;

  const _SwitchSlotDialog({
    required this.lecture,
    required this.currentDayName,
    required this.currentSlot,
    required this.weeklyTimetable,
    required this.onSaved,
  });

  @override
  ConsumerState<_SwitchSlotDialog> createState() => _SwitchSlotDialogState();
}

class _SwitchSlotDialogState extends ConsumerState<_SwitchSlotDialog> {
  String? _targetDayName;
  int? _targetSlotId;
  bool _saving = false;

  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  @override
  void initState() {
    super.initState();
    _targetDayName = widget.currentDayName;
    _targetSlotId = widget.lecture.timeTableDetailedId;
  }

  void _handleDayChanged(String? newDayName) {
    if (newDayName == null || newDayName == _targetDayName) return;

    final newDayData = widget.weeklyTimetable.firstWhere(
      (d) => d.dayName.toLowerCase() == newDayName.toLowerCase(),
    );

    final oldDayData = widget.weeklyTimetable.firstWhere(
      (d) => d.dayName.toLowerCase() == _targetDayName!.toLowerCase(),
    );

    final currentSlotIndex = oldDayData.slots.indexWhere((s) => s.id == _targetSlotId);

    setState(() {
      _targetDayName = newDayName;
      if (currentSlotIndex != -1 && currentSlotIndex < newDayData.slots.length) {
        _targetSlotId = newDayData.slots[currentSlotIndex].id;
      } else if (newDayData.slots.isNotEmpty) {
        _targetSlotId = newDayData.slots.first.id;
      }
    });
  }

  Future<void> _save() async {
    if (_targetSlotId == null || _targetSlotId == widget.lecture.timeTableDetailedId) {
      Navigator.pop(context);
      return;
    }

    setState(() => _saving = true);
    final ok = await ref.read(timetableProvider.notifier).moveLecture(
          lectureId: widget.lecture.id,
          targetSlotId: _targetSlotId!,
          swap: true,
        );

    setState(() => _saving = false);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lecture relocated/swapped successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(timetableProvider).errorMessage ?? 'Failed to move slot. Check conflicts.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDayData = widget.weeklyTimetable.firstWhere(
      (d) => d.dayName.toLowerCase() == _targetDayName!.toLowerCase(),
    );
    final availableSlots = activeDayData.slots;

    return AlertDialog(
      title: const Text('Switch / Move Lecture'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Move: ${widget.lecture.subjectName ?? widget.lecture.subjectCode}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Current: ${widget.currentDayName} ${widget.currentSlot.timeRangeDisplay}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _targetDayName,
            decoration: const InputDecoration(labelText: 'Target Day'),
            items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: _handleDayChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _targetSlotId,
            decoration: const InputDecoration(labelText: 'Target Slot / Period'),
            items: availableSlots
                .map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text('${s.timeRangeDisplay}${s.lectures.isNotEmpty ? ' (${s.lectures.first.subjectCode})' : ' (Free Slot)'}'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _targetSlotId = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Move / Switch'),
        ),
      ],
    );
  }
}
