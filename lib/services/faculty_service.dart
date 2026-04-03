import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/faculty_model.dart';

class FacultyService {
  final ApiClient _apiClient;

  FacultyService(this._apiClient);

  Future<List<FacultyModel>> fetchAllFaculty({
    int? branchId,
    int? departId,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.faculty,
      queryParameters: {
        if (branchId != null) 'branchId': branchId,
        if (departId != null) 'departId': departId,
      },
    );
    final body = response.data as Map<String, dynamic>;
    final raw = body['data'];
    final List<dynamic> list = raw is List ? raw : [];
    return list
        .map((e) => FacultyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FacultyModel> fetchFacultyById(int id) async {
    final response = await _apiClient.get('${ApiEndpoints.facultyById}/$id');
    final body = response.data as Map<String, dynamic>;
    return FacultyModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Returns a map with keys: 'faculty' (FacultyModel) and 'credentials' (Map?) if new login was created.
  Future<Map<String, dynamic>> createFaculty(Map<String, dynamic> facultyData) async {
    final response = await _apiClient.post(
      ApiEndpoints.faculty,
      data: facultyData,
    );
    final body = response.data as Map<String, dynamic>;
    final faculty = FacultyModel.fromJson(body['data'] as Map<String, dynamic>);
    final credentials = body['credentials'] as Map<String, dynamic>?;
    return {'faculty': faculty, 'credentials': credentials};
  }

  Future<FacultyModel> updateFaculty(int id, Map<String, dynamic> updates) async {
    final response = await _apiClient.put(
      '${ApiEndpoints.facultyById}/$id',
      data: updates,
    );
    final body = response.data as Map<String, dynamic>;
    return FacultyModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteFaculty(int id) async {
    await _apiClient.delete('${ApiEndpoints.facultyById}/$id');
  }
}

final facultyServiceProvider = Provider<FacultyService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FacultyService(apiClient);
});
