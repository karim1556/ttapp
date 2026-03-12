import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_model.dart';
import '../services/subject_service.dart';

enum SubjectStatus { initial, loading, loaded, error }

class SubjectState {
  final SubjectStatus status;
  final List<SubjectModel> subjects;
  final String? errorMessage;

  const SubjectState({
    this.status = SubjectStatus.initial,
    this.subjects = const [],
    this.errorMessage,
  });

  SubjectState copyWith({
    SubjectStatus? status,
    List<SubjectModel>? subjects,
    String? errorMessage,
  }) {
    return SubjectState(
      status: status ?? this.status,
      subjects: subjects ?? this.subjects,
      errorMessage: errorMessage,
    );
  }
}

class SubjectNotifier extends StateNotifier<SubjectState> {
  final SubjectService _subjectService;

  SubjectNotifier(this._subjectService) : super(const SubjectState());

  Future<void> loadSubjects({
    int? branchId,
    int? semester,
    String? acadYear,
  }) async {
    state = state.copyWith(status: SubjectStatus.loading);
    try {
      final list = await _subjectService.fetchAllSubjects(
        branchId: branchId,
        semester: semester,
        acadYear: acadYear,
      );
      state = state.copyWith(status: SubjectStatus.loaded, subjects: list);
    } on Exception catch (e) {
      state = state.copyWith(
        status: SubjectStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> createSubject(Map<String, dynamic> data) async {
    try {
      final created = await _subjectService.createSubject(data);
      state = state.copyWith(subjects: [...state.subjects, created]);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateSubject(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _subjectService.updateSubject(id, data);
      final newList = state.subjects
          .map((s) => s.id == id ? updated : s)
          .toList();
      state = state.copyWith(subjects: newList);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteSubject(int id) async {
    try {
      await _subjectService.deleteSubject(id);
      state = state.copyWith(
        subjects: state.subjects.where((s) => s.id != id).toList(),
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final subjectProvider =
    StateNotifierProvider<SubjectNotifier, SubjectState>((ref) {
  final subjectService = ref.watch(subjectServiceProvider);
  return SubjectNotifier(subjectService);
});
