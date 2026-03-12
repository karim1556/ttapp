import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/subject_model.dart';

class SubjectService {
  final ApiClient _apiClient;

  SubjectService(this._apiClient);

  Future<List<SubjectModel>> fetchAllSubjects({
    int? branchId,
    int? semester,
    String? acadYear,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.subjects,
      queryParameters: {
        if (branchId != null) 'branch_id': branchId,
        if (semester != null) 'semester': semester,
        if (acadYear != null) 'acad_year': acadYear,
      },
    );
    final body = response.data as Map<String, dynamic>;
    final raw = body['data'];
    final List<dynamic> list = raw is List ? raw : [];
    return list
        .map((e) => SubjectModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SubjectModel> fetchSubjectById(int id) async {
    final response = await _apiClient.get('${ApiEndpoints.subjectById}/$id');
    final body = response.data as Map<String, dynamic>;
    return SubjectModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<SubjectModel> createSubject(Map<String, dynamic> subjectData) async {
    final response = await _apiClient.post(
      ApiEndpoints.subjects,
      data: subjectData,
    );
    final body = response.data as Map<String, dynamic>;
    return SubjectModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<SubjectModel> updateSubject(int id, Map<String, dynamic> updates) async {
    final response = await _apiClient.put(
      '${ApiEndpoints.subjectById}/$id',
      data: updates,
    );
    final body = response.data as Map<String, dynamic>;
    return SubjectModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteSubject(int id) async {
    await _apiClient.delete('${ApiEndpoints.subjectById}/$id');
  }
}

final subjectServiceProvider = Provider<SubjectService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SubjectService(apiClient);
});
