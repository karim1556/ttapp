import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/temporary_timetable_model.dart';

class TemporaryTimetableService {
  final ApiClient _apiClient;

  TemporaryTimetableService(this._apiClient);

  Future<List<TemporaryTimeSlot>> fetchTemporarySlots({
    int? branchId,
    int? semester,
    String? division,
    String? date,
    String? fromDate,
    String? toDate,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.temporaryTimetable,
      queryParameters: {
        if (branchId != null) 'branchId': branchId,
        if (semester != null) 'sem': semester,
        if (division != null) 'division': division,
        if (date != null) 'date': date,
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final rawList = data['data'] as List<dynamic>? ?? [];
    return rawList.map((e) => TemporaryTimeSlot.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createTemporarySlot(Map<String, dynamic> data) async {
    await _apiClient.post(
      ApiEndpoints.temporaryTimetable,
      data: data,
    );
  }

  Future<void> createBulkSlots(Map<String, dynamic> data) async {
    await _apiClient.post(
      ApiEndpoints.temporaryTimetableBulk,
      data: data,
    );
  }

  Future<void> generateTemporarySlot(Map<String, dynamic> data) async {
    await _apiClient.post(
      ApiEndpoints.temporaryTimetableGenerate,
      data: data,
    );
  }

  Future<void> updateTemporarySlot(int id, Map<String, dynamic> data) async {
    await _apiClient.put(
      '${ApiEndpoints.temporaryTimetable}/$id',
      data: data,
    );
  }

  Future<void> deleteTemporarySlot(int id) async {
    await _apiClient.delete(
      '${ApiEndpoints.temporaryTimetable}/$id',
    );
  }

  Future<Uint8List> downloadTemporaryPdf({
    int? branchId,
    int? semester,
    String? division,
    String? date,
    String? fromDate,
    String? toDate,
  }) async {
    final response = await _apiClient.get<List<int>>(
      ApiEndpoints.temporaryTimetablePdf,
      queryParameters: {
        if (branchId != null) 'branchId': branchId,
        if (semester != null) 'sem': semester,
        if (division != null) 'division': division,
        if (date != null) 'date': date,
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
      },
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(response.data!);
  }
}

final temporaryTimetableServiceProvider = Provider<TemporaryTimetableService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TemporaryTimetableService(apiClient);
});
