import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/timeslot_template_model.dart';
import '../../../providers/timeslot_provider.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/loading_overlay_widget.dart';

class ManageTimeslotsScreen extends ConsumerStatefulWidget {
  const ManageTimeslotsScreen({super.key});

  @override
  ConsumerState<ManageTimeslotsScreen> createState() =>
      _ManageTimeslotsScreenState();
}

class _ManageTimeslotsScreenState
    extends ConsumerState<ManageTimeslotsScreen> {
  int? _selectedBranch;
  int? _selectedSemester;
  String? _selectedDivision;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTimeslots();
    });
  }

  void _loadTimeslots() {
    ref.read(timeslotProvider.notifier).loadTimeslots(
          branchId: _selectedBranch,
          semester: _selectedSemester,
          division: _selectedDivision,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timeslotProvider);
    final isLoading =
        state.status == TimeslotStatus.loading && state.timeslots.isEmpty;

    return LoadingOverlayWidget(
      isLoading: state.status == TimeslotStatus.loading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configure Time Slots'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: _loadTimeslots,
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (state.timeslots.isEmpty)
              FloatingActionButton.extended(
                heroTag: 'seed',
                onPressed: () => _confirmSeedDefaults(context),
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('Load Defaults'),
                backgroundColor: Colors.deepPurple,
              ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: 'add',
              onPressed: () => _showTimeslotDialog(context, null),
              icon: const Icon(Icons.add),
              label: const Text('Add Slot'),
            ),
          ],
        ),
        body: Column(
          children: [
            // Info banner
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Slots are used when generating timetables. '
                        'Slots marked as Break are skipped during scheduling. '
                        'If no slots are configured, 8 default 1-hour periods (8 AM – 5 PM) are used.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Filters Card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _selectedBranch,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Global / All')),
                        DropdownMenuItem(value: 1, child: Text('CS')),
                        DropdownMenuItem(value: 2, child: Text('IT')),
                        DropdownMenuItem(value: 3, child: Text('EXTC')),
                        DropdownMenuItem(value: 4, child: Text('Mech')),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedBranch = v);
                        _loadTimeslots();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _selectedSemester,
                      decoration: const InputDecoration(
                        labelText: 'Semester',
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Sem')),
                        ...List.generate(8, (i) => DropdownMenuItem(value: i + 1, child: Text('Sem ${i + 1}'))),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedSemester = v);
                        _loadTimeslots();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _selectedDivision,
                      decoration: const InputDecoration(
                        labelText: 'Division',
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Div')),
                        DropdownMenuItem(value: 'A', child: Text('Div A')),
                        DropdownMenuItem(value: 'B', child: Text('Div B')),
                        DropdownMenuItem(value: 'C', child: Text('Div C')),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedDivision = v);
                        _loadTimeslots();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Error banner
            if (state.errorMessage != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.errorMessage!,
                  style: TextStyle(color: AppColors.error),
                ),
              ),

            // List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.timeslots.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.schedule_outlined,
                          title: 'No time slots configured',
                          subtitle:
                              'Try adjusting your filters, load defaults, or add a slot manually.',
                        )
                      : ReorderableListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: state.timeslots.length,
                          onReorder: _onReorder,
                          itemBuilder: (context, i) {
                            final slot = state.timeslots[i];
                            return _TimeslotCard(
                              key: ValueKey(slot.id),
                              slot: slot,
                              onEdit: () =>
                                  _showTimeslotDialog(context, slot),
                              onDelete: () =>
                                  _confirmDelete(context, slot),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    final timeslots =
        List<TimeSlotTemplateModel>.from(ref.read(timeslotProvider).timeslots);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = timeslots.removeAt(oldIndex);
    timeslots.insert(newIndex, item);

    // Update sort_order for affected items
    final notifier = ref.read(timeslotProvider.notifier);
    for (var i = 0; i < timeslots.length; i++) {
      final t = timeslots[i];
      if (t.sortOrder != i + 1) {
        await notifier.updateTimeslot(t.id, {'sort_order': i + 1});
      }
    }
    // Reload to reflect new order
    _loadTimeslots();
  }

  Future<void> _showTimeslotDialog(
      BuildContext context, TimeSlotTemplateModel? existing) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _TimeslotFormDialog(
        slot: existing,
        defaultBranchId: _selectedBranch,
        defaultSemester: _selectedSemester,
        defaultDivision: _selectedDivision,
      ),
    );
    if (result == null) return;
    if (!mounted) return;
    final notifier = ref.read(timeslotProvider.notifier);
    if (existing == null) {
      await notifier.createTimeslot(result);
    } else {
      await notifier.updateTimeslot(existing.id, result);
    }
    _loadTimeslots();
  }

  Future<void> _confirmSeedDefaults(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Load Default Slots'),
        content: const Text(
          'This will add the 8 standard 1-hour periods (8 AM – 5 PM) '
          'plus a lunch break to the database. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Load'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(timeslotProvider.notifier).seedDefaults();
      _loadTimeslots();
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, TimeSlotTemplateModel slot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Time Slot'),
        content: Text(
          'Delete slot "${slot.label ?? slot.timeRange}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(timeslotProvider.notifier).deleteTimeslot(slot.id);
      _loadTimeslots();
    }
  }
}

