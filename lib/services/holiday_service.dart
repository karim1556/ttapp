import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/holiday_model.dart';

class HolidayService {
  final ApiClient _apiClient;

  HolidayService(this._apiClient);

  Future<List<HolidayModel>> fetchAllHolidays({String? year}) async {
    final response = await _apiClient.get(
      ApiEndpoints.holidays,
      queryParameters: {
        if (year != null) 'year': year,
      },
    );
    final body = response.data as Map<String, dynamic>;
    final raw = body['data'];
    final List<dynamic> list = raw is List ? raw : [];
    return list
        .map((e) => HolidayModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<HolidayModel>> fetchUpcomingHolidays({int limit = 10}) async {
    final response = await _apiClient.get(
      ApiEndpoints.upcomingHolidays,
      queryParameters: {'limit': limit},
    );
    final body = response.data as Map<String, dynamic>;
    final raw = body['data'];
    final List<dynamic> list = raw is List ? raw : [];
    return list
        .map((e) => HolidayModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Check if a given DateTime is a holiday.
  /// Matches against the cached/fetched holiday list.
  bool isHoliday(DateTime date, List<HolidayModel> holidays) {
    return holidays.any((h) {
      final d = DateTime.tryParse(h.date);
      if (d == null) return false;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    });
  }

  HolidayModel? getHolidayForDate(DateTime date, List<HolidayModel> holidays) {
    try {
      return holidays.firstWhere((h) {
        final d = DateTime.tryParse(h.date);
        if (d == null) return false;
        return d.year == date.year && d.month == date.month && d.day == date.day;
      });
    } catch (_) {
      return null;
    }
  }
}

final holidayServiceProvider = Provider<HolidayService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HolidayService(apiClient);
});
