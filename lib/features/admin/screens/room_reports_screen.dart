import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/timetable_day_model.dart';
import '../../../models/time_slot_model.dart';
import '../../../providers/room_provider.dart';
import '../../../services/timetable_service.dart';
import '../../timetable/utils/slot_grouping.dart';
import '../../timetable/widgets/timetable_grid_widget.dart';

class RoomReportsScreen extends ConsumerStatefulWidget {
  const RoomReportsScreen({super.key});

  @override
  ConsumerState<RoomReportsScreen> createState() => _RoomReportsScreenState();
}

class _RoomReportsScreenState extends ConsumerState<RoomReportsScreen> {
  bool _loadingTimetable = false;
  bool _loadingUsage = false;
  String? _selectedRoomNumber;
  String? _errorMessage;

  List<TimetableDay> _roomWeek = const [];
  List<Map<String, dynamic>> _usageRows = const [];

  static const _orderedDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    await ref.read(roomProvider.notifier).loadRooms();

    final rooms = ref.read(roomProvider).rooms.where((r) => r.active).toList();

    if (_selectedRoomNumber == null && rooms.isNotEmpty) {
      _selectedRoomNumber = rooms.first.roomNumber;
    }

    await Future.wait([_loadRoomTimetable(), _loadUsageReport()]);
  }

  Future<void> _loadRoomTimetable() async {
    final room = _selectedRoomNumber;
    if (room == null || room.isEmpty) return;

    setState(() {
      _loadingTimetable = true;
      _errorMessage = null;
    });

    try {
      final data = await ref
          .read(timetableServiceProvider)
          .fetchRoomWeeklyTimetable(room);

      setState(() {
        _roomWeek = data;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingTimetable = false;
        });
      }
    }
  }

  Future<void> _loadUsageReport() async {
    setState(() {
      _loadingUsage = true;
      _errorMessage = null;
    });

    try {
      final rows = await ref
          .read(timetableServiceProvider)
          .fetchClassroomUsageReport();

      setState(() {
        _usageRows = rows;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingUsage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    final activeRooms = roomState.rooms.where((r) => r.active).toList()
      ..sort((a, b) => a.roomNumber.compareTo(b.roomNumber));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Timetable & Usage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _bootstrap,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value:
                        activeRooms.any(
                          (r) => r.roomNumber == _selectedRoomNumber,
                        )
                        ? _selectedRoomNumber
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Select Room',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: activeRooms
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.roomNumber,
                            child: Text(
                              '${r.roomNumber} • ${r.roomType ?? 'Classroom'}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedRoomNumber = value);
                      _loadRoomTimetable();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _loadRoomTimetable,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Load'),
                ),
              ],
            ),
          ),
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.25)),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _SectionCard(
                  title: 'Room Weekly Timetable',
                  subtitle: _selectedRoomNumber == null
                      ? 'Choose a room to view schedule'
                      : 'Schedule for room $_selectedRoomNumber',
                  child: _loadingTimetable
                      ? const _CenteredProgress()
                      : _buildRoomWeekView(),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Classroom Usage Report',
                  subtitle: 'Lectures assigned per room this week',
                  child: _loadingUsage
                      ? const _CenteredProgress()
                      : _buildUsageView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomWeekView() {
    if (_selectedRoomNumber == null || _selectedRoomNumber!.isEmpty) {
      return const Text('No room selected.');
    }

    if (_roomWeek.isEmpty) {
      return const Text(
        'No timetable data found for this room.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    final byDay = <String, TimetableDay>{
      for (final day in _roomWeek) day.dayName: day,
    };

    return Column(
      children: _orderedDays.map((dayName) {
        final day = byDay[dayName];
        final slots = day == null
            ? <TimeSlotModel>[]
            : collapseConsecutiveLabSlots(
                day.slots,
              ).where((s) => s.lectures.isNotEmpty).toList();

        return ExpansionTile(
          title: Text(dayName),
          subtitle: Text(
            slots.isEmpty
                ? 'No lectures'
                : '${slots.length} lecture${slots.length == 1 ? '' : 's'}',
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          initiallyExpanded: dayName == 'Monday',
          children: [
            if (slots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No lectures scheduled.'),
              )
            else
              ...slots.asMap().entries.map((entry) {
                final i = entry.key;
                final slot = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TimetableGridWidget(
                    slot: slot,
                    color: AppColors
                        .subjectColors[i % AppColors.subjectColors.length],
                  ),
                );
              }),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildUsageView() {
    if (_usageRows.isEmpty) {
      return const Text(
        'No classroom usage data available.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    final sorted = [..._usageRows]
      ..sort(
        (a, b) => ((b['assignedLectures'] as num?) ?? 0).compareTo(
          (a['assignedLectures'] as num?) ?? 0,
        ),
      );

    final maxLectures = sorted.fold<int>(
      0,
      (prev, row) => ((row['assignedLectures'] as num?)?.toInt() ?? 0) > prev
          ? ((row['assignedLectures'] as num?)?.toInt() ?? 0)
          : prev,
    );

    return Column(
      children: sorted.map((row) {
        final room = (row['roomNumber'] ?? '').toString();
        final type = (row['roomType'] ?? '').toString();
        final lectures = (row['assignedLectures'] as num?)?.toInt() ?? 0;
        final utilization =
            (row['utilizationPercent'] as num?)?.toDouble() ?? 0;
        final ratio = maxLectures > 0 ? lectures / maxLectures : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (type.isNotEmpty)
                      Text(
                        type,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 94,
                child: Text(
                  '$lectures lec | ${utilization.toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _CenteredProgress extends StatelessWidget {
  const _CenteredProgress();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
