import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/room_model.dart';

class RoomService {
  final ApiClient _apiClient;

  RoomService(this._apiClient);

  Future<List<RoomModel>> fetchAllRooms({int? branchId}) async {
    final response = await _apiClient.get(
      ApiEndpoints.rooms,
      queryParameters: {
        if (branchId != null) 'branch_id': branchId,
      },
    );
    final body = response.data as Map<String, dynamic>;
    final raw = body['data'];
    final List<dynamic> list = raw is List ? raw : [];
    return list
        .map((e) => RoomModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RoomModel> createRoom(Map<String, dynamic> data) async {
    final response = await _apiClient.post(ApiEndpoints.rooms, data: data);
    final body = response.data as Map<String, dynamic>;
    return RoomModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<RoomModel> updateRoom(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(
      '${ApiEndpoints.roomById}/$id',
      data: data,
    );
    final body = response.data as Map<String, dynamic>;
    return RoomModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteRoom(int id) async {
    await _apiClient.delete('${ApiEndpoints.roomById}/$id');
  }
}

final roomServiceProvider = Provider<RoomService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RoomService(apiClient);
});
