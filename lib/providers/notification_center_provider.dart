import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notification_item.dart';
import '../services/notification_service.dart';

enum NotificationCenterStatus { initial, loading, loaded, error }

class NotificationCenterState {
  final NotificationCenterStatus status;
  final List<AppNotificationItem> items;
  final String? errorMessage;

  const NotificationCenterState({
    this.status = NotificationCenterStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  int get unreadCount => items.where((e) => !e.isRead).length;

  NotificationCenterState copyWith({
    NotificationCenterStatus? status,
    List<AppNotificationItem>? items,
    String? errorMessage,
  }) {
    return NotificationCenterState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }
}

class NotificationCenterNotifier extends StateNotifier<NotificationCenterState> {
  final NotificationService _notificationService;
  StreamSubscription<AppNotificationItem>? _incomingSub;

  NotificationCenterNotifier(this._notificationService)
      : super(const NotificationCenterState()) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    state = state.copyWith(status: NotificationCenterStatus.loading);
    try {
      final inbox = await _notificationService.getInbox();
      state = state.copyWith(
        status: NotificationCenterStatus.loaded,
        items: inbox,
      );

      _incomingSub = _notificationService.incomingNotifications.listen((item) {
        final next = [
          item,
          ...state.items.where((existing) => existing.id != item.id),
        ];
        state = state.copyWith(items: next);
      });
    } catch (e) {
      state = state.copyWith(
        status: NotificationCenterStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    try {
      final inbox = await _notificationService.getInbox();
      state = state.copyWith(
        status: NotificationCenterStatus.loaded,
        items: inbox,
      );
    } catch (e) {
      state = state.copyWith(
        status: NotificationCenterStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> markAsRead(String id) async {
    final next = state.items.map((e) {
      if (e.id != id) return e;
      return e.copyWith(isRead: true);
    }).toList(growable: false);
    state = state.copyWith(items: next);
    await _notificationService.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    final next = state.items.map((e) => e.copyWith(isRead: true)).toList(growable: false);
    state = state.copyWith(items: next);
    await _notificationService.markAllAsRead();
  }

  Future<void> clearAll() async {
    state = state.copyWith(items: const []);
    await _notificationService.clearInbox();
  }

  @override
  void dispose() {
    _incomingSub?.cancel();
    super.dispose();
  }
}

final notificationCenterProvider =
    StateNotifierProvider<NotificationCenterNotifier, NotificationCenterState>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return NotificationCenterNotifier(notificationService);
});
