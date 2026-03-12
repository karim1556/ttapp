import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/time_slot_model.dart';
import '../../../models/timetable_day_model.dart';
import '../../../navigation/app_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/holiday_provider.dart';
import '../../../providers/timetable_provider.dart';
import '../../../widgets/lecture_card_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    ref.read(timetableProvider.notifier).loadWeeklyTimetable();
    ref.read(holidayProvider.notifier).loadHolidays();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final timetableState = ref.watch(timetableProvider);
    final holidayState = ref.watch(holidayProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final isFaculty = ref.watch(isFacultyProvider);

    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);
    final dateFormatted = DateFormat('d MMMM yyyy').format(now);

    final todayHoliday = holidayState.todayHoliday;

    // Get today's lectures from weekly timetable
    final todayDay = _getTodayFromWeekly(timetableState.weeklyTimetable, dayName);

    // Next upcoming lecture
    final nextLecture = _getNextLecture(todayDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TT Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Greeting card
            _buildGreetingCard(context, user?.email ?? 'User', dayName, dateFormatted),
            const SizedBox(height: 16),

            // Holiday banner
            if (todayHoliday != null) ...[
              _buildHolidayBanner(context, todayHoliday.name),
              const SizedBox(height: 16),
            ],

            // Next lecture card
            if (todayHoliday == null) ...[
              _buildNextLectureCard(context, nextLecture),
              const SizedBox(height: 16),
            ],

            // Quick action cards
            Text(
              'Quick Access',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _QuickActionCard(
                  icon: Icons.grid_view_rounded,
                  label: 'Weekly\nTimetable',
                  color: AppColors.primary,
                  onTap: () => context.go(AppRoutes.timetable),
                ),
                _QuickActionCard(
                  icon: Icons.today_rounded,
                  label: "Today's\nSchedule",
                  color: AppColors.success,
                  onTap: () => context.go(AppRoutes.today),
                ),
                _QuickActionCard(
                  icon: Icons.beach_access_rounded,
                  label: 'Upcoming\nHolidays',
                  color: AppColors.error,
                  onTap: () => isAdmin
                      ? context.go(AppRoutes.adminPanel)
                      : context.go(AppRoutes.holidays),
                ),
                if (isAdmin)
                  _QuickActionCard(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin\nPanel',
                    color: AppColors.warning,
                    onTap: () => context.go(AppRoutes.adminPanel),
                  )
                else if (isFaculty)
                  _QuickActionCard(
                    icon: Icons.tune_rounded,
                    label: 'My\nConstraints',
                    color: AppColors.secondary,
                    onTap: () => context.push(AppRoutes.facultyConstraints),
                  )
                else
                  _QuickActionCard(
                    icon: Icons.beach_access_rounded,
                    label: 'Holidays',
                    color: AppColors.warning,
                    onTap: () => context.go(AppRoutes.holidays),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Today's lectures preview
            if (todayHoliday == null && todayDay != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today — $dayName",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.today),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (todayDay.slots.isEmpty)
                _buildEmptyTodayCard(context)
              else
                ...todayDay.slots.take(3).map(
                      (slot) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: LectureCardWidget(slot: slot),
                      ),
                    ),
            ],

            // Upcoming holidays preview
            if (holidayState.upcomingHolidays.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Holidays',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (!isAdmin)
                    TextButton(
                      onPressed: () => context.go(AppRoutes.holidays),
                      child: const Text('View All'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ...holidayState.upcomingHolidays.take(3).map(
                    (h) => _HolidayChip(holiday: h),
                  ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  TimetableDay? _getTodayFromWeekly(List<TimetableDay> weekly, String dayName) {
    try {
      return weekly.firstWhere(
        (d) => d.dayName.toLowerCase() == dayName.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  TimeSlotModel? _getNextLecture(TimetableDay? todayDay) {
    if (todayDay == null) return null;
    final now = DateTime.now();
    for (final slot in todayDay.slots) {
      final slotTime = DateTime(
        now.year,
        now.month,
        now.day,
        slot.startTimeHr,
        slot.startTimeMinutes,
      );
      if (slotTime.isAfter(now) && slot.lectures.isNotEmpty) {
        return slot;
      }
    }
    return null;
  }

  Widget _buildGreetingCard(
      BuildContext context, String email, String day, String date) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning!'
        : hour < 17
            ? 'Good Afternoon!'
            : 'Good Evening!';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email.split('@').first,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '$day, $date',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.school_rounded,
            color: Colors.white30,
            size: 64,
          ),
        ],
      ),
    );
  }

  Widget _buildHolidayBanner(BuildContext context, String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.holidayBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.holidayBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration_rounded,
              color: AppColors.holidayText, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today is a Holiday',
                  style: TextStyle(
                    color: AppColors.holidayText,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(color: AppColors.holidayText, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextLectureCard(BuildContext context, TimeSlotModel? slot) {
    if (slot == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.breakBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 24),
            const SizedBox(width: 12),
            Text(
              'No more lectures today',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.success),
            ),
          ],
        ),
      );
    }

    final lecture = slot.lectures.isNotEmpty ? slot.lectures.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Next Lecture',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                slot.timeRangeDisplay,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 12),
              if (lecture != null)
                Expanded(
                  child: Text(
                    lecture.subjectName ?? lecture.subjectCode ?? 'Subject',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          if (lecture?.roomNumber != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.room_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Room ${lecture!.roomNumber}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (lecture.facultyName != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.person_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lecture.facultyName!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyTodayCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.breakBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined,
                size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(
              'No lectures scheduled today',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HolidayChip extends StatelessWidget {
  final dynamic holiday;

  const _HolidayChip({required this.holiday});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy').format(
      DateTime.tryParse(holiday.date) ?? DateTime.now(),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.holidayBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.holidayBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.event_outlined,
                color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holiday.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (holiday.type != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                holiday.type,
                style:
                    const TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }
}
