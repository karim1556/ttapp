import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../navigation/app_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/holiday_provider.dart';
import '../../../providers/timetable_provider.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/loading_overlay_widget.dart';
import '../../../widgets/lecture_card_widget.dart';
import '../../timetable/widgets/lecture_detail_sheet.dart';
import '../../timetable/utils/slot_grouping.dart';
import '../../../models/time_slot_model.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final user = ref.read(currentUserProvider);
    final isFaculty = user?.isFaculty ?? false;

    if (isFaculty && user != null) {
      ref.read(timetableProvider.notifier).loadFacultyTimetable(user.uid);
    } else {
      ref.read(timetableProvider.notifier).loadWeeklyTimetable();
    }
    ref.read(holidayProvider.notifier).loadHolidays();
  }

  @override
  Widget build(BuildContext context) {
    final timetableState = ref.watch(timetableProvider);
    final holidayState = ref.watch(holidayProvider);
    final isAdmin = ref.watch(isAdminProvider);

    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);
    final dateFormatted = DateFormat('d MMMM yyyy').format(now);
    final todayHoliday = holidayState.todayHoliday;
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    final todayDay = timetableState.weeklyTimetable
        .where((d) => d.dayName.toLowerCase() == dayName.toLowerCase())
        .firstOrNull;

    final visibleSlots = todayDay == null
        ? const <TimeSlotModel>[]
        : collapseConsecutiveLabSlots(todayDay.slots);

    final isLoading =
        timetableState.status == TimetableStatus.loading &&
        timetableState.weeklyTimetable.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Today' : 'My Day'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading
          ? const FullScreenLoader(message: 'Loading schedule...')
          : RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date header
                  _TodayHeader(
                    dayName: dayName,
                    date: dateFormatted,
                    lectureCount: visibleSlots
                        .where((s) => s.lectures.isNotEmpty)
                        .length,
                  ),
                  const SizedBox(height: 16),

                  // Weekend or holiday banner
                  if (isWeekend) ...[
                    _InfoBanner(
                      icon: Icons.weekend_outlined,
                      message: 'It\'s the weekend — no lectures!',
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 16),
                  ] else if (todayHoliday != null) ...[
                    _InfoBanner(
                      icon: Icons.celebration_outlined,
                      message: 'Holiday: ${todayHoliday.name}',
                      subtitle: 'No lectures today',
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                  ] else if (isAdmin) ...[
                    // Admin should use Timetable screen instead
                    EmptyStateWidget(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Admin View',
                      subtitle:
                          'Use the Timetable screen to view all class timetables with year, branch, and division details.',
                    ),
                  ] else if (visibleSlots.isEmpty) ...[
                    EmptyStateWidget(
                      icon: Icons.event_busy_outlined,
                      title: 'No schedule for today',
                      subtitle:
                          'Timetable for $dayName hasn\'t been set up yet.',
                    ),
                  ] else ...[
                    Text(
                      'Schedule — $dayName',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...visibleSlots.map(
                      (slot) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: LectureCardWidget(
                          slot: slot,
                          onTap: slot.lectures.isNotEmpty
                              ? () => _showDetail(context, slot)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  void _showDetail(BuildContext context, TimeSlotModel slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LectureDetailSheet(slot: slot),
    );
  }
}

class _TodayHeader extends StatelessWidget {
  final String dayName;
  final String date;
  final int lectureCount;

  const _TodayHeader({
    required this.dayName,
    required this.date,
    required this.lectureCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5E87F7), Color(0xFF79A1FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.today_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  date,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$lectureCount slot${lectureCount == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final Color color;

  const _InfoBanner({
    required this.icon,
    required this.message,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
