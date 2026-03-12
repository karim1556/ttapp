import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthService(this._apiClient, this._storageService);

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );

    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? body;
    final token = data['token']?.toString() ?? '';
    final userJson = data['user'] as Map<String, dynamic>? ?? data;
    final user = UserModel.fromJson(userJson).copyWith(token: token);

    await _storageService.saveToken(token);
    await _storageService.saveUserData(user.toJson());

    return user;
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore API error on logout; clear local data either way.
    } finally {
      await _storageService.clearAll();
    }
  }

  Future<UserModel?> getStoredUser() async {
    final userData = await _storageService.getUserData();
    if (userData == null) return null;
    final token = await _storageService.getToken();
    if (token == null || token.isEmpty) return null;
    return UserModel.fromJson(userData).copyWith(token: token);
  }

  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.profile);
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? body;
    return UserModel.fromJson(data);
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthService(apiClient, storageService);
});
