import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/temporary_timetable_model.dart';
import '../../../models/faculty_model.dart';
import '../../../models/subject_model.dart';
import '../../../models/room_model.dart';
import '../../../providers/temporary_timetable_provider.dart';
import '../../../providers/faculty_provider.dart';
import '../../../providers/subject_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../providers/timeslot_provider.dart';
import '../../../models/timeslot_template_model.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/loading_overlay_widget.dart';

const _branchMap = {1: 'CS', 2: 'IT', 3: 'EXTC', 4: 'Mech'};

class ManageTemporaryTimetableScreen extends ConsumerStatefulWidget {
  const ManageTemporaryTimetableScreen({super.key});

  @override
  ConsumerState<ManageTemporaryTimetableScreen> createState() =>
      _ManageTemporaryTimetableScreenState();
}

class _ManageTemporaryTimetableScreenState
    extends ConsumerState<ManageTemporaryTimetableScreen> {
  int _filterBranch = 1;
  int _filterSem = 4;
  String _filterDivision = 'A';
  DateTimeRange? _filterDateRange;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _filterDateRange = DateTimeRange(
      start: DateTime(today.year, today.month, today.day),
      end: DateTime(today.year, today.month, today.day)
          .add(const Duration(days: 7)),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(facultyProvider.notifier).loadFaculty();
      ref.read(roomProvider.notifier).loadRooms();
      _loadSlots();
    });
  }

  void _loadSlots() {
    final startStr =
        DateFormat('yyyy-MM-dd').format(_filterDateRange!.start);
    final endStr = DateFormat('yyyy-MM-dd').format(_filterDateRange!.end);
    ref.read(temporaryTimetableProvider.notifier).loadSlots(
          branchId: _filterBranch,
          semester: _filterSem,
          division: _filterDivision,
          fromDate: startStr,
          toDate: endStr,
        );
    ref
        .read(subjectProvider.notifier)
        .loadSubjects(branchId: _filterBranch);
  }

  Future<void> _exportPdf() async {
    final startStr =
        DateFormat('yyyy-MM-dd').format(_filterDateRange!.start);
    final endStr = DateFormat('yyyy-MM-dd').format(_filterDateRange!.end);
    final pdfBytes =
        await ref.read(temporaryTimetableProvider.notifier).downloadPdf(
              branchId: _filterBranch,
              semester: _filterSem,
              division: _filterDivision,
              fromDate: startStr,
              toDate: endStr,
            );

    if (pdfBytes != null) {
      final fileName =
          'temp_tt_${_branchMap[_filterBranch]}_sem${_filterSem}_div$_filterDivision.pdf';
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to generate PDF. Make sure slots exist.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tempState = ref.watch(temporaryTimetableProvider);
    final isPageLoading =
        tempState.status == TemporaryTimetableStatus.loading;

    return LoadingOverlayWidget(
      isLoading: tempState.isSaving,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Temporary Timetable'),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Export PDF',
              onPressed: isPageLoading ? null : _exportPdf,
            ),
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: _loadSlots,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Schedule Event'),
        ),
        body: Column(
          children: [
            // ── Filter Card ──
            Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _FilterDropdown<int>(
                          label: 'Branch',
                          value: _filterBranch,
                          items: _branchMap.entries
                              .map((e) => DropdownMenuItem(
                                  value: e.key, child: Text(e.value)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _filterBranch = v);
                              _loadSlots();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FilterDropdown<int>(
                          label: 'Semester',
                          value: _filterSem,
                          items: List.generate(8, (i) => i + 1)
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text('Sem $s')))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _filterSem = v);
                              _loadSlots();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FilterDropdown<String>(
                          label: 'Division',
                          value: _filterDivision,
                          items: ['A', 'B', 'C']
                              .map((d) => DropdownMenuItem(
                                  value: d, child: Text('Div $d')))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _filterDivision = v);
                              _loadSlots();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        initialDateRange: _filterDateRange,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 30)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) {
                        setState(() => _filterDateRange = picked);
                        _loadSlots();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range_rounded,
                              size: 18, color: Color(0xFF5C6BC0)),
                          const SizedBox(width: 10),
                          const Text(
                            'Date Range',
                            style: TextStyle(
                                color: Color(0xFF5C6BC0),
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Text(
                            '${DateFormat('MMM d').format(_filterDateRange!.start)}  →  ${DateFormat('MMM d').format(_filterDateRange!.end)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF1A237E)),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded,
                              size: 16, color: Color(0xFF5C6BC0)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Error Banner ──
            if (tempState.errorMessage != null)
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tempState.errorMessage!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => ref
                          .read(temporaryTimetableProvider.notifier)
                          .clearError(),
                    ),
                  ],
                ),
              ),

            // ── Slot List ──
            Expanded(
              child: isPageLoading
                  ? const Center(child: CircularProgressIndicator())
                  : tempState.slots.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.event_busy_outlined,
                          title: 'No temporary slots found',
                          subtitle:
                              'Tap "Schedule Event" to create a temporary timetable.',
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(14, 14, 14, 100),
                          itemCount: tempState.slots.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final slot = tempState.slots[i];
                            return _TemporarySlotCard(
                              slot: slot,
                              onDelete: () => _confirmDelete(context, slot),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final result = await showGeneralDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
      pageBuilder: (ctx, anim1, anim2) => _AddSlotFormDialog(
        branchId: _filterBranch,
        sem: _filterSem,
        division: _filterDivision,
      ),
    );

    if (result == null) return;

    final notifier = ref.read(temporaryTimetableProvider.notifier);
    final success = await notifier.saveBulkSlots(result);

    if (success) {
      _loadSlots();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Temporary timetable saved successfully!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, TemporaryTimeSlot slot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Slot'),
        content: Text(
          'Delete "${slot.subjectCode ?? slot.eventName ?? 'Event'}" on ${DateFormat('EEE, MMM d').format(slot.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      final success =
          await ref.read(temporaryTimetableProvider.notifier).deleteSlot(slot.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot deleted.')),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────
// Filter Dropdown helper
// ─────────────────────────────────────────────────────────
class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      isDense: true,
      items: items,
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────
// Slot Card
// ─────────────────────────────────────────────────────────
class _TemporarySlotCard extends ConsumerWidget {
  final TemporaryTimeSlot slot;
  final VoidCallback onDelete;

  const _TemporarySlotCard({
    required this.slot,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facultyList = ref.watch(facultyProvider).faculty;
    final teacher = facultyList.firstWhere(
      (f) => f.facultyId == slot.facultyId,
      orElse: () => FacultyModel(facultyId: 0, name: 'N/A', email: ''),
    );

    final formattedDate =
        DateFormat('EEE, MMM d, yyyy').format(slot.date);
    final startH = slot.startTimeHr.toString().padLeft(2, '0');
    final startM = slot.startTimeMinutes.toString().padLeft(2, '0');
    final endH = slot.endTimeHr.toString().padLeft(2, '0');
    final endM = slot.endTimeMinutes.toString().padLeft(2, '0');
    final formattedTime = '$startH:$startM – $endH:$endM';

    final isLab = slot.typeOfLecture == 'Lab';
    final accentColor = isLab ? const Color(0xFF5E35B1) : const Color(0xFF1565C0);

    final subjectTitle = slot.subjectCode ?? slot.eventName ?? 'Special Event';
    final occasionLabel = slot.eventName;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Colored left bar
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subjectTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            slot.typeOfLecture ?? 'Lecture',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (occasionLabel != null &&
                        occasionLabel.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.flag_outlined,
                              size: 12, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          Text(
                            occasionLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        text: formattedDate),
                    const SizedBox(height: 5),
                    _InfoRow(
                        icon: Icons.schedule_outlined,
                        text: formattedTime),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoRow(
                            icon: Icons.person_outline_rounded,
                            text: teacher.name.isNotEmpty
                                ? teacher.name
                                : 'N/A',
                          ),
                        ),
                        const SizedBox(width: 8),
                        _InfoRow(
                          icon: Icons.meeting_room_outlined,
                          text: slot.roomNumber ?? 'No Room',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF8590A5)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF5A657A)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Add Slot Dialog
// ─────────────────────────────────────────────────────────
class _AddSlotFormDialog extends ConsumerStatefulWidget {
  final int branchId;
  final int sem;
  final String division;

  const _AddSlotFormDialog({
    required this.branchId,
    required this.sem,
    required this.division,
  });

  @override
  ConsumerState<_AddSlotFormDialog> createState() =>
      _AddSlotFormDialogState();
}

class _AddSlotFormDialogState
    extends ConsumerState<_AddSlotFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isRangeMode = false;

  DateTime? _selectedDate;
  DateTimeRange? _selectedDateRange;

  final _occasionController = TextEditingController();

  // Per-slot selection state
  final Map<int, bool> _selectedSlots = {};
  final Map<int, String?> _slotSubjects = {};
  final Map<int, String?> _slotRooms = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 1)),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timeslotProvider.notifier).loadTimeslots();
      ref.read(facultyProvider.notifier).loadFaculty();
      ref.read(roomProvider.notifier).loadRooms();
      ref
          .read(subjectProvider.notifier)
          .loadSubjects(branchId: widget.branchId);
    });
  }

  @override
  void dispose() {
    _occasionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref
        .watch(subjectProvider)
        .subjects
        .where((s) => s.semester == widget.sem)
        .toList();
    final teachers = ref.watch(facultyProvider).faculty;
    final rooms = ref
        .watch(roomProvider)
        .rooms
        .where((r) => r.active)
        .toList();
    final timeslotState = ref.watch(timeslotProvider);

    final activeSlots = timeslotState.timeslots
        .where((t) => t.active && !t.breakSlot)
        .toList()
      ..sort((a, b) {
        if (a.sortOrder != null && b.sortOrder != null) {
          return a.sortOrder!.compareTo(b.sortOrder!);
        }
        if (a.startTimeHr != b.startTimeHr) {
          return a.startTimeHr.compareTo(b.startTimeHr);
        }
        return a.startTimeMinutes.compareTo(b.startTimeMinutes);
      });

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
            maxWidth: 520,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Dialog Header ──
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 22, 16, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_note_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Generate Temporary Timetable',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Select slots & assign subjects',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // ── Dialog Body ──
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Occasion field
                        TextFormField(
                          controller: _occasionController,
                          decoration: InputDecoration(
                            labelText: 'Occasion / Purpose *',
                            hintText:
                                'e.g. Sports Day, Exam Week, Industrial Visit',
                            prefixIcon: const Icon(Icons.flag_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FF),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Occasion is required'
                                  : null,
                        ),
                        const SizedBox(height: 16),

                        // Date range toggle
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: SwitchListTile(
                            title: const Text(
                              'Multiple Days',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              'Apply same slots across a date range',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _isRangeMode,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            onChanged: (val) =>
                                setState(() => _isRangeMode = val),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Date picker
                        _isRangeMode
                            ? _DatePickerTile(
                                label: 'Date Range',
                                icon: Icons.date_range_rounded,
                                value:
                                    '${DateFormat('MMM d, yyyy').format(_selectedDateRange!.start)}  →  ${DateFormat('MMM d, yyyy').format(_selectedDateRange!.end)}',
                                onTap: () async {
                                  final picked = await showDateRangePicker(
                                    context: context,
                                    initialDateRange: _selectedDateRange,
                                    firstDate: DateTime.now()
                                        .subtract(const Duration(days: 30)),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 90)),
                                  );
                                  if (picked != null) {
                                    setState(
                                        () => _selectedDateRange = picked);
                                  }
                                },
                              )
                            : _DatePickerTile(
                                label: 'Date',
                                icon: Icons.today_rounded,
                                value: DateFormat('EEE, MMM d, yyyy')
                                    .format(_selectedDate!),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate!,
                                    firstDate: DateTime.now()
                                        .subtract(const Duration(days: 30)),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 90)),
                                  );
                                  if (picked != null) {
                                    setState(() => _selectedDate = picked);
                                  }
                                },
                              ),
                        const SizedBox(height: 20),

                        // Timeslot checklist heading
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3949AB),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Select Timeslots & Assign Subjects',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Check the periods you want to include, then assign a subject and room for each.',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8590A5)),
                        ),
                        const SizedBox(height: 12),

                        if (timeslotState.status == TimeslotStatus.loading)
                          const Center(
                              child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ))
                        else if (activeSlots.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'No active timeslot templates found. Please configure them in Admin Panel → Timeslots.',
                              style: TextStyle(color: AppColors.error),
                            ),
                          )
                        else
                          ...activeSlots.map((slot) {
                            final isChecked =
                                _selectedSlots[slot.id] ?? false;
                            final currentSubjectCode =
                                _slotSubjects[slot.id];
                            final currentRoom = _slotRooms[slot.id];

                            // Auto-populate teacher name
                            String teacherName = '';
                            if (currentSubjectCode != null) {
                              final sub = subjects.firstWhere(
                                (s) => s.subjectCode == currentSubjectCode,
                                orElse: () => SubjectModel(
                                    id: 0,
                                    subjectCode: '',
                                    subjectName: '',
                                    totalCredits: 0),
                              );
                              if (sub.professorAssign != null) {
                                final profId =
                                    int.tryParse(sub.professorAssign!);
                                final prof = teachers.firstWhere(
                                  (t) => t.facultyId == profId,
                                  orElse: () => FacultyModel(
                                      facultyId: 0, name: '', email: ''),
                                );
                                teacherName = prof.name;
                              }
                            }

                            return _SlotCheckCard(
                              slot: slot,
                              isChecked: isChecked,
                              subjects: subjects,
                              rooms: rooms,
                              currentSubjectCode: currentSubjectCode,
                              currentRoom: currentRoom,
                              teacherName: teacherName,
                              onToggle: (v) => setState(() {
                                _selectedSlots[slot.id] = v ?? false;
                              }),
                              onSubjectChanged: (val) => setState(() {
                                _slotSubjects[slot.id] = val;
                              }),
                              onRoomChanged: (val) => setState(() {
                                _slotRooms[slot.id] = val;
                              }),
                            );
                          }),
                      ],
                    ),
                  ),
                ),

                // ── Dialog Footer ──
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                  decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Color(0xFFEEF0F5))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () =>
                              _submit(activeSlots, subjects),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Generate Timetable'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit(
      List<TimeSlotTemplateModel> activeSlots, List<SubjectModel> subjects) {
    if (_formKey.currentState == null ||
        !_formKey.currentState!.validate()) return;

    final List<Map<String, dynamic>> slotsPayload = [];
    for (final slot in activeSlots) {
      if (_selectedSlots[slot.id] == true) {
        final subCode = _slotSubjects[slot.id];
        if (subCode == null || subCode.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Select a subject for "${slot.label ?? 'slot'}"')),
          );
          return;
        }

        final sub =
            subjects.firstWhere((s) => s.subjectCode == subCode);
        final facultyId = int.tryParse(sub.professorAssign ?? '');

        slotsPayload.add({
          'startTimeHr': slot.startTimeHr,
          'startTimeMinutes': slot.startTimeMinutes,
          'endTimeHr': slot.endTimeHr,
          'endTimeMinutes': slot.endTimeMinutes,
          'subjectCode': subCode,
          'facultyId': facultyId,
          'roomNumber': _slotRooms[slot.id],
        });
      }
    }

    if (slotsPayload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please check at least one timeslot')),
      );
      return;
    }

    final payload = <String, dynamic>{
      'branchId': widget.branchId,
      'sem': widget.sem,
      'division': widget.division,
      'eventName': _occasionController.text.trim(),
      'slots': slotsPayload,
    };

    if (_isRangeMode) {
      payload['fromDate'] =
          DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
      payload['toDate'] =
          DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
    } else {
      payload['date'] =
          DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }

    Navigator.pop(context, payload);
  }
}

