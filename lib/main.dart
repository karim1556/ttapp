import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/storage_keys.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (optional — skip if not configured yet)
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (_) {
    // Firebase not configured — app will run without push notifications
  }

  // Initialize Hive
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox<dynamic>(StorageKeys.userBox),
    Hive.openBox<dynamic>(StorageKeys.timetableBox),
    Hive.openBox<dynamic>(StorageKeys.settingsBox),
  ]);

  runApp(
    const ProviderScope(
      child: TtApp(),
    ),
  );
}

class TtApp extends ConsumerWidget {
  const TtApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Initialize notification service once
    ref.watch(notificationServiceProvider);

    return MaterialApp.router(
      title: 'TT App',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

