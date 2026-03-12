import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/constraint_model.dart';
import '../services/constraint_service.dart';

enum ConstraintStatus { initial, loading, loaded, saving, saved, error }

class ConstraintState {
  final ConstraintStatus status;
  final ConstraintModel? constraint;
  final String? errorMessage;

  const ConstraintState({
    this.status = ConstraintStatus.initial,
    this.constraint,
    this.errorMessage,
  });

  ConstraintState copyWith({
    ConstraintStatus? status,
    ConstraintModel? constraint,
    String? errorMessage,
  }) {
    return ConstraintState(
      status: status ?? this.status,
      constraint: constraint ?? this.constraint,
      errorMessage: errorMessage,
    );
  }
}

class ConstraintNotifier extends StateNotifier<ConstraintState> {
  final ConstraintService _constraintService;

  ConstraintNotifier(this._constraintService) : super(const ConstraintState());

  Future<void> loadConstraints(int facultyId) async {
    state = state.copyWith(status: ConstraintStatus.loading);
    try {
      final constraint = await _constraintService.fetchMyConstraints(facultyId);
      state = state.copyWith(
        status: ConstraintStatus.loaded,
        constraint: constraint,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: ConstraintStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> saveConstraints(ConstraintModel constraint) async {
    state = state.copyWith(status: ConstraintStatus.saving);
    try {
      final saved = await _constraintService.saveConstraints(constraint);
      state = state.copyWith(
        status: ConstraintStatus.saved,
        constraint: saved,
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        status: ConstraintStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void updateLocalConstraint(ConstraintModel updated) {
    state = state.copyWith(constraint: updated);
  }
}

final constraintProvider =
    StateNotifierProvider<ConstraintNotifier, ConstraintState>((ref) {
  final service = ref.watch(constraintServiceProvider);
  return ConstraintNotifier(service);
});
