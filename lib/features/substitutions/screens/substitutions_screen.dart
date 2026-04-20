import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/substitution_provider.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/loading_overlay_widget.dart';

class SubstitutionsScreen extends ConsumerStatefulWidget {
  const SubstitutionsScreen({super.key});

  @override
  ConsumerState<SubstitutionsScreen> createState() => _SubstitutionsScreenState();
}

class _SubstitutionsScreenState extends ConsumerState<SubstitutionsScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecords();
    });
  }

  Future<void> _loadRecords() async {
    final user = ref.read(currentUserProvider);
    final isAdmin = user?.isAdmin ?? false;
    final facultyId = isAdmin ? null : user?.uid;
    await ref.read(substitutionProvider.notifier).loadForDate(
      _selectedDate,
      facultyId: facultyId,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) return;
    setState(() => _selectedDate = picked);
    await _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.isAdmin ?? false;
    final state = ref.watch(substitutionProvider);
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(_selectedDate);

    return LoadingOverlayWidget(
      isLoading: state.isSubmitting,
      message: 'Saving substitution...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Substitutions'),
          actions: [
            IconButton(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_outlined),
              tooltip: 'Select Date',
            ),
            IconButton(
              onPressed: _loadRecords,
              icon: const Icon(Icons.refresh_outlined),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAdmin
                              ? 'Day-only substitutions for admin review'
                              : 'Your substitutions for this date',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: state.status == SubstitutionStatus.loading &&
                      state.records.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _SubstitutionList(
                      isAdmin: isAdmin,
                      selectedDate: _selectedDate,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubstitutionList extends ConsumerWidget {
  final bool isAdmin;
  final DateTime selectedDate;

  const _SubstitutionList({
    required this.isAdmin,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(substitutionProvider);
    final records = state.records;

    if (records.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.swap_horiz_rounded,
        title: 'No substitutions recorded',
        subtitle: 'Temporary replacements for this date will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = records[index];
        final statusColor = _statusColor(item.normalizedStatus);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.subjectName ?? item.subjectCode ?? 'Lecture',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.normalizedStatus.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${item.dayName} • ${item.date}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _FacultyLine(
                      icon: Icons.person_outline,
                      label: 'Original',
                      value: item.originalFacultyName ?? 'Unknown',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FacultyLine(
                      icon: Icons.person_add_alt_1_outlined,
                      label: 'Substitute',
                      value: item.substituteFacultyName ?? 'Unknown',
                    ),
                  ),
                ],
              ),
              if (item.reason != null && item.reason!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.reason!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
              if (isAdmin && item.isPending) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final user = ref.read(currentUserProvider);
                      await ref.read(substitutionProvider.notifier).approveSubstitution(
                            item.id,
                            approvedBy: user?.uid,
                          );
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('One-tap Approve'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }
}

class _FacultyLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _FacultyLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '$label: $value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
