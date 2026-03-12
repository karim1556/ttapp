import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room_model.dart';
import '../services/room_service.dart';

enum RoomStatus { initial, loading, loaded, error }

class RoomState {
  final RoomStatus status;
  final List<RoomModel> rooms;
  final String? errorMessage;

  const RoomState({
    this.status = RoomStatus.initial,
    this.rooms = const [],
    this.errorMessage,
  });

  RoomState copyWith({
    RoomStatus? status,
    List<RoomModel>? rooms,
    String? errorMessage,
  }) {
    return RoomState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      errorMessage: errorMessage,
    );
  }
}

class RoomNotifier extends StateNotifier<RoomState> {
  final RoomService _roomService;

  RoomNotifier(this._roomService) : super(const RoomState());

  Future<void> loadRooms({int? branchId}) async {
    state = state.copyWith(status: RoomStatus.loading);
    try {
      final list = await _roomService.fetchAllRooms(branchId: branchId);
      state = state.copyWith(status: RoomStatus.loaded, rooms: list);
    } on Exception catch (e) {
      state = state.copyWith(
        status: RoomStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> createRoom(Map<String, dynamic> data) async {
    try {
      final created = await _roomService.createRoom(data);
      state = state.copyWith(rooms: [...state.rooms, created]);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateRoom(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _roomService.updateRoom(id, data);
      final newList = state.rooms.map((r) => r.id == id ? updated : r).toList();
      state = state.copyWith(rooms: newList);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteRoom(int id) async {
    try {
      await _roomService.deleteRoom(id);
      state = state.copyWith(
        rooms: state.rooms.where((r) => r.id != id).toList(),
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final roomProvider = StateNotifierProvider<RoomNotifier, RoomState>((ref) {
  final roomService = ref.watch(roomServiceProvider);
  return RoomNotifier(roomService);
});
