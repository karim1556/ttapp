import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../constants/storage_keys.dart';
import '../../services/storage_service.dart';

/// Reads the saved server URL from Hive (sync, box already open at startup).
/// Falls back to [AppConstants.baseUrl] if nothing is stored.
String getEffectiveBaseUrl() {
  try {
    final box = Hive.box<dynamic>(StorageKeys.settingsBox);
    final saved = box.get(StorageKeys.serverUrl) as String?;
    if (saved != null && saved.isNotEmpty) return saved;
  } catch (_) {}
  return AppConstants.baseUrl;
}

/// Notifier that exposes the current server URL and allows updating it.
class ServerUrlNotifier extends StateNotifier<String> {
  ServerUrlNotifier() : super(getEffectiveBaseUrl());

  Future<void> updateUrl(String newUrl) async {
    final box = Hive.box<dynamic>(StorageKeys.settingsBox);
    await box.put(StorageKeys.serverUrl, newUrl);
    state = newUrl;
  }
}

final serverUrlProvider =
    StateNotifierProvider<ServerUrlNotifier, String>((ref) {
  return ServerUrlNotifier();
});

class ApiClient {
  late final Dio _dio;
  final StorageService _storageService;

  ApiClient(this._storageService, {required String baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_storageService),
      _ErrorInterceptor(),
    ]);

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (object) => debugPrint('[DIO] $object'),
        ),
      );
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

class _AuthInterceptor extends Interceptor {
  final StorageService _storageService;

  _AuthInterceptor(this._storageService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _storageService.clearAll();
    }
    handler.next(err);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final message = _parseError(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: message,
        message: message,
      ),
    );
  }

  String _parseError(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your network.';
    }
    if (err.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please try again.';
    }
    if (err.response != null) {
      final data = err.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      switch (err.response?.statusCode) {
        case 400:
          return 'Bad request. Please check your input.';
        case 401:
          return 'Session expired. Please login again.';
        case 403:
          return 'You do not have permission to perform this action.';
        case 404:
          return 'Resource not found.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'An unexpected error occurred.';
      }
    }
    return err.message ?? 'An unexpected error occurred.';
  }
}

// Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final baseUrl = ref.watch(serverUrlProvider);
  return ApiClient(storageService, baseUrl: baseUrl);
});
