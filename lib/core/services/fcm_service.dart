import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Define the channel with custom sound
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel_v4', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('notification_sound'),
    playSound: true,
  );

  Future<void> initialize() async {
    // Request permission for iOS/Web
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Note: iOS permissions are handled by FirebaseMessaging, but we need init settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(initializationSettings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Inspect created channels
    final List<AndroidNotificationChannel>? channels = await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.getNotificationChannels();
    
    if (channels != null) {
      for (var channel in channels) {
        debugPrint('Channel: ${channel.id}, Name: ${channel.name}, Importance: ${channel.importance}, Sound: ${channel.sound?.sound}');
      }
    }

    // Foreground message handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // If `onMessage` is triggered with a notification, construct our own
      // local notification to show to users using the created channel.
      debugPrint('Notification: ${notification?.title}, ${notification?.body}');
      debugPrint('Android: ${android?.smallIcon}');
      
      if (notification != null && android != null) {
        debugPrint('Showing local notification...');
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android.smallIcon,
              sound: const RawResourceAndroidNotificationSound('notification_sound'),
              playSound: true,
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: '${message.data['trip_id']}', 
        );
      }
    });

    // Handle Local Notification Tap
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // ... iOS settings ...
  }

  // Setup interaction handlers (Call this from main/app after router is ready)
  void setupInteractedMessage(GoRouter router) async {
    // 1. Terminated State
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage, router);
    }

    // 2. Background State
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message, router);
    });

    // 3. Local Notification Tap (Foreground/Background)
    _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
            debugPrint('Local Notification Payload: ${response.payload}');
            // Assuming payload is trip_id
            router.go('/dashboard/trip-tracking/${response.payload}');
        }
      },
    );
  }

  void _handleMessage(RemoteMessage message, GoRouter router) {
    debugPrint("Handling Interacted Message: ${message.data}");
    if (message.data['trip_id'] != null) {
      router.go('/dashboard/trip-tracking/${message.data['trip_id']}');
    }
  }

  Future<String?> getToken() async {
    try {
      String? token = await _messaging.getToken();
      debugPrint("FCM Token: $token");
      return token;
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
      return null;
    }
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