class _TimeslotCard extends StatelessWidget {
  final TimeSlotTemplateModel slot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TimeslotCard({
    super.key,
    required this.slot,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isBreak = slot.breakSlot;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isBreak ? Colors.orange.withOpacity(0.07) : null,
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: 0, // handled by ReorderableListView
          child: Icon(
            isBreak ? Icons.free_breakfast_outlined : Icons.schedule_outlined,
            color: isBreak ? Colors.orange : Colors.deepPurple,
          ),
        ),
        title: Row(
          children: [
            Text(
              slot.label ?? slot.timeRange,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (isBreak) ...[
              const SizedBox(width: 8),
              Chip(
                label: const Text('Break'),
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.orange.withOpacity(0.2),
                labelStyle:
                    const TextStyle(color: Colors.orange, fontSize: 11),
              ),
            ],
            if (slot.isActive == 0) ...[
              const SizedBox(width: 8),
              const Chip(
                label: Text('Inactive'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(slot.timeRange),
            const SizedBox(height: 4),
            Row(
              children: [
                if (slot.branchId != null)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _branchName(slot.branchId!),
                      style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (slot.semester != null)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Sem ${slot.semester}',
                      style: const TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (slot.division != null)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Div ${slot.division}',
                      style: const TextStyle(color: Colors.teal, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (slot.branchId == null && slot.semester == null && slot.division == null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Global / All Dept',
                      style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
              splashRadius: 20,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              splashRadius: 20,
              color: AppColors.error,
            ),
            const Icon(Icons.drag_handle, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  static String _branchName(int id) {
    switch (id) {
      case 1: return 'CS';
      case 2: return 'IT';
      case 3: return 'EXTC';
      case 4: return 'Mech';
      default: return 'Branch $id';
    }
  }
}

class _TimeslotFormDialog extends StatefulWidget {
  final TimeSlotTemplateModel? slot;
  final int? defaultBranchId;
  final int? defaultSemester;
  final String? defaultDivision;

  const _TimeslotFormDialog({
    this.slot,
    this.defaultBranchId,
    this.defaultSemester,
    this.defaultDivision,
  });

  @override
  State<_TimeslotFormDialog> createState() => _TimeslotFormDialogState();
}

class _TimeslotFormDialogState extends State<_TimeslotFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late final TextEditingController _sortCtrl;
  late int _startHr;
  late int _startMin;
  late int _endHr;
  late int _endMin;
  bool _isBreak = false;
  bool _isActive = true;

  int? _branchId;
  int? _semester;
  String? _division;

  @override
  void initState() {
    super.initState();
    final s = widget.slot;
    _labelCtrl = TextEditingController(text: s?.label ?? '');
    _sortCtrl =
        TextEditingController(text: (s?.sortOrder ?? 0).toString());
    _startHr = s?.startTimeHr ?? 8;
    _startMin = s?.startTimeMinutes ?? 0;
    _endHr = s?.endTimeHr ?? 9;
    _endMin = s?.endTimeMinutes ?? 0;
    _isBreak = s?.breakSlot ?? false;
    _isActive = (s?.isActive ?? 1) != 0;

    _branchId = s?.branchId ?? widget.defaultBranchId;
    _semester = s?.semester ?? widget.defaultSemester;
    _division = s?.division ?? widget.defaultDivision;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  String _timeLabel(int hr, int min) =>
      '${hr.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final hours = List.generate(24, (i) => i);
    final minutes = List.generate(60, (i) => i);

    return AlertDialog(
      title: Text(widget.slot == null ? 'Add Time Slot' : 'Edit Time Slot'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int?>(
                  value: _branchId,
                  decoration: const InputDecoration(labelText: 'Department / Branch'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Global / All (Default)')),
                    DropdownMenuItem(value: 1, child: Text('CS')),
                    DropdownMenuItem(value: 2, child: Text('IT')),
                    DropdownMenuItem(value: 3, child: Text('EXTC')),
                    DropdownMenuItem(value: 4, child: Text('Mech')),
                  ],
                  onChanged: (v) => setState(() => _branchId = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _semester,
                        decoration: const InputDecoration(labelText: 'Semester'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Global / All')),
                          ...List.generate(8, (i) => DropdownMenuItem(value: i + 1, child: Text('Sem ${i + 1}'))),
                        ],
                        onChanged: (v) => setState(() => _semester = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _division,
                        decoration: const InputDecoration(labelText: 'Division'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Global / All')),
                          DropdownMenuItem(value: 'A', child: Text('Div A')),
                          DropdownMenuItem(value: 'B', child: Text('Div B')),
                          DropdownMenuItem(value: 'C', child: Text('Div C')),
                        ],
                        onChanged: (v) => setState(() => _division = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _labelCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Label (e.g. Period 1)'),
                ),
                const SizedBox(height: 16),
                Text('Start Time',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _startHr,
                        decoration: const InputDecoration(labelText: 'Hour'),
                        items: hours
                            .map((h) => DropdownMenuItem(
                                  value: h,
                                  child: Text(_timeLabel(h, 0)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _startHr = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _startMin,
                        decoration: const InputDecoration(labelText: 'Min'),
                        items: minutes
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m.toString().padLeft(2, '0')),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _startMin = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('End Time',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _endHr,
                        decoration: const InputDecoration(labelText: 'Hour'),
                        items: hours
                            .map((h) => DropdownMenuItem(
                                  value: h,
                                  child: Text(_timeLabel(h, 0)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _endHr = v!),
                        validator: (_) {
                          if (_endHr < _startHr ||
                              (_endHr == _startHr && _endMin <= _startMin)) {
                            return 'End must be after start';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _endMin,
                        decoration: const InputDecoration(labelText: 'Min'),
                        items: minutes
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m.toString().padLeft(2, '0')),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _endMin = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sortCtrl,
                  decoration: const InputDecoration(labelText: 'Sort Order'),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Break Slot'),
                  subtitle:
                      const Text('Break slots are skipped during scheduling'),
                  value: _isBreak,
                  onChanged: (v) => setState(() => _isBreak = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.slot == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'branch_id': _branchId,
      'semester': _semester,
      'division': _division,
      'label': _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
      'startTimeHr': _startHr,
      'startTimeMinutes': _startMin,
      'endTimeHr': _endHr,
      'endTimeMinutes': _endMin,
      'is_break': _isBreak ? 1 : 0,
      'sort_order':
          int.tryParse(_sortCtrl.text) ?? 0,
      'is_active': _isActive ? 1 : 0,
    });
  }
}
