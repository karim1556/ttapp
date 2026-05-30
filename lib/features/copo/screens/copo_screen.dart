import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/copo_model.dart';
import '../../../models/subject_model.dart';
import '../../../providers/copo_provider.dart';
import '../../../providers/subject_provider.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/loading_overlay_widget.dart';
import '../../../core/utils/academic_year.dart';

class CopoScreen extends ConsumerStatefulWidget {
  const CopoScreen({super.key});

  @override
  ConsumerState<CopoScreen> createState() => _CopoScreenState();
}

class _CopoScreenState extends ConsumerState<CopoScreen> {
  int? _filterBranch;
  int? _filterSemester;
  late String _filterYear;

  @override
  void initState() {
    super.initState();
    _filterYear = currentAcademicYear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(copoProvider.notifier).load(academicYear: _filterYear);
      ref.read(subjectProvider.notifier).loadSubjects();
    });
  }

  void _applyFilters() {
    ref.read(copoProvider.notifier).load(
          branch: _filterBranch,
          semester: _filterSemester,
          academicYear: _filterYear,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(copoProvider);
    final isLoading =
        state.status == CopoStatus.loading && state.courses.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('COPO Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _applyFilters,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Course Mapping'),
      ),
      body: Column(
        children: [
          _FilterBar(
            filterBranch: _filterBranch,
            filterSemester: _filterSemester,
            filterYear: _filterYear,
            onChanged: ({branch, semester, year}) {
              setState(() {
                if (branch != null || branch == null && _filterBranch != null) {
                  _filterBranch = branch;
                }
                if (semester != null ||
                    semester == null && _filterSemester != null) {
                  _filterSemester = semester;
                }
                if (year != null) _filterYear = year;
              });
              _applyFilters();
            },
          ),

          Expanded(
            child: isLoading
                ? const FullScreenLoader(message: 'Loading COPO data...')
                : state.courses.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.school_outlined,
                        title: 'No course mappings found',
                        subtitle: state.status == CopoStatus.error
                            ? (state.errorMessage ?? 'An error occurred')
                            : 'Add a course mapping using the + button',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: state.courses.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) => _CopoCard(
                          course: state.courses[i],
                          onEdit: () =>
                              _showFormDialog(context, state.courses[i]),
                          onDelete: () =>
                              _confirmDelete(context, state.courses[i]),
                          onManageUsers: () =>
                              _showEnrollmentsSheet(context, state.courses[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Add / Edit dialog ─────────────────────────────────────────────────────

  void _showFormDialog(BuildContext context, CopoUserCourseModel? existing) {
    final subjects = ref.read(subjectProvider).subjects;
    final formKey = GlobalKey<FormState>();

    int? courseId = existing?.courseId;
    int? semester = existing?.semester;
    int branchId = existing?.branch ?? 1;
    String academicYear = existing?.academicYear ?? currentAcademicYear();
    int coCount = existing?.coCount ?? 2;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null
              ? 'Add Course Mapping'
              : 'Edit Course Mapping'),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subject
                    DropdownButtonFormField<int>(
                      value: courseId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Subject *'),
                      validator: (v) => v == null ? 'Required' : null,
                      items: subjects
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  '${s.subjectCode} — ${s.subjectName}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setS(() => courseId = v),
                    ),
                    const SizedBox(height: 10),

                    // Semester
                    DropdownButtonFormField<int>(
                      value: semester,
                      decoration: const InputDecoration(labelText: 'Semester'),
                      items: List.generate(
                        8,
                        (i) => DropdownMenuItem(
                            value: i + 1, child: Text('Sem ${i + 1}')),
                      ),
                      onChanged: (v) => setS(() => semester = v),
                    ),
                    const SizedBox(height: 10),

                    // Branch
                    DropdownButtonFormField<int>(
                      value: branchId,
                      decoration: const InputDecoration(labelText: 'Branch'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('CS')),
                        DropdownMenuItem(value: 2, child: Text('IT')),
                        DropdownMenuItem(value: 3, child: Text('EXTC')),
                        DropdownMenuItem(value: 4, child: Text('Mech')),
                      ],
                      onChanged: (v) => setS(() => branchId = v ?? 1),
                    ),
                    const SizedBox(height: 10),

                    // Academic year
                    DropdownButtonFormField<String>(
                      value: academicYear,
                      decoration:
                          const InputDecoration(labelText: 'Academic Year'),
                      items: academicYearOptions()
                          .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setS(() => academicYear = v);
                      },
                    ),
                    const SizedBox(height: 10),

                    // CO count
                    Row(
                      children: [
                        const Text('Number of Course Outcomes (COs):'),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: coCount > 1
                              ? () => setS(() => coCount--)
                              : null,
                        ),
                        Text(
                          '$coCount',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: coCount < 12
                              ? () => setS(() => coCount++)
                              : null,
                        ),
                      ],
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
                  'course_id':     courseId,
                  'semester':      semester,
                  'branch':        branchId,
                  'academic_year': academicYear,
                  'co_count':      coCount,
                };
                Navigator.pop(ctx);
                bool ok;
                if (existing == null) {
                  ok = await ref.read(copoProvider.notifier).create(data);
                } else {
                  ok = await ref
                      .read(copoProvider.notifier)
                      .update(existing.usercourseId, data);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok
                        ? existing == null
                            ? 'Course mapping created'
                            : 'Course mapping updated'
                        : 'Operation failed'),
                    backgroundColor: ok ? AppColors.success : AppColors.error,
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

  // ── Delete confirm ────────────────────────────────────────────────────────

  Future<void> _confirmDelete(
      BuildContext context, CopoUserCourseModel course) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course Mapping'),
        content: Text(
          'Remove "${course.subjectName ?? 'this course'}" mapping for '
          'Sem ${course.semester}, ${course.branchLabel}? '
          'All enrolled users will be removed.',
        ),
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

    if (ok == true) {
      final success = await ref
          .read(copoProvider.notifier)
          .delete(course.usercourseId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Deleted' : 'Delete failed'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ));
      }
    }
  }

  // ── Enrollments bottom sheet ──────────────────────────────────────────────

  void _showEnrollmentsSheet(
      BuildContext context, CopoUserCourseModel course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EnrollmentsSheet(course: course),
    );
  }
}

// ── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final int? filterBranch;
  final int? filterSemester;
  final String filterYear;
  final void Function({int? branch, int? semester, String? year}) onChanged;

  const _FilterBar({
    required this.filterBranch,
    required this.filterSemester,
    required this.filterYear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Branch filter
            _chip<int>(
              label: filterBranch != null
                  ? _branchName(filterBranch!)
                  : 'All Branches',
              active: filterBranch != null,
              onTap: () => _pickBranch(context),
            ),
            const SizedBox(width: 8),

            // Semester filter
            _chip<int>(
              label: filterSemester != null
                  ? 'Sem $filterSemester'
                  : 'All Sems',
              active: filterSemester != null,
              onTap: () => _pickSemester(context),
            ),
            const SizedBox(width: 8),

            // Year filter
            _chip<String>(
              label: filterYear,
              active: true,
              onTap: () => _pickYear(context),
            ),

            if (filterBranch != null || filterSemester != null) ...[
              const SizedBox(width: 8),
              ActionChip(
                label: const Text('Clear'),
                onPressed: () =>
                    onChanged(branch: null, semester: null, year: filterYear),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip<T>({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryLight,
      checkmarkColor: AppColors.primary,
    );
  }

  void _pickBranch(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Filter by Branch'),
        children: [
          SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                onChanged(branch: null);
              },
              child: const Text('All Branches')),
          for (final entry in {1: 'CS', 2: 'IT', 3: 'EXTC', 4: 'Mech'}
              .entries)
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                onChanged(branch: entry.key);
              },
              child: Text(entry.value),
            ),
        ],
      ),
    );
  }

  void _pickSemester(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Filter by Semester'),
        children: [
          SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                onChanged(semester: null);
              },
              child: const Text('All Semesters')),
          for (int s = 1; s <= 8; s++)
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                onChanged(semester: s);
              },
              child: Text('Semester $s'),
            ),
        ],
      ),
    );
  }

  void _pickYear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Academic Year'),
        children: [
          for (final y in academicYearOptions())
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                onChanged(year: y);
              },
              child: Text(y),
            ),
        ],
      ),
    );
  }

  static String _branchName(int id) {
    switch (id) {
      case 1: return 'CS';
      case 2: return 'IT';
      case 3: return 'EXTC';
      case 4: return 'Mech';
      default: return 'Branch $id';
    }
  }
}

