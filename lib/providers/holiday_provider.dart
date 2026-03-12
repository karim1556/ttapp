import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/holiday_model.dart';
import '../services/holiday_service.dart';
import '../services/storage_service.dart';

enum HolidayStatus { initial, loading, loaded, error }

class HolidayState {
  final HolidayStatus status;
  final List<HolidayModel> holidays;
  final String? errorMessage;

  const HolidayState({
    this.status = HolidayStatus.initial,
    this.holidays = const [],
    this.errorMessage,
  });

  HolidayState copyWith({
    HolidayStatus? status,
    List<HolidayModel>? holidays,
    String? errorMessage,
  }) {
    return HolidayState(
      status: status ?? this.status,
      holidays: holidays ?? this.holidays,
      errorMessage: errorMessage,
    );
  }

  List<HolidayModel> get upcomingHolidays {
    final now = DateTime.now();
    return holidays.where((h) => h.isUpcoming).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  HolidayModel? get todayHoliday {
    try {
      return holidays.firstWhere((h) => h.isToday);
    } catch (_) {
      return null;
    }
  }

  bool isHoliday(DateTime date) {
    return holidays.any((h) {
      final d = DateTime.tryParse(h.date);
      if (d == null) return false;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    });
  }
}

class HolidayNotifier extends StateNotifier<HolidayState> {
  final HolidayService _holidayService;
  final StorageService _storageService;

  HolidayNotifier(this._holidayService, this._storageService)
      : super(const HolidayState());

  Future<void> loadHolidays({String? year}) async {
    state = state.copyWith(status: HolidayStatus.loading);
    try {
      // Try cached first
      final cached = await _storageService.getHolidayCache();
      if (cached != null && cached.isNotEmpty) {
        final cachedHolidays = cached
            .map((e) => HolidayModel.fromJson(e))
            .toList();
        state = state.copyWith(
          status: HolidayStatus.loaded,
          holidays: cachedHolidays,
        );
      }

      final holidays = await _holidayService.fetchAllHolidays(year: year);

      await _storageService.saveHolidayCache(
        holidays.map((e) => e.toJson()).toList(),
      );

      state = state.copyWith(
        status: HolidayStatus.loaded,
        holidays: holidays,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: state.holidays.isEmpty
            ? HolidayStatus.error
            : HolidayStatus.loaded,
        errorMessage: e.toString(),
      );
    }
  }
}

final holidayProvider =
    StateNotifierProvider<HolidayNotifier, HolidayState>((ref) {
  final holidayService = ref.watch(holidayServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return HolidayNotifier(holidayService, storageService);
});

// Today's holiday convenience provider
final todayHolidayProvider = Provider<HolidayModel?>((ref) {
  return ref.watch(holidayProvider).todayHoliday;
});
