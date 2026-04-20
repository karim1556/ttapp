import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
  show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/app_notification_item.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

/// Handle background messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handling
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final StorageService _storageService;
  final ApiClient _apiClient;

  bool _initialized = false;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;
  StreamSubscription<String>? _tokenRefreshSub;
  int? _registeredUserId;

  final StreamController<AppNotificationItem> _incomingController =
      StreamController<AppNotificationItem>.broadcast();

  NotificationService(this._storageService, this._apiClient);

  Stream<AppNotificationItem> get incomingNotifications =>
      _incomingController.stream;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    try {
      await _requestPermissions();
      await _initializeLocalNotifications();
      _listenToForegroundMessages();
      _listenToNotificationOpens();
      await _captureInitialNotificationOpen();
      _initialized = true;
    } catch (_) {
      // Firebase not configured — skip notifications
    }
  }

  Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (!kIsWeb) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'ttapp_high_importance',
      'TT Manager Notifications',
      description: 'Notifications for lecture reminders and substitutions',
      importance: Importance.max,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _listenToForegroundMessages() {
    _foregroundMessageSub ??= FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        final notification = message.notification;
        final title =
            notification?.title ?? message.data['title']?.toString() ?? 'TT Manager';
        final body =
            notification?.body ?? message.data['body']?.toString() ?? 'New update available.';
        final payload = message.data.isEmpty ? null : jsonEncode(message.data);

        final inboxItem = AppNotificationItem(
          id: message.messageId ?? 'push_${DateTime.now().microsecondsSinceEpoch}',
          title: title,
          body: body,
          payload: payload,
          source: 'push',
          receivedAt: DateTime.now().toIso8601String(),
        );

        await _appendInboxItem(inboxItem);

        await _showLocalNotification(
          id: message.hashCode,
          title: title,
          body: body,
          payload: payload,
        );
      },
    );
  }

  void _listenToNotificationOpens() {
    _openedAppSub ??= FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) async {
        final title = message.notification?.title ?? 'TT Manager';
        final body = message.notification?.body ?? 'Notification opened';
        final payload = message.data.isEmpty ? null : jsonEncode(message.data);

        final inboxItem = AppNotificationItem(
          id: 'open_${message.messageId ?? DateTime.now().microsecondsSinceEpoch}',
          title: title,
          body: body,
          payload: payload,
          source: 'push',
          receivedAt: DateTime.now().toIso8601String(),
          isRead: true,
        );
        await _appendInboxItem(inboxItem);
      },
    );
  }

  Future<void> _captureInitialNotificationOpen() async {
    final initial = await _firebaseMessaging.getInitialMessage();
    if (initial == null) return;

    final title = initial.notification?.title ?? 'TT Manager';
    final body = initial.notification?.body ?? 'Notification opened';
    final payload = initial.data.isEmpty ? null : jsonEncode(initial.data);
    final item = AppNotificationItem(
      id: 'initial_${initial.messageId ?? DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      payload: payload,
      source: 'push',
      receivedAt: DateTime.now().toIso8601String(),
      isRead: true,
    );
    await _appendInboxItem(item);
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ttapp_high_importance',
      'TT Manager Notifications',
      channelDescription: 'Notifications for lecture reminders and substitutions',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      ticker: 'TT Manager alert',
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation on notification tap if needed
  }

  Future<void> registerDeviceForUser(UserModel user) async {
    if (kIsWeb) return;
    if (_registeredUserId == user.uid) return;
    await initialize();

    final token = await getFcmToken();
    if (token == null || token.isEmpty) return;

    try {
      await _storageService.saveFcmToken(token);
    } catch (_) {}

    try {
      await _apiClient.post(
        ApiEndpoints.saveFcmToken,
        data: {
          'token': token,
          'uid': user.uid,
          'userType': user.userType,
          'platform': _platformLabel(),
        },
      );
    } catch (_) {}

    try {
      await _firebaseMessaging.subscribeToTopic('ttapp_all');
      await _firebaseMessaging.subscribeToTopic('user_${user.uid}');
      await _firebaseMessaging.subscribeToTopic(_roleTopic(user.userType));
    } catch (_) {}

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      try {
        await _storageService.saveFcmToken(newToken);
      } catch (_) {}

      try {
        await _apiClient.post(
          ApiEndpoints.saveFcmToken,
          data: {
            'token': newToken,
            'uid': user.uid,
            'userType': user.userType,
            'platform': _platformLabel(),
          },
        );
      } catch (_) {}
    });

    _registeredUserId = user.uid;
  }

  Future<List<AppNotificationItem>> getInbox() async {
    final raw = await _storageService.getNotificationInbox();
    final list = (raw ?? const <Map<String, dynamic>>[])
        .map(AppNotificationItem.fromJson)
        .toList();
    list.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return list;
  }

  Future<void> markAsRead(String id) async {
    final inbox = await getInbox();
    final updated = inbox.map((item) {
      if (item.id != id) return item;
      return item.copyWith(isRead: true);
    }).toList(growable: false);

    await _storageService.saveNotificationInbox(
      updated.map((e) => e.toJson()).toList(growable: false),
    );
  }

  Future<void> markAllAsRead() async {
    final inbox = await getInbox();
    final updated = inbox
        .map((item) => item.copyWith(isRead: true))
        .toList(growable: false);

    await _storageService.saveNotificationInbox(
      updated.map((e) => e.toJson()).toList(growable: false),
    );
  }

  Future<void> clearInbox() async {
    await _storageService.saveNotificationInbox(const []);
  }

  Future<void> pushInAppNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final payload = data == null || data.isEmpty ? null : jsonEncode(data);
    final item = AppNotificationItem(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      payload: payload,
      source: 'local',
      receivedAt: DateTime.now().toIso8601String(),
    );

    await _appendInboxItem(item);

    if (!kIsWeb) {
      await _showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
        title: title,
        body: body,
        payload: payload,
      );
    }
  }

  Future<void> _appendInboxItem(AppNotificationItem item) async {
    final inbox = await getInbox();
    final updated = <AppNotificationItem>[
      item,
      ...inbox.where((existing) => existing.id != item.id),
    ];

    final capped = updated.take(200).toList(growable: false);
    await _storageService.saveNotificationInbox(
      capped.map((e) => e.toJson()).toList(growable: false),
    );
    _incomingController.add(item);
  }

  String _platformLabel() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  String _roleTopic(int userType) {
    switch (userType) {
      case 1:
        return 'role_admin';
      case 2:
        return 'role_faculty';
      case 3:
        return 'role_student';
      default:
        return 'role_unknown';
    }
  }

  Future<String?> getFcmToken() async {
    if (kIsWeb) return null;
    try {
      return await _firebaseMessaging.getToken();
    } catch (_) {
      return null;
    }
  }

  void onTokenRefresh(void Function(String) callback) {
    _firebaseMessaging.onTokenRefresh.listen(callback);
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  final service = NotificationService(storageService, apiClient);
  service.initialize();
  return service;
});