// ── COPO Card ─────────────────────────────────────────────────────────────────

class _CopoCard extends StatelessWidget {
  final CopoUserCourseModel course;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageUsers;

  const _CopoCard({
    required this.course,
    required this.onEdit,
    required this.onDelete,
    required this.onManageUsers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onManageUsers,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.subjectName ?? 'Subject #${course.courseId}',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (course.subjectCode != null)
                          Text(
                            course.subjectCode!,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                      if (v == 'users') onManageUsers();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'users', child: Text('Manage Enrolled Users')),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _tag(
                      Icons.layers_outlined,
                      course.semester != null
                          ? 'Sem ${course.semester}'
                          : '—',
                      AppColors.info),
                  _tag(Icons.account_tree_outlined, course.branchLabel,
                      AppColors.secondary),
                  _tag(Icons.calendar_month_outlined,
                      course.academicYear ?? '—', AppColors.warning),
                  _tag(
                    Icons.format_list_numbered,
                    '${course.coCount ?? 0} CO${(course.coCount ?? 0) == 1 ? '' : 's'}',
                    AppColors.success,
                  ),
                  _tag(
                    Icons.people_outlined,
                    '${course.enrolledCount ?? 0} enrolled',
                    AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Enrollments Bottom Sheet ──────────────────────────────────────────────────

class _EnrollmentsSheet extends ConsumerStatefulWidget {
  final CopoUserCourseModel course;
  const _EnrollmentsSheet({required this.course});

  @override
  ConsumerState<_EnrollmentsSheet> createState() => _EnrollmentsSheetState();
}

class _EnrollmentsSheetState extends ConsumerState<_EnrollmentsSheet> {
  final _uidCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(enrollmentProvider(widget.course.usercourseId).notifier)
          .load();
    });
  }

  @override
  void dispose() {
    _uidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(enrollmentProvider(widget.course.usercourseId));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enrolled Users',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        widget.course.subjectName ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add_outlined),
                  tooltip: 'Add user by UID',
                  onPressed: () => _showAddUserDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: state.loading && state.enrollments.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.enrollments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline,
                                size: 48, color: AppColors.textSecondary),
                            const SizedBox(height: 8),
                            const Text('No users enrolled yet'),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => _showAddUserDialog(context),
                              icon: const Icon(Icons.person_add_outlined),
                              label: const Text('Add User'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: state.enrollments.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final e = state.enrollments[i];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                e.userEmail?.isNotEmpty == true
                                    ? e.userEmail![0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(e.userEmail ?? 'UID ${e.userId}'),
                            subtitle: Text(e.userTypeLabel),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: AppColors.error),
                              onPressed: () => _removeUser(e.userId),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    _uidCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add User(s) by UID'),
        content: TextField(
          controller: _uidCtrl,
          decoration: const InputDecoration(
            labelText: 'User IDs (comma-separated)',
            hintText: 'e.g. 5, 12, 18',
          ),
          keyboardType: TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final raw = _uidCtrl.text.trim();
              final ids = raw
                  .split(',')
                  .map((s) => int.tryParse(s.trim()))
                  .whereType<int>()
                  .toList();
              if (ids.isEmpty) return;
              Navigator.pop(ctx);
              final ok = await ref
                  .read(enrollmentProvider(widget.course.usercourseId)
                      .notifier)
                  .addUsers(ids);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Users enrolled' : 'Failed to enroll'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                ));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeUser(int userId) async {
    final ok = await ref
        .read(
            enrollmentProvider(widget.course.usercourseId).notifier)
        .removeUser(userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'User removed' : 'Failed to remove'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ));
    }
  }
}
