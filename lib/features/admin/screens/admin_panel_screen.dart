import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../navigation/app_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/faculty_provider.dart';
import '../../../providers/subject_provider.dart';
import '../../../providers/timetable_provider.dart';
import '../../../widgets/loading_overlay_widget.dart';

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
      return const Scaffold(body: Center(child: Text('Access Denied')));
    }

    return LoadingOverlayWidget(
      isLoading: isGenerating,
      message: 'Generating timetable...\nThis may take a moment.',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Workspace'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () {
                ref.read(facultyProvider.notifier).loadFaculty();
                ref.read(subjectProvider.notifier).loadSubjects();
                ref.read(timetableProvider.notifier).loadWeeklyTimetable();
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AdminHeroCard(
              adminName: (user?.email ?? 'admin').split('@').first,
              teacherCount: facultyState.faculty.length,
              subjectCount: subjectState.subjects.length,
            ),
            const SizedBox(height: 14),
            _StatsRow(
              teacherCount: facultyState.faculty.length,
              subjectCount: subjectState.subjects.length,
              timetableCount: timetableState.weeklyTimetable.length,
            ),
            const SizedBox(height: 24),

            const _SectionTitle(
              title: 'Timetable Generation',
              subtitle:
                  'Generate even/odd term schedules for A and B divisions',
            ),
            const SizedBox(height: 10),
            _GenerateTimetableCard(onGenerateAll: _handleGenerateAll),

            const SizedBox(height: 24),

            const _SectionTitle(
              title: 'Management',
              subtitle: 'Configure faculty, subjects, rooms and reports',
            ),
            const SizedBox(height: 10),

            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.16,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _AdminActionTile(
                  icon: Icons.people_outlined,
                  title: 'Teachers',
                  subtitle: '${facultyState.faculty.length} registered',
                  color: AppColors.primary,
                  onTap: () => context.push(AppRoutes.manageTeachers),
                ),
                _AdminActionTile(
                  icon: Icons.book_outlined,
                  title: 'Subjects',
                  subtitle: '${subjectState.subjects.length} configured',
                  color: AppColors.secondary,
                  onTap: () => context.push(AppRoutes.manageSubjects),
                ),
                _AdminActionTile(
                  icon: Icons.grid_view_rounded,
                  title: 'Timetable',
                  subtitle: 'Weekly view',
                  color: AppColors.success,
                  onTap: () => context.go(AppRoutes.timetable),
                ),
                _AdminActionTile(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Substitutions',
                  subtitle: 'Day-only replacements',
                  color: AppColors.info,
                  onTap: () => context.push(AppRoutes.substitutions),
                ),
                _AdminActionTile(
                  icon: Icons.school_outlined,
                  title: 'COPO',
                  subtitle: 'Outcome mapping',
                  color: AppColors.warning,
                  onTap: () => context.push(AppRoutes.copo),
                ),
                _AdminActionTile(
                  icon: Icons.meeting_room_outlined,
                  title: 'Rooms',
                  subtitle: 'Labs & classes',
                  color: Colors.teal,
                  onTap: () => context.push(AppRoutes.manageRooms),
                ),
                _AdminActionTile(
                  icon: Icons.domain_verification_outlined,
                  title: 'Room Reports',
                  subtitle: 'Usage insights',
                  color: Colors.blueGrey,
                  onTap: () => context.push(AppRoutes.roomReports),
                ),
                _AdminActionTile(
                  icon: Icons.schedule_outlined,
                  title: 'Time Slots',
                  subtitle: 'Periods & breaks',
                  color: const Color(0xFF6D4DF2),
                  onTap: () => context.push(AppRoutes.manageTimeslots),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Generation result message
            if (timetableState.generateMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      timetableState.generateMessage!.contains('failed') ||
                          timetableState.generateMessage!.contains('Error')
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        timetableState.generateMessage!.contains('failed') ||
                            timetableState.generateMessage!.contains('Error')
                        ? AppColors.error.withValues(alpha: 0.4)
                        : AppColors.success.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      timetableState.generateMessage!.contains('failed') ||
                              timetableState.generateMessage!.contains('Error')
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color:
                          timetableState.generateMessage!.contains('failed') ||
                              timetableState.generateMessage!.contains('Error')
                          ? AppColors.error
                          : AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(timetableState.generateMessage!)),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: _WorkloadSection(
                    workload: _computeWorkload(timetableState.weeklyTimetable),
                  ),
                ),
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

  Future<void> _handleGenerateAll({
    required String academicYear,
    required int branchId,
    required String termType,
  }) async {
    await ref
        .read(timetableProvider.notifier)
        .generateAllTimetables(
          academicYear: academicYear,
          branchIds: [branchId],
          divisions: const ['A', 'B'],
          termType: termType,
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

class _AdminHeroCard extends StatelessWidget {
  final String adminName;
  final int teacherCount;
  final int subjectCount;

  const _AdminHeroCard({
    required this.adminName,
    required this.teacherCount,
    required this.subjectCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5E87F7), Color(0xFF7EA4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Control Center',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hi ${adminName[0].toUpperCase()}${adminName.substring(1)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$teacherCount teachers, $subjectCount subjects ready for scheduling',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
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

class _AdminActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
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
    required String academicYear,
    required int branchId,
    required String termType,
  })
  onGenerateAll;

  const _GenerateTimetableCard({required this.onGenerateAll});

  @override
  State<_GenerateTimetableCard> createState() => _GenerateTimetableCardState();
}

class _GenerateTimetableCardState extends State<_GenerateTimetableCard> {
  int _branchId = 1;
  String _termType = 'even';
  String _academicYear = '2024-25';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5E87F7), Color(0xFF79A1FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: Colors.white,
                ),
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
                      'Smart conflict-free scheduling',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.divider.withValues(alpha: 0.9)),
          const SizedBox(height: 12),
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
                child: _DropdownField<String>(
                  label: 'Term',
                  value: _termType,
                  items: const [
                    DropdownMenuItem(
                      value: 'even',
                      child: Text('Even (2,4,6,8)'),
                    ),
                    DropdownMenuItem(
                      value: 'odd',
                      child: Text('Odd (1,3,5,7)'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _termType = v ?? 'even'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Divisions'),
                  child: const Text('A and B (fixed)'),
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
              label: Text(
                _termType == 'even'
                    ? 'Generate Even Semesters (A+B)'
                    : 'Generate Odd Semesters (A+B)',
                style: const TextStyle(fontSize: 16),
              ),
              onPressed: () => widget.onGenerateAll(
                academicYear: _academicYear,
                branchId: _branchId,
                termType: _termType,
              ),
            ),
          ),
        ],
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
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
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
        child: Text(
          'No lecture assignments found.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 10,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${entry.value} lec',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
