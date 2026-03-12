import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/constraint_model.dart';

class ConstraintService {
  final ApiClient _apiClient;

  ConstraintService(this._apiClient);

  Future<ConstraintModel?> fetchMyConstraints(int facultyId) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.constraintsByFaculty}/$facultyId',
    );
    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    if (data == null) return null;
    return ConstraintModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ConstraintModel> saveConstraints(ConstraintModel constraint) async {
    if (constraint.id != null) {
      final response = await _apiClient.put(
        '${ApiEndpoints.constraints}/${constraint.id}',
        data: constraint.toJson(),
      );
      final body = response.data as Map<String, dynamic>;
      return ConstraintModel.fromJson(body['data'] as Map<String, dynamic>);
    } else {
      final response = await _apiClient.post(
        ApiEndpoints.constraints,
        data: constraint.toJson(),
      );
      final body = response.data as Map<String, dynamic>;
      return ConstraintModel.fromJson(body['data'] as Map<String, dynamic>);
    }
  }
}

final constraintServiceProvider = Provider<ConstraintService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ConstraintService(apiClient);
});
