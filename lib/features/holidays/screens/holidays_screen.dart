import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

class _HolidaysScreenState extends ConsumerState<HolidaysScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(holidayProvider.notifier).loadHolidays();
    });
  }

  @override
  Widget build(BuildContext context) {
    final holidayState = ref.watch(holidayProvider);
    final isLoading =
        holidayState.status == HolidayStatus.loading &&
        holidayState.holidays.isEmpty;

    final holidays = _selectedTab == 0
        ? holidayState.upcomingHolidays
        : holidayState.holidays;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Holiday Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.read(holidayProvider.notifier).loadHolidays(),
          ),
        ],
      ),
      body: isLoading
          ? const FullScreenLoader(message: 'Loading holidays...')
          : holidayState.status == HolidayStatus.error &&
                holidayState.holidays.isEmpty
          ? ErrorStateWidget(
              message: holidayState.errorMessage,
              onRetry: () => ref.read(holidayProvider.notifier).loadHolidays(),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                _HolidayHeaderCard(
                  count: holidays.length,
                  selectedTab: _selectedTab,
                ),
                const SizedBox(height: 12),
                _SegmentedSelector(
                  selectedTab: _selectedTab,
                  onChanged: (tab) => setState(() => _selectedTab = tab),
                ),
                const SizedBox(height: 12),
                _HolidayList(
                  holidays: holidays,
                  emptyMessage: _selectedTab == 0
                      ? 'No upcoming holidays'
                      : 'No holidays found',
                ),
              ],
            ),
    );
  }
}

class _HolidayHeaderCard extends StatelessWidget {
  final int count;
  final int selectedTab;

  const _HolidayHeaderCard({required this.count, required this.selectedTab});

  @override
  Widget build(BuildContext context) {
    final title = selectedTab == 0 ? 'Upcoming Holidays' : 'All Holidays';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5E87F7), Color(0xFF79A1FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.celebration_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count holiday entries',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedSelector extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onChanged;

  const _SegmentedSelector({
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _SegmentButton(
            selected: selectedTab == 0,
            label: 'Upcoming',
            onTap: () => onChanged(0),
          ),
          _SegmentButton(
            selected: selectedTab == 1,
            label: 'All',
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
      return SizedBox(
        height: 320,
        child: EmptyStateWidget(
          icon: Icons.beach_access_outlined,
          title: emptyMessage,
          subtitle: 'Check back later.',
        ),
      );
    }

    final grouped = <String, List<HolidayModel>>{};
    for (final holiday in holidays) {
      final date = DateTime.tryParse(holiday.date) ?? DateTime.now();
      final key = DateFormat('MMMM yyyy').format(date);
      grouped.putIfAbsent(key, () => []).add(holiday);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...entry.value.map(
              (holiday) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _HolidayCard(holiday: holiday),
              ),
            ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: typeColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Text(
                  dayNum,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                Text(dayName, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          holiday.name,
                          style: TextStyle(
                            color: holiday.isToday
                                ? AppColors.holidayText
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (holiday.isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Today',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(fullDate, style: Theme.of(context).textTheme.bodySmall),
                  if (holiday.type != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        holiday.type!,
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                  if (holiday.description != null &&
                      holiday.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      holiday.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
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
