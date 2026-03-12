import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/holiday_model.dart';
import '../../../providers/holiday_provider.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/loading_overlay_widget.dart';

class HolidaysScreen extends ConsumerStatefulWidget {
  const HolidaysScreen({super.key});

  @override
  ConsumerState<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends ConsumerState<HolidaysScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const _tabs = ['Upcoming', 'All'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(holidayProvider.notifier).loadHolidays();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final holidayState = ref.watch(holidayProvider);
    final isLoading = holidayState.status == HolidayStatus.loading &&
        holidayState.holidays.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Holidays'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () =>
                ref.read(holidayProvider.notifier).loadHolidays(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: isLoading
          ? const FullScreenLoader(message: 'Loading holidays...')
          : holidayState.status == HolidayStatus.error &&
                  holidayState.holidays.isEmpty
              ? ErrorStateWidget(
                  message: holidayState.errorMessage,
                  onRetry: () =>
                      ref.read(holidayProvider.notifier).loadHolidays(),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _HolidayList(
                      holidays: holidayState.upcomingHolidays,
                      emptyMessage: 'No upcoming holidays',
                    ),
                    _HolidayList(
                      holidays: holidayState.holidays,
                      emptyMessage: 'No holidays found',
                    ),
                  ],
                ),
    );
  }
}

class _HolidayList extends StatelessWidget {
  final List<HolidayModel> holidays;
  final String emptyMessage;

  const _HolidayList({required this.holidays, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (holidays.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.beach_access_outlined,
        title: emptyMessage,
        subtitle: 'Check back later.',
      );
    }

    // Group holidays by month
    final grouped = <String, List<HolidayModel>>{};
    for (final h in holidays) {
      final d = DateTime.tryParse(h.date) ?? DateTime.now();
      final key = DateFormat('MMMM yyyy').format(d);
      grouped.putIfAbsent(key, () => []).add(h);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
            ),
            ...entry.value.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _HolidayCard(holiday: h),
                )),
          ],
        );
      }).toList(),
    );
  }
}

class _HolidayCard extends StatelessWidget {
  final HolidayModel holiday;

  const _HolidayCard({required this.holiday});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(holiday.date) ?? DateTime.now();
    final dayNum = DateFormat('d').format(date);
    final dayName = DateFormat('EEE').format(date);
    final fullDate = DateFormat('d MMM yyyy').format(date);
    final isToday = holiday.isToday;

    Color typeColor;
    switch (holiday.type?.toLowerCase()) {
      case 'national':
        typeColor = AppColors.error;
        break;
      case 'institute':
        typeColor = AppColors.primary;
        break;
      case 'festival':
        typeColor = AppColors.warning;
        break;
      default:
        typeColor = AppColors.secondary;
    }

    return Container(
      decoration: BoxDecoration(
        color: isToday ? AppColors.holidayBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? AppColors.holidayBorder : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date box
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: typeColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayNum,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                Text(
                  dayName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          holiday.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isToday ? AppColors.holidayText : null,
                              ),
                        ),
                      ),
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Today',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fullDate,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (holiday.type != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        holiday.type!,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  if (holiday.description != null &&
                      holiday.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      holiday.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