// ─────────────────────────────────────────────────────────
// Per-slot check card widget
// ─────────────────────────────────────────────────────────
class _SlotCheckCard extends StatelessWidget {
  final TimeSlotTemplateModel slot;
  final bool isChecked;
  final List<SubjectModel> subjects;
  final List<RoomModel> rooms;
  final String? currentSubjectCode;
  final String? currentRoom;
  final String teacherName;
  final ValueChanged<bool?> onToggle;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<String?> onRoomChanged;

  const _SlotCheckCard({
    required this.slot,
    required this.isChecked,
    required this.subjects,
    required this.rooms,
    required this.currentSubjectCode,
    required this.currentRoom,
    required this.teacherName,
    required this.onToggle,
    required this.onSubjectChanged,
    required this.onRoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isChecked
            ? const Color(0xFFF0F4FF)
            : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isChecked
              ? const Color(0xFF3949AB)
              : const Color(0xFFE0E0E0),
          width: isChecked ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Slot header row
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onToggle(!isChecked),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: isChecked,
                      onChanged: onToggle,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      activeColor: const Color(0xFF3949AB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot.label ??
                              'Period ${slot.sortOrder ?? ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isChecked
                                ? const Color(0xFF1A237E)
                                : Colors.black87,
                          ),
                        ),
                        Text(
                          slot.timeRange,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8590A5)),
                        ),
                      ],
                    ),
                  ),
                  if (isChecked)
                    const Icon(Icons.keyboard_arrow_up_rounded,
                        color: Color(0xFF3949AB), size: 20)
                  else
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFFBBBBBB), size: 20),
                ],
              ),
            ),
          ),

          // Expanded assignment section
          if (isChecked) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  // Subject dropdown
                  DropdownButtonFormField<String>(
                    value: currentSubjectCode,
                    decoration: InputDecoration(
                      labelText: 'Subject *',
                      prefixIcon: const Icon(Icons.book_outlined, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    hint: const Text('Choose subject'),
                    items: subjects.map((sub) {
                      return DropdownMenuItem(
                        value: sub.subjectCode,
                        child: Text(
                          '${sub.subjectCode} – ${sub.subjectName}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: onSubjectChanged,
                  ),

                  // Teacher display
                  if (teacherName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_pin_rounded,
                              size: 16, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Teacher: $teacherName',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Room dropdown
                  DropdownButtonFormField<String>(
                    value: currentRoom,
                    decoration: InputDecoration(
                      labelText: 'Room',
                      prefixIcon:
                          const Icon(Icons.meeting_room_outlined, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    hint: const Text('Select room (optional)'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('— No room assigned —'),
                      ),
                      ...rooms.map((r) {
                        final label = r.name != null && r.name!.isNotEmpty
                            ? '${r.roomNumber} – ${r.name}'
                            : r.roomNumber;
                        return DropdownMenuItem(
                          value: r.roomNumber,
                          child: Text(label),
                        );
                      }),
                    ],
                    onChanged: onRoomChanged,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Date picker tile helper
// ─────────────────────────────────────────────────────────
class _DatePickerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBC8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF3949AB)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF8590A5))),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A237E))),
              ],
            ),
            const Spacer(),
            const Icon(Icons.edit_calendar_outlined,
                size: 16, color: Color(0xFF5C6BC0)),
          ],
        ),
      ),
    );
  }
}
