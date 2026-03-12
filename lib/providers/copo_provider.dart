import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/copo_model.dart';
import '../services/copo_service.dart';

enum CopoStatus { initial, loading, loaded, error }

class CopoState {
  final CopoStatus status;
  final List<CopoUserCourseModel> courses;
  final String? errorMessage;

  const CopoState({
    this.status = CopoStatus.initial,
    this.courses = const [],
    this.errorMessage,
  });

  CopoState copyWith({
    CopoStatus? status,
    List<CopoUserCourseModel>? courses,
    String? errorMessage,
  }) =>
      CopoState(
        status: status ?? this.status,
        courses: courses ?? this.courses,
        errorMessage: errorMessage,
      );
}

class CopoNotifier extends StateNotifier<CopoState> {
  final CopoService _service;
  CopoNotifier(this._service) : super(const CopoState());

  Future<void> load({int? branch, int? semester, String? academicYear}) async {
    state = state.copyWith(status: CopoStatus.loading);
    try {
      final list = await _service.fetchAll(
        branch: branch,
        semester: semester,
        academicYear: academicYear,
      );
      state = state.copyWith(status: CopoStatus.loaded, courses: list);
    } on Exception catch (e) {
      state = state.copyWith(
          status: CopoStatus.error, errorMessage: e.toString());
    }
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      final created = await _service.create(data);
      state = state.copyWith(courses: [...state.courses, created]);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> update(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _service.update(id, data);
      state = state.copyWith(
        courses: state.courses
            .map((c) => c.usercourseId == id ? updated : c)
            .toList(),
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _service.delete(id);
      state = state.copyWith(
          courses: state.courses.where((c) => c.usercourseId != id).toList());
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final copoProvider =
    StateNotifierProvider<CopoNotifier, CopoState>((ref) {
  return CopoNotifier(ref.watch(copoServiceProvider));
});

// ── Enrollment sub-state ────────────────────────────────────────────────────

class EnrollmentState {
  final bool loading;
  final List<CopoEnrollmentModel> enrollments;
  final String? error;

  const EnrollmentState({
    this.loading = false,
    this.enrollments = const [],
    this.error,
  });

  EnrollmentState copyWith({
    bool? loading,
    List<CopoEnrollmentModel>? enrollments,
    String? error,
  }) =>
      EnrollmentState(
        loading: loading ?? this.loading,
        enrollments: enrollments ?? this.enrollments,
        error: error,
      );
}

class EnrollmentNotifier extends StateNotifier<EnrollmentState> {
  final CopoService _service;
  final int usercourseId;

  EnrollmentNotifier(this._service, this.usercourseId)
      : super(const EnrollmentState());

  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      final list = await _service.fetchUsers(usercourseId);
      state = state.copyWith(loading: false, enrollments: list);
    } on Exception catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> addUsers(List<int> userIds) async {
    try {
      await _service.addUsers(usercourseId, userIds);
      await load();
      return true;
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> removeUser(int userId) async {
    try {
      await _service.removeUser(usercourseId, userId);
      state = state.copyWith(
        enrollments:
            state.enrollments.where((e) => e.userId != userId).toList(),
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final enrollmentProvider = StateNotifierProvider.family<EnrollmentNotifier,
    EnrollmentState, int>((ref, usercourseId) {
  return EnrollmentNotifier(ref.watch(copoServiceProvider), usercourseId);
});
