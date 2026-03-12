import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/copo_model.dart';

class CopoService {
  final ApiClient _api;
  CopoService(this._api);

  // ── Course mappings ──────────────────────────────────────────────────────

  Future<List<CopoUserCourseModel>> fetchAll({
    int? branch,
    int? semester,
    String? academicYear,
  }) async {
    final response = await _api.get(
      ApiEndpoints.copo,
      queryParameters: {
        if (branch != null)       'branch':        branch,
        if (semester != null)     'semester':      semester,
        if (academicYear != null) 'academic_year': academicYear,
      },
    );
    final body = response.data as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => CopoUserCourseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CopoUserCourseModel> create(Map<String, dynamic> data) async {
    final response = await _api.post(ApiEndpoints.copo, data: data);
    final body = response.data as Map<String, dynamic>;
    return CopoUserCourseModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<CopoUserCourseModel> update(int id, Map<String, dynamic> data) async {
    final response = await _api.put('${ApiEndpoints.copo}/$id', data: data);
    final body = response.data as Map<String, dynamic>;
    return CopoUserCourseModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _api.delete('${ApiEndpoints.copo}/$id');
  }

  // ── Enrollments ──────────────────────────────────────────────────────────

  Future<List<CopoEnrollmentModel>> fetchUsers(int usercourseId) async {
    final response = await _api.get('${ApiEndpoints.copo}/$usercourseId/users');
    final body = response.data as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => CopoEnrollmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addUsers(int usercourseId, List<int> userIds) async {
    await _api.post(
      '${ApiEndpoints.copo}/$usercourseId/users',
      data: {'user_ids': userIds},
    );
  }

  Future<void> removeUser(int usercourseId, int userId) async {
    await _api.delete('${ApiEndpoints.copo}/$usercourseId/users/$userId');
  }
}

final copoServiceProvider = Provider<CopoService>((ref) {
  return CopoService(ref.watch(apiClientProvider));
});
