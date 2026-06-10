import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/temporary_timetable_model.dart';
import '../services/temporary_timetable_service.dart';

enum TemporaryTimetableStatus { initial, loading, loaded, error }

class TemporaryTimetableState {
  final TemporaryTimetableStatus status;
  final List<TemporaryTimeSlot> slots;
  final String? errorMessage;
  final bool isSaving;

  const TemporaryTimetableState({
    this.status = TemporaryTimetableStatus.initial,
    this.slots = const [],
    this.errorMessage,
    this.isSaving = false,
  });

  TemporaryTimetableState copyWith({
    TemporaryTimetableStatus? status,
    List<TemporaryTimeSlot>? slots,
    String? errorMessage,
    bool? isSaving,
  }) {
    return TemporaryTimetableState(
      status: status ?? this.status,
      slots: slots ?? this.slots,
      errorMessage: errorMessage ?? this.errorMessage,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class TemporaryTimetableNotifier extends StateNotifier<TemporaryTimetableState> {
  final TemporaryTimetableService _service;

  TemporaryTimetableNotifier(this._service) : super(const TemporaryTimetableState());

  Future<void> loadSlots({
    int? branchId,
    int? semester,
    String? division,
    String? date,
    String? fromDate,
    String? toDate,
  }) async {
    state = state.copyWith(status: TemporaryTimetableStatus.loading);
    try {
      final slots = await _service.fetchTemporarySlots(
        branchId: branchId,
        semester: semester,
        division: division,
        date: date,
        fromDate: fromDate,
        toDate: toDate,
      );
      state = state.copyWith(
        status: TemporaryTimetableStatus.loaded,
        slots: slots,
      );
    } catch (e) {
      state = state.copyWith(
        status: TemporaryTimetableStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> createSlot(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true);
    try {
      await _service.createTemporarySlot(data);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> saveBulkSlots(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true);
    try {
      await _service.createBulkSlots(data);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> generateSlot(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true);
    try {
      await _service.generateTemporarySlot(data);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> deleteSlot(int id) async {
    try {
      await _service.deleteTemporarySlot(id);
      state = state.copyWith(
        slots: state.slots.where((s) => s.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<Uint8List?> downloadPdf({
    int? branchId,
    int? semester,
    String? division,
    String? date,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      return await _service.downloadTemporaryPdf(
        branchId: branchId,
        semester: semester,
        division: division,
        date: date,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final temporaryTimetableProvider = StateNotifierProvider<TemporaryTimetableNotifier, TemporaryTimetableState>((ref) {
  final service = ref.watch(temporaryTimetableServiceProvider);
  return TemporaryTimetableNotifier(service);
});
