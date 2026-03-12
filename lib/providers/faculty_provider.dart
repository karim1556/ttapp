import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/faculty_model.dart';
import '../services/faculty_service.dart';

enum FacultyStatus { initial, loading, loaded, error }

class FacultyState {
  final FacultyStatus status;
  final List<FacultyModel> faculty;
  final String? errorMessage;

  const FacultyState({
    this.status = FacultyStatus.initial,
    this.faculty = const [],
    this.errorMessage,
  });

  FacultyState copyWith({
    FacultyStatus? status,
    List<FacultyModel>? faculty,
    String? errorMessage,
  }) {
    return FacultyState(
      status: status ?? this.status,
      faculty: faculty ?? this.faculty,
      errorMessage: errorMessage,
    );
  }
}

class FacultyNotifier extends StateNotifier<FacultyState> {
  final FacultyService _facultyService;

  FacultyNotifier(this._facultyService) : super(const FacultyState());

  Future<void> loadFaculty({int? branchId, int? departId}) async {
    state = state.copyWith(status: FacultyStatus.loading);
    try {
      final list = await _facultyService.fetchAllFaculty(
        branchId: branchId,
        departId: departId,
      );
      state = state.copyWith(status: FacultyStatus.loaded, faculty: list);
    } on Exception catch (e) {
      state = state.copyWith(
        status: FacultyStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Returns credentials map {email, defaultPassword} on success, null on failure.
  Future<Map<String, dynamic>?> createFaculty(Map<String, dynamic> data) async {
    try {
      final result = await _facultyService.createFaculty(data);
      final created = result['faculty'] as FacultyModel;
      state = state.copyWith(faculty: [...state.faculty, created]);
      return result['credentials'] as Map<String, dynamic>?;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  Future<bool> updateFaculty(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _facultyService.updateFaculty(id, data);
      final newList = state.faculty
          .map((f) => f.facultyId == id ? updated : f)
          .toList();
      state = state.copyWith(faculty: newList);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteFaculty(int id) async {
    try {
      await _facultyService.deleteFaculty(id);
      state = state.copyWith(
        faculty: state.faculty.where((f) => f.facultyId != id).toList(),
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final facultyProvider =
    StateNotifierProvider<FacultyNotifier, FacultyState>((ref) {
  final facultyService = ref.watch(facultyServiceProvider);
  return FacultyNotifier(facultyService);
});
