import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/holiday_model.dart';

class HolidayService {
  final ApiClient _apiClient;

  HolidayService(this._apiClient);

  List<HolidayModel> _normalizeAndSort(List<dynamic> raw) {
    final parsed = raw
        .whereType<Map>()
        .map((e) => HolidayModel.fromJson(Map<String, dynamic>.from(e)))
        .where((h) => h.parsedDate != null)
        .toList();

    parsed.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return parsed;
  }

  Future<List<HolidayModel>> fetchAllHolidays({String? year}) async {
    final queryParameters = <String, dynamic>{};
    if (year != null && year.isNotEmpty) {
      queryParameters['acadYear'] = year;
    }

    final response = await _apiClient.get(
      ApiEndpoints.holidays,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    final body = response.data as Map<String, dynamic>;
    final raw = body['data'];
    final List<dynamic> list = raw is List ? raw : [];
    return _normalizeAndSort(list);
  }

  Future<List<HolidayModel>> fetchUpcomingHolidays({int limit = 10}) async {
    final response = await _apiClient.get(
      ApiEndpoints.upcomingHolidays,
      queryParameters: {'limit': limit},
    );
    final body = response.data as Map<String, dynamic>;
    final raw = body['data'];
    final List<dynamic> list = raw is List ? raw : [];
    return _normalizeAndSort(list);
  }

  /// Check if a given DateTime is a holiday.
  /// Matches against the cached/fetched holiday list.
  bool isHoliday(DateTime date, List<HolidayModel> holidays) {
    final target = DateTime(date.year, date.month, date.day);
    return holidays.any((h) {
      final d = h.parsedDate;
      if (d == null) return false;
      return d.year == target.year &&
          d.month == target.month &&
          d.day == target.day;
    });
  }

  HolidayModel? getHolidayForDate(DateTime date, List<HolidayModel> holidays) {
    final target = DateTime(date.year, date.month, date.day);
    try {
      return holidays.firstWhere((h) {
        final d = h.parsedDate;
        if (d == null) return false;
        return d.year == target.year &&
            d.month == target.month &&
            d.day == target.day;
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
