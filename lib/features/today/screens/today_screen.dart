import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/holiday_provider.dart';
import '../../../providers/timetable_provider.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/loading_overlay_widget.dart';
import '../../../widgets/lecture_card_widget.dart';
import '../../timetable/widgets/lecture_detail_sheet.dart';
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
      ref.read(timetableProvider.notifier).loadWeeklyTimetable();
      ref.read(holidayProvider.notifier).loadHolidays();
    });
  }

  @override
  Widget build(BuildContext context) {
    final timetableState = ref.watch(timetableProvider);
    final holidayState = ref.watch(holidayProvider);

    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);
    final dateFormatted = DateFormat('d MMMM yyyy').format(now);
    final todayHoliday = holidayState.todayHoliday;
    final isWeekend = now.weekday == DateTime.saturday ||
        now.weekday == DateTime.sunday;

    final todayDay = timetableState.weeklyTimetable
        .where((d) => d.dayName.toLowerCase() == dayName.toLowerCase())
        .firstOrNull;

    final isLoading = timetableState.status == TimetableStatus.loading &&
        timetableState.weeklyTimetable.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () =>
                ref.read(timetableProvider.notifier).loadWeeklyTimetable(),
          ),
        ],
      ),
      body: isLoading
          ? const FullScreenLoader(message: 'Loading schedule...')
          : RefreshIndicator(
              onRefresh: () async {
                ref.read(timetableProvider.notifier).loadWeeklyTimetable();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date header
                  _TodayHeader(dayName: dayName, date: dateFormatted),
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
                  ] else if (todayDay == null ||
                      todayDay.slots.isEmpty) ...[
                    EmptyStateWidget(
                      icon: Icons.event_busy_outlined,
                      title: 'No schedule for today',
                      subtitle: 'Timetable for $dayName hasn\'t been set up yet.',
                    ),
                  ] else ...[
                    Text(
                      'Schedule — $dayName',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...todayDay.slots.map(
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

  const _TodayHeader({required this.dayName, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.today_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
              Text(
                date,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
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
                    style: TextStyle(color: color.withOpacity(0.7), fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
