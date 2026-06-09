import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/subject_model.dart';
import '../../../providers/subject_provider.dart';
import '../../../providers/faculty_provider.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/loading_overlay_widget.dart';
import '../../../core/utils/academic_year.dart';

class ManageSubjectsScreen extends ConsumerStatefulWidget {
  const ManageSubjectsScreen({super.key});

  @override
  ConsumerState<ManageSubjectsScreen> createState() =>
      _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends ConsumerState<ManageSubjectsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedSemester;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subjectProvider.notifier).loadSubjects();
      ref.read(facultyProvider.notifier).loadFaculty();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectState = ref.watch(subjectProvider);
    final isLoading = subjectState.status == SubjectStatus.loading &&
        subjectState.subjects.isEmpty;

    final filtered = subjectState.subjects.where((s) {
      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          s.subjectName.toLowerCase().contains(q) ||
          s.subjectCode.toLowerCase().contains(q);
      final matchesSem = _selectedSemester == null ||
          s.semester == _selectedSemester;
      return matchesQuery && matchesSem;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subjects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.read(subjectProvider.notifier).loadSubjects(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubjectFormDialog(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
      ),
      body: Column(
        children: [
          // Search + filter row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by name or code...',
                      prefixIcon: Icon(Icons.search_outlined),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 8),
                _SemesterFilterChip(
                  selected: _selectedSemester,
                  onChanged: (sem) =>
                      setState(() => _selectedSemester = sem),
                ),
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? const FullScreenLoader(message: 'Loading subjects...')
                : filtered.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.menu_book_outlined,
                        title: 'No subjects found',
                        subtitle: _searchQuery.isNotEmpty ||
                                _selectedSemester != null
                            ? 'Try adjusting your filters'
                            : 'Add your first subject using the + button',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _SubjectCard(
                            subject: filtered[index],
                            onEdit: () => _showSubjectFormDialog(
                                context, filtered[index]),
                            onDelete: () =>
                                _confirmDelete(context, filtered[index]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showSubjectFormDialog(BuildContext context, SubjectModel? existing) {
    final nameCtrl =
        TextEditingController(text: existing?.subjectName);
    final codeCtrl =
        TextEditingController(text: existing?.subjectCode);
    final weeklyHoursCtrl = TextEditingController(
      text: existing == null
        ? ''
        : (existing.weeklyHours ?? existing.totalCredits).toString());
    final semesterHoursCtrl = TextEditingController(
      text: existing?.semesterHours?.toString() ?? '');
    final maxMarksCtrl = TextEditingController(
        text: existing?.maxMarks?.toString() ?? '');
    final oralMarksCtrl = TextEditingController(
        text: existing?.oralMarks?.toString() ?? '');
    final practicalMarksCtrl = TextEditingController(
        text: existing?.practicalMarks?.toString() ?? '');
    final passingMarksCtrl = TextEditingController(
        text: existing?.passingMarks?.toString() ?? '');
    final numModulesCtrl = TextEditingController(
        text: existing?.numModules?.toString() ?? '');
    final numExperimentsCtrl = TextEditingController(
        text: existing?.numExperiments?.toString() ?? '');
    final numAssignmentsCtrl = TextEditingController(
        text: existing?.numAssignments?.toString() ?? '');
    final experimentsCtrl = TextEditingController(
        text: existing?.experiments ?? '');
    final theoryCtrl = TextEditingController(
        text: existing?.theory ?? '');
    bool isPractical = existing?.isLabSubject ?? false;
    bool isOral = (existing?.isOral ?? 0) == 1;
    final formKey = GlobalKey<FormState>();

    // semester options
    final semesters = List.generate(8, (i) => (i + 1).toString());
    String semValue =
        existing?.semester?.toString() ?? semesters.first;

    int branchId = existing?.branchId ?? 1;
    String acadYear = existing?.acadYear ?? currentAcademicYear();

    // Professor assignment - use faculty list
    final facultyList = ref.read(facultyProvider).faculty;
    String? professorAssign = existing?.professorAssign;

    // Batch-wise professor assignments for lab subjects (A, B, C)
    final batchProfessors = <String, String?>{'A': null, 'B': null, 'C': null};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Subject' : 'Edit Subject'),
          insetPadding: const EdgeInsets.symmetric(horizontal: 12),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Subject Name *'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: codeCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Subject Code *'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: semValue,
                            decoration: const InputDecoration(labelText: 'Semester'),
                            items: semesters
                                .map((s) => DropdownMenuItem(
                                    value: s, child: Text('Sem $s')))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) semValue = v;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: branchId,
                            decoration: const InputDecoration(labelText: 'Branch *'),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('CS')),
                              DropdownMenuItem(value: 2, child: Text('IT')),
                              DropdownMenuItem(value: 3, child: Text('EXTC')),
                              DropdownMenuItem(value: 4, child: Text('Mech')),
                            ],
                            onChanged: (v) =>
                                setDialogState(() => branchId = v ?? 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: acadYear,
                      decoration: const InputDecoration(labelText: 'Academic Year'),
                      items: academicYearOptions()
                          .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) acadYear = v;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: weeklyHoursCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Weekly Required Hours *'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (int.tryParse(v.trim()) == null) return 'Must be a number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: semesterHoursCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Total Semester Hours (e.g. 20)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (int.tryParse(v.trim()) == null) return 'Must be a number';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Assign Teacher',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),

                    // Professor assignment dropdown
                    DropdownButtonFormField<String>(
                      value: professorAssign,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Professor',
                        hintText: 'Select a teacher',
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('-- None --', style: TextStyle(color: Colors.grey)),
                        ),
                        ...facultyList.map((f) => DropdownMenuItem<String>(
                              value: f.facultyId.toString(),
                              child: Text('${f.name} (${f.email})'),
                            )),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => professorAssign = v),
                    ),

                    // Batch-wise professor assignment for lab subjects
                    if (isPractical) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Batch-wise Teacher Assignment',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.labText, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lab subjects get 3 batch variants (A, B, C). Assign a teacher for each batch.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      for (final batch in ['A', 'B', 'C']) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                child: Text('Batch $batch',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: batchProfessors[batch],
                                  decoration: InputDecoration(
                                    labelText: 'Teacher for Batch $batch',
                                    hintText: 'Select teacher',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('-- Same as default --',
                                          style: TextStyle(color: Colors.grey)),
                                    ),
                                    ...facultyList.map((f) => DropdownMenuItem<String>(
                                          value: f.facultyId.toString(),
                                          child: Text(f.name ?? 'Unknown'),
                                        )),
                                  ],
                                  onChanged: (v) =>
                                      setDialogState(() => batchProfessors[batch] = v),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Type & Marks',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),

                    SwitchListTile(
                      title: const Text('Lab / Practical Subject'),
                      subtitle: const Text('Requires double slot'),
                      value: isPractical,
                      onChanged: (v) => setDialogState(() => isPractical = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: const Text('Has Oral Exam'),
                      value: isOral,
                      onChanged: (v) => setDialogState(() => isOral = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: maxMarksCtrl,
                            decoration: const InputDecoration(labelText: 'Max Marks'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: passingMarksCtrl,
                            decoration: const InputDecoration(labelText: 'Passing Marks'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (isOral)
                          Expanded(
                            child: TextFormField(
                              controller: oralMarksCtrl,
                              decoration: const InputDecoration(labelText: 'Oral Marks'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        if (isOral && isPractical) const SizedBox(width: 10),
                        if (isPractical)
                          Expanded(
                            child: TextFormField(
                              controller: practicalMarksCtrl,
                              decoration:
                                  const InputDecoration(labelText: 'Practical Marks'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Course Content',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: numModulesCtrl,
                            decoration: const InputDecoration(labelText: 'No. of Modules'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: numExperimentsCtrl,
                            decoration: const InputDecoration(labelText: 'No. of Experiments'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: numAssignmentsCtrl,
                            decoration: const InputDecoration(labelText: 'No. of Assignments'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: theoryCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Theory Topics',
                          hintText: 'Briefly describe theory modules'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: experimentsCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Experiments',
                          hintText: 'Briefly describe lab experiments'),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final data = {
                  'subjectName': nameCtrl.text.trim(),
                  'subjectCode': codeCtrl.text.trim(),
                  'semester': semValue,
                  'weeklyHours': int.parse(weeklyHoursCtrl.text.trim()),
                  // Keep backward compatibility with existing backend contracts.
                  'totalCredits': int.parse(weeklyHoursCtrl.text.trim()),
                  if (semesterHoursCtrl.text.trim().isNotEmpty)
                    'semesterHours': int.tryParse(semesterHoursCtrl.text.trim()),
                  'isPractical': isPractical ? 1 : 0,
                  'isOral': isOral ? 1 : 0,
                  'branchId': branchId,
                  'acadYear': acadYear,
                  'professorAssign': professorAssign,
                  if (maxMarksCtrl.text.trim().isNotEmpty)
                    'maxMarks': int.tryParse(maxMarksCtrl.text.trim()),
                  if (passingMarksCtrl.text.trim().isNotEmpty)
                    'passingMarks': int.tryParse(passingMarksCtrl.text.trim()),
                  if (oralMarksCtrl.text.trim().isNotEmpty)
                    'oralMarks': int.tryParse(oralMarksCtrl.text.trim()),
                  if (practicalMarksCtrl.text.trim().isNotEmpty)
                    'practicalMarks': int.tryParse(practicalMarksCtrl.text.trim()),
                  if (numModulesCtrl.text.trim().isNotEmpty)
                    'numModules': int.tryParse(numModulesCtrl.text.trim()),
                  if (numExperimentsCtrl.text.trim().isNotEmpty)
                    'numExperiments': int.tryParse(numExperimentsCtrl.text.trim()),
                  if (numAssignmentsCtrl.text.trim().isNotEmpty)
                    'numAssignments': int.tryParse(numAssignmentsCtrl.text.trim()),
                  if (theoryCtrl.text.trim().isNotEmpty)
                    'theory': theoryCtrl.text.trim(),
                  if (experimentsCtrl.text.trim().isNotEmpty)
                    'experiments': experimentsCtrl.text.trim(),
                  // Send batch-wise professor assignments for lab subjects
                  if (isPractical) ...[
                    'batchProfessors': {
                      for (final entry in batchProfessors.entries)
                        if (entry.value != null) entry.key: entry.value,
                    },
                  ],
                };
                Navigator.pop(ctx);
                bool success;
                if (existing == null) {
                  success = await ref
                      .read(subjectProvider.notifier)
                      .createSubject(data);
                } else {
                  success = await ref
                      .read(subjectProvider.notifier)
                      .updateSubject(existing.id, data);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success
                        ? existing == null
                            ? 'Subject added'
                            : 'Subject updated'
                        : 'Operation failed'),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                  ));
                }
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, SubjectModel subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
            'Remove "${subject.subjectName}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(subjectProvider.notifier)
          .deleteSubject(subject.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? '${subject.subjectName} removed'
              : 'Failed to delete'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ));
      }
    }
  }
}

// ─── Semester filter chip pop-up ───────────────────────────────────────────

class _SemesterFilterChip extends StatelessWidget {
  final int? selected;
  final ValueChanged<int?> onChanged;

  const _SemesterFilterChip(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<int?>(
          context: context,
          builder: (ctx) => _SemesterPicker(current: selected),
        );
        onChanged(result);
      },
      child: Chip(
        label: Text(selected == null ? 'All Sem' : 'Sem $selected'),
        avatar: const Icon(Icons.filter_list, size: 16),
        deleteIcon: selected != null ? const Icon(Icons.close, size: 16) : null,
        onDeleted: selected != null ? () => onChanged(null) : null,
      ),
    );
  }
}

class _SemesterPicker extends StatelessWidget {
  final int? current;

  const _SemesterPicker({this.current});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Filter by Semester',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              title: const Text('All Semesters'),
              leading: Radio<int?>(
                  value: null,
                  groupValue: current,
                  onChanged: (v) => Navigator.pop(context, v)),
            ),
            ...List.generate(
              8,
              (i) => ListTile(
                title: Text('Semester ${i + 1}'),
                leading: Radio<int?>(
                    value: i + 1,
                    groupValue: current,
                    onChanged: (v) => Navigator.pop(context, v)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Subject card ───────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectCard({
    required this.subject,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: subject.isLabSubject
                ? AppColors.labBackground
                : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            subject.isLabSubject
                ? Icons.science_outlined
                : Icons.menu_book_outlined,
            color: subject.isLabSubject
                ? AppColors.labText
                : AppColors.primary,
          ),
        ),
        title: Text(
          subject.subjectName,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              subject.subjectCode,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _TagChip(
                    label: 'Sem ${subject.semester}',
                    color: AppColors.info),
                const SizedBox(width: 4),
                _TagChip(
                label:
                  '${subject.weeklyHours ?? subject.totalCredits} hr/wk',
                    color: AppColors.secondary),
              if (subject.semesterHours != null) ...[
                const SizedBox(width: 4),
                _TagChip(
                  label: '${subject.semesterHours} hr/sem',
                  color: AppColors.warning),
              ],
                if (subject.isLabSubject) ...[
                  const SizedBox(width: 4),
                  _TagChip(
                      label: 'Lab', color: AppColors.labText),
                ],
              ],
            ),
            if (subject.professorAssign != null &&
                subject.professorAssign!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outlined,
                      size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Prof: ${subject.professorAssign}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete',
                  style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
