import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/constraint_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/constraint_provider.dart';
import '../../../widgets/loading_overlay_widget.dart';

class FacultyConstraintsScreen extends ConsumerStatefulWidget {
  const FacultyConstraintsScreen({super.key});

  @override
  ConsumerState<FacultyConstraintsScreen> createState() =>
      _FacultyConstraintsScreenState();
}

class _FacultyConstraintsScreenState
    extends ConsumerState<FacultyConstraintsScreen> {
  int _maxPerDay = 4;
  int _totalPerWeek = 18;
  final List<UnavailableSlot> _unavailableSlots = [];
  final List<PreferredSlot> _preferredSlots = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref
            .read(constraintProvider.notifier)
            .loadConstraints(int.tryParse(user.uid.toString()) ?? 0);
      }
    });
  }

  // Sync local state when constraint data loads
  void _applyLoadedConstraints(ConstraintModel c) {
    _maxPerDay = c.maxLecturesPerDay;
    _totalPerWeek = c.totalLecturesPerWeek;
    _unavailableSlots
      ..clear()
      ..addAll(c.unavailableSlots);
    _preferredSlots
      ..clear()
      ..addAll(c.preferredSlots);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(constraintProvider);
    final isSaving = state.status == ConstraintStatus.saving;

    // Populate local form state once loaded
    if (state.status == ConstraintStatus.loaded && state.constraint != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _maxPerDay == 4 &&
            _totalPerWeek == 18 &&
            _unavailableSlots.isEmpty &&
            _preferredSlots.isEmpty) {
          setState(() => _applyLoadedConstraints(state.constraint!));
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Scheduling Constraints'),
        actions: [
          TextButton.icon(
            onPressed: isSaving ? null : _saveConstraints,
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ],
      ),
      body: state.status == ConstraintStatus.loading
          ? const FullScreenLoader(message: 'Loading constraints...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoCard(context),
                  const SizedBox(height: 20),
                  _maxLecturesCard(context),
                  const SizedBox(height: 16),
                  _totalLecturesCard(context),
                  const SizedBox(height: 20),
                  _unavailableSlotsCard(context),
                  const SizedBox(height: 16),
                  _preferredSlotsCard(context),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            onPressed: isSaving ? null : _saveConstraints,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Save Constraints',
                    style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'These constraints help the AI scheduler assign your lectures. '
              'Mark slots you are unavailable, and optionally preferred timings.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _maxLecturesCard(BuildContext context) {
    return _SectionCard(
      title: 'Max Lectures Per Day',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_maxPerDay lectures',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
              Text('(1 – 8)',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          Slider(
            value: _maxPerDay.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            label: '$_maxPerDay',
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _maxPerDay = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _totalLecturesCard(BuildContext context) {
    return _SectionCard(
      title: 'Total Lectures Per Week',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_totalPerWeek lectures',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
              Text('(5 – 30)',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          Slider(
            value: _totalPerWeek.toDouble(),
            min: 5,
            max: 30,
            divisions: 25,
            label: '$_totalPerWeek',
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _totalPerWeek = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _unavailableSlotsCard(BuildContext context) {
    return _SectionCard(
      title: 'Unavailable Slots',
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
        onPressed: () => _addSlotDialog(
          context,
          isUnavailable: true,
        ),
      ),
      child: _unavailableSlots.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'No unavailable slots added.\nTap + to add.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          : Column(
              children: _unavailableSlots
                  .asMap()
                  .entries
                  .map((entry) => _SlotChip(
                        label:
                            '${entry.value.day} — ${entry.value.startHour}:00',
                        color: AppColors.error,
                        onRemove: () => setState(
                            () => _unavailableSlots.removeAt(entry.key)),
                      ))
                  .toList(),
            ),
    );
  }

  Widget _preferredSlotsCard(BuildContext context) {
    return _SectionCard(
      title: 'Preferred Slots (optional)',
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
        onPressed: () => _addSlotDialog(context, isUnavailable: false),
      ),
      child: _preferredSlots.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'No preferred slots added.\nTap + to add.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          : Column(
              children: _preferredSlots
                  .asMap()
                  .entries
                  .map((entry) => _SlotChip(
                        label:
                            '${entry.value.day} — ${entry.value.startHour}:00',
                        color: AppColors.success,
                        onRemove: () => setState(
                            () => _preferredSlots.removeAt(entry.key)),
                      ))
                  .toList(),
            ),
    );
  }

  void _addSlotDialog(BuildContext context, {required bool isUnavailable}) {
    String selectedDay = AppConstants.daysOfWeek.first;
    // slot hours: slot 1 = 8:00, slot 2 = 9:00, ... slot 8 = 15:00
    int slotHour = 8;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: Text(isUnavailable ? 'Add Unavailable Slot' : 'Add Preferred Slot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedDay,
                decoration: const InputDecoration(labelText: 'Day'),
                items: AppConstants.daysOfWeek
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDs(() => selectedDay = v);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: slotHour,
                decoration:
                    const InputDecoration(labelText: 'Time Slot'),
                items: List.generate(
                    8,
                    (i) => DropdownMenuItem(
                        value: 8 + i, child: Text('Slot ${i + 1} (${8 + i}:00)'))),
                onChanged: (v) {
                  if (v != null) setDs(() => slotHour = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isUnavailable) {
                    _unavailableSlots.add(UnavailableSlot(
                      day: selectedDay,
                      startHour: slotHour,
                      startMinutes: 0,
                      endHour: slotHour + 1,
                      endMinutes: 0,
                    ));
                  } else {
                    _preferredSlots.add(PreferredSlot(
                      day: selectedDay,
                      startHour: slotHour,
                      startMinutes: 0,
                      endHour: slotHour + 1,
                      endMinutes: 0,
                    ));
                  }
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveConstraints() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final facultyId = int.tryParse(user.uid.toString()) ?? 0;
    final existing = ref.read(constraintProvider).constraint;
    final constraint = (existing ??
            ConstraintModel(
              facultyId: facultyId,
              maxLecturesPerDay: _maxPerDay,
              totalLecturesPerWeek: _totalPerWeek,
            ))
        .copyWith(
      maxLecturesPerDay: _maxPerDay,
      totalLecturesPerWeek: _totalPerWeek,
      unavailableSlots: _unavailableSlots,
      preferredSlots: _preferredSlots,
    );

    final success = await ref
        .read(constraintProvider.notifier)
        .saveConstraints(constraint);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            success ? 'Constraints saved successfully' : 'Failed to save'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ));
    }
  }
}

// ─── Helper widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onRemove;

  const _SlotChip({
    required this.label,
    required this.color,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_outlined, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w500))),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, color: color, size: 18),
          ),
        ],
      ),
    );
  }
}
