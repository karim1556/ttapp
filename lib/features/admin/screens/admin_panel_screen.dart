import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../navigation/app_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/faculty_provider.dart';
import '../../../providers/subject_provider.dart';
import '../../../providers/timetable_provider.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/loading_overlay_widget.dart';

// Internal state for generation form
final _selectedBranchProvider = StateProvider<int?>((ref) => null);
final _selectedSemesterProvider = StateProvider<int?>((ref) => null);
final _selectedDivisionProvider = StateProvider<String?>((ref) => null);

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(facultyProvider.notifier).loadFaculty();
      ref.read(subjectProvider.notifier).loadSubjects();
      ref.read(timetableProvider.notifier).loadWeeklyTimetable();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final timetableState = ref.watch(timetableProvider);
    final facultyState = ref.watch(facultyProvider);
    final subjectState = ref.watch(subjectProvider);
    final isGenerating = timetableState.isGenerating;

    // Redirect non-admins
    if (user != null && !user.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access Denied')),
      );
    }

    return LoadingOverlayWidget(
      isLoading: isGenerating,
      message: 'Generating timetable...\nThis may take a moment.',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats row
            _StatsRow(
              teacherCount: facultyState.faculty.length,
              subjectCount: subjectState.subjects.length,
              timetableCount: timetableState.weeklyTimetable.length,
            ),
            const SizedBox(height: 20),

            // Generate Timetable section
            Text(
              'Timetable Generation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _GenerateTimetableCard(
              onGenerate: _handleGenerate,
            ),

            const SizedBox(height: 24),

            // Management section
            Text(
              'Management',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            _AdminActionCard(
              icon: Icons.people_outlined,
              title: 'Manage Teachers',
              subtitle: '${facultyState.faculty.length} teachers registered',
              color: AppColors.primary,
              onTap: () => context.push(AppRoutes.manageTeachers),
            ),
            const SizedBox(height: 10),
            _AdminActionCard(
              icon: Icons.book_outlined,
              title: 'Manage Subjects',
              subtitle: '${subjectState.subjects.length} subjects configured',
              color: AppColors.secondary,
              onTap: () => context.push(AppRoutes.manageSubjects),
            ),
            const SizedBox(height: 10),
            _AdminActionCard(
              icon: Icons.grid_view_rounded,
              title: 'View Timetable',
              subtitle: 'View generated weekly timetable',
              color: AppColors.success,
              onTap: () => context.go(AppRoutes.timetable),
            ),
            const SizedBox(height: 10),
            _AdminActionCard(
              icon: Icons.school_outlined,
              title: 'COPO Management',
              subtitle: 'Map courses to outcomes & enroll users',
              color: AppColors.warning,
              onTap: () => context.push(AppRoutes.copo),
            ),
            const SizedBox(height: 10),
            _AdminActionCard(
              icon: Icons.meeting_room_outlined,
              title: 'Manage Rooms',
              subtitle: 'Classrooms, labs and their capacities',
              color: Colors.teal,
              onTap: () => context.push(AppRoutes.manageRooms),
            ),
            const SizedBox(height: 10),
            _AdminActionCard(
              icon: Icons.schedule_outlined,
              title: 'Configure Time Slots',
              subtitle: 'Custom periods and break slots',
              color: Colors.deepPurple,
              onTap: () => context.push(AppRoutes.manageTimeslots),
            ),

            const SizedBox(height: 24),

            // Generation result message
            if (timetableState.generateMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: timetableState.generateMessage!.contains('failed') ||
                          timetableState.generateMessage!.contains('Error')
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: timetableState.generateMessage!.contains('failed') ||
                            timetableState.generateMessage!.contains('Error')
                        ? AppColors.error.withOpacity(0.4)
                        : AppColors.success.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      timetableState.generateMessage!.contains('failed') ||
                              timetableState.generateMessage!.contains('Error')
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: timetableState.generateMessage!.contains('failed') ||
                              timetableState.generateMessage!.contains('Error')
                          ? AppColors.error
                          : AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(timetableState.generateMessage!),
                    ),
                  ],
                ),
              ),

            // Teacher Workload Report
            if (timetableState.weeklyTimetable.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                'Teacher Workload Report',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Lectures assigned this week',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _WorkloadSection(
                workload: _computeWorkload(timetableState.weeklyTimetable),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Counts lectures per faculty from the loaded weekly timetable.
  Map<String, int> _computeWorkload(List<dynamic> week) {
    final counts = <String, int>{};
    for (final day in week) {
      for (final slot in day.slots) {
        for (final lecture in slot.lectures) {
          if (lecture.facultyName != null) {
            counts[lecture.facultyName as String] =
                (counts[lecture.facultyName as String] ?? 0) + 1;
          }
        }
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  Future<void> _handleGenerate({
    required int branchId,
    required int semester,
    required String division,
    required String academicYear,
  }) async {
    await ref.read(timetableProvider.notifier).generateTimetable(
          branchId: branchId,
          semester: semester,
          division: division,
          academicYear: academicYear,
        );
  }
}

class _StatsRow extends StatelessWidget {
  final int teacherCount;
  final int subjectCount;
  final int timetableCount;

  const _StatsRow({
    required this.teacherCount,
    required this.subjectCount,
    required this.timetableCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          label: 'Teachers',
          value: teacherCount.toString(),
          icon: Icons.person_outlined,
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Subjects',
          value: subjectCount.toString(),
          icon: Icons.book_outlined,
          color: AppColors.secondary,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Days Set',
          value: timetableCount.toString(),
          icon: Icons.grid_view_outlined,
          color: AppColors.success,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenerateTimetableCard extends StatefulWidget {
  final Future<void> Function({
    required int branchId,
    required int semester,
    required String division,
    required String academicYear,
  }) onGenerate;

  const _GenerateTimetableCard({required this.onGenerate});

  @override
  State<_GenerateTimetableCard> createState() => _GenerateTimetableCardState();
}

class _GenerateTimetableCardState extends State<_GenerateTimetableCard> {
  int _branchId = 1;
  int _semester = 5;
  String _division = 'A';
  String _academicYear = '2024-25';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_outlined,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generate Timetable',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'AI-powered conflict-free scheduling',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Parameters
            Row(
              children: [
                Expanded(
                  child: _DropdownField<int>(
                    label: 'Branch',
                    value: _branchId,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('CS')),
                      DropdownMenuItem(value: 2, child: Text('IT')),
                      DropdownMenuItem(value: 3, child: Text('EXTC')),
                      DropdownMenuItem(value: 4, child: Text('Mech')),
                    ],
                    onChanged: (v) => setState(() => _branchId = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DropdownField<int>(
                    label: 'Semester',
                    value: _semester,
                    items: List.generate(
                      8,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('Sem ${i + 1}'),
                      ),
                    ),
                    onChanged: (v) => setState(() => _semester = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DropdownField<String>(
                    label: 'Division',
                    value: _division,
                    items: const [
                      DropdownMenuItem(value: 'A', child: Text('Division A')),
                      DropdownMenuItem(value: 'B', child: Text('Division B')),
                      DropdownMenuItem(value: 'C', child: Text('Division C')),
                    ],
                    onChanged: (v) => setState(() => _division = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DropdownField<String>(
                    label: 'Academic Year',
                    value: _academicYear,
                    items: const [
                      DropdownMenuItem(value: '2024-25', child: Text('2024-25')),
                      DropdownMenuItem(value: '2025-26', child: Text('2025-26')),
                    ],
                    onChanged: (v) => setState(() => _academicYear = v!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text(
                  'Generate Timetable',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () => widget.onGenerate(
                  branchId: _branchId,
                  semester: _semester,
                  division: _division,
                  academicYear: _academicYear,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Teacher Workload Section ─────────────────────────────────────────────────
class _WorkloadSection extends StatelessWidget {
  final Map<String, int> workload;

  const _WorkloadSection({required this.workload});

  @override
  Widget build(BuildContext context) {
    if (workload.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No lecture assignments found.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final maxCount = workload.values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: workload.entries.map((entry) {
        final fraction = maxCount > 0 ? entry.value / maxCount : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  entry.key,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 10,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${entry.value} lec',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
