import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:yellow/app/app.dart';
import 'package:yellow/core/config/env.dart';
import 'package:yellow/core/config/app_config.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");

  // Manually show notification for background messages (if data-only)
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel_v5', // id
    'Notificaciones Importantes', // title
    description: 'Este canal se usa para notificaciones importantes.', // description
    importance: Importance.max,
    // sound: RawResourceAndroidNotificationSound('notification_sound'),
    playSound: true,
  );

  await localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Inspect created channels in background
  final List<AndroidNotificationChannel>? channels = await localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.getNotificationChannels();
  
  if (channels != null) {
    for (var c in channels) {
      print('Background Channel: ${c.id}, Sound: ${c.sound?.sound}');
    }
  }

  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  // If it's a data message, we might want to show a notification based on data
  // But if it has a notification payload, the system handles it.
  // However, user logs show "Message data: {}" for foreground, so maybe it's a notification message?
  // If it's a notification message, the system SHOULD handle it.
  // But let's add logic to show it manually if needed, or at least log more info.
  
  if (notification != null && android != null) {
      // System handles this automatically for background messages usually.
      // But if we want to force our sound channel:
      // Actually, for notification messages, the "channel_id" field in the payload MUST match.
      // If the payload doesn't have "channel_id", it uses the default from AndroidManifest.
      // We updated AndroidManifest to use 'high_importance_channel_v2'.
      // So it SHOULD work.
      
      // Let's just log for now to confirm payload.
      print("Background Notification: ${notification.title}, ${notification.body}");
      print("Incoming Android Sound: ${android.sound}");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Load Environment variables
  final env = await Env.load();
  final appConfig = AppConfig(env: env);
  
  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(appConfig),
      ],
      child: const App(),
    ),
  );
}
