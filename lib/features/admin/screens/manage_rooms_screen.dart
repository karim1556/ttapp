import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/room_model.dart';
import '../../../providers/room_provider.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/loading_overlay_widget.dart';

const _roomTypes = ['Classroom', 'Lab', 'Tutorial', 'Seminar Hall', 'Office'];
const _branchMap = {1: 'CS', 2: 'IT', 3: 'EXTC', 4: 'Mech'};

class ManageRoomsScreen extends ConsumerStatefulWidget {
  const ManageRoomsScreen({super.key});

  @override
  ConsumerState<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends ConsumerState<ManageRoomsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _filterBranch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(roomProvider.notifier).loadRooms();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    final isLoading =
        roomState.status == RoomStatus.loading && roomState.rooms.isEmpty;

    final filtered = roomState.rooms.where((r) {
      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          r.roomNumber.toLowerCase().contains(q) ||
          (r.name?.toLowerCase().contains(q) ?? false);
      final matchesBranch =
          _filterBranch == null || r.branchId == _filterBranch;
      return matchesQuery && matchesBranch;
    }).toList();

    return LoadingOverlayWidget(
      isLoading: roomState.status == RoomStatus.loading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Rooms'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () =>
                  ref.read(roomProvider.notifier).loadRooms(branchId: _filterBranch),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showRoomDialog(context, null),
          icon: const Icon(Icons.add),
          label: const Text('Add Room'),
        ),
        body: Column(
          children: [
            // Search + filter row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search rooms…',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int?>(
                    value: _filterBranch,
                    hint: const Text('All Branches'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Branches'),
                      ),
                      ..._branchMap.entries.map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _filterBranch = v);
                      ref
                          .read(roomProvider.notifier)
                          .loadRooms(branchId: v);
                    },
                  ),
                ],
              ),
            ),

            // Error banner
            if (roomState.errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  roomState.errorMessage!,
                  style: TextStyle(color: AppColors.error),
                ),
              ),

            // List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.meeting_room_outlined,
                          title: 'No rooms found',
                          subtitle: 'Tap the + button to add a room.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) =>
                              _RoomCard(
                                room: filtered[i],
                                onEdit: () =>
                                    _showRoomDialog(context, filtered[i]),
                                onDelete: () =>
                                    _confirmDelete(context, filtered[i]),
                              ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRoomDialog(BuildContext context, RoomModel? existing) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _RoomFormDialog(room: existing),
    );
    if (result == null) return;
    if (!mounted) return;
    final notifier = ref.read(roomProvider.notifier);
    if (existing == null) {
      await notifier.createRoom(result);
    } else {
      await notifier.updateRoom(existing.id, result);
    }
  }

  Future<void> _confirmDelete(BuildContext context, RoomModel room) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Delete room "${room.roomNumber}"? This cannot be undone.'),
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
      await ref.read(roomProvider.notifier).deleteRoom(room.id);
    }
  }
}

class _RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoomCard({
    required this.room,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final branchLabel = room.branchId != null
        ? _branchMap[room.branchId] ?? 'Branch ${room.branchId}'
        : null;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _typeColor(room.roomType).withOpacity(0.15),
          child: Icon(
            _typeIcon(room.roomType),
            color: _typeColor(room.roomType),
          ),
        ),
        title: Text(
          room.roomNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text([
          if (room.name != null && room.name!.isNotEmpty) room.name!,
          if (room.roomType != null) room.roomType!,
          if (room.capacity != null) 'Capacity: ${room.capacity}',
          if (branchLabel != null) branchLabel,
          if (room.floor != null && room.floor!.isNotEmpty) 'Floor ${room.floor}',
        ].join(' · ')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (room.isActive == 0)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text('Inactive'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
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
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'Lab':
        return Icons.computer_outlined;
      case 'Seminar Hall':
        return Icons.groups_outlined;
      case 'Tutorial':
        return Icons.edit_note_outlined;
      case 'Office':
        return Icons.business_outlined;
      default:
        return Icons.meeting_room_outlined;
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'Lab':
        return Colors.indigo;
      case 'Seminar Hall':
        return Colors.purple;
      case 'Tutorial':
        return Colors.orange;
      case 'Office':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }
}

class _RoomFormDialog extends StatefulWidget {
  final RoomModel? room;

  const _RoomFormDialog({this.room});

  @override
  State<_RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends State<_RoomFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roomNumCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _capacityCtrl;
  late final TextEditingController _floorCtrl;
  String? _roomType;
  int? _branchId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final r = widget.room;
    _roomNumCtrl = TextEditingController(text: r?.roomNumber ?? '');
    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _capacityCtrl =
        TextEditingController(text: r?.capacity?.toString() ?? '');
    _floorCtrl = TextEditingController(text: r?.floor ?? '');
    _roomType = r?.roomType ?? 'Classroom';
    _branchId = r?.branchId;
    _isActive = (r?.isActive ?? 1) == 1;
  }

  @override
  void dispose() {
    _roomNumCtrl.dispose();
    _nameCtrl.dispose();
    _capacityCtrl.dispose();
    _floorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.room == null ? 'Add Room' : 'Edit Room'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _roomNumCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Room Number *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Name / Description'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _roomType,
                  decoration: const InputDecoration(labelText: 'Room Type'),
                  items: _roomTypes
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _roomType = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _capacityCtrl,
                  decoration: const InputDecoration(labelText: 'Capacity'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                      return 'Must be a number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: _branchId,
                  decoration: const InputDecoration(labelText: 'Branch'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Branches / General'),
                    ),
                    ..._branchMap.entries.map(
                      (e) => DropdownMenuItem(
                          value: e.key, child: Text(e.value)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _branchId = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _floorCtrl,
                  decoration: const InputDecoration(labelText: 'Floor'),
                ),
                const SizedBox(height: 8),
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
          child: Text(widget.room == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'room_number': _roomNumCtrl.text.trim(),
      'name': _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      'room_type': _roomType,
      'capacity': _capacityCtrl.text.isEmpty
          ? null
          : int.tryParse(_capacityCtrl.text),
      'branch_id': _branchId,
      'floor': _floorCtrl.text.trim().isEmpty ? null : _floorCtrl.text.trim(),
      'is_active': _isActive ? 1 : 0,
    });
  }
}
