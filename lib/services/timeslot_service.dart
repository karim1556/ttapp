import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/timeslot_template_model.dart';

class TimeslotService {
  final ApiClient _apiClient;

  TimeslotService(this._apiClient);

  Future<List<TimeSlotTemplateModel>> fetchAllTimeslots() async {
    final response = await _apiClient.get(ApiEndpoints.timeslotTemplates);
    final body = response.data as Map<String, dynamic>;
    final raw = body['data'];
    final List<dynamic> list = raw is List ? raw : [];
    return list
        .map((e) => TimeSlotTemplateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TimeSlotTemplateModel> createTimeslot(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ApiEndpoints.timeslotTemplates,
      data: data,
    );
    final body = response.data as Map<String, dynamic>;
    return TimeSlotTemplateModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<TimeSlotTemplateModel> updateTimeslot(
      int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(
      '${ApiEndpoints.timeslotTemplateById}/$id',
      data: data,
    );
    final body = response.data as Map<String, dynamic>;
    return TimeSlotTemplateModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteTimeslot(int id) async {
    await _apiClient.delete('${ApiEndpoints.timeslotTemplateById}/$id');
  }
}

final timeslotServiceProvider = Provider<TimeslotService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TimeslotService(apiClient);
});
