import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widget_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    final data = message.data;
    if (data.containsKey('imageUrl')) {
      final imageUrl = data['imageUrl'] as String? ?? '';
      final caption = data['caption'] as String? ?? '';
      final posterName = data['postedByName'] as String? ?? 'Partner';
      await WidgetService.updateWidget(
        imageUrl: imageUrl,
        caption: caption,
        posterName: posterName,
      );
    }
  } catch (e) {
    debugPrint('Background message widget update error: $e');
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    if (kIsWeb) return;

    // Request permissions
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Local notifications setup
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // Notification channel
    const channel = AndroidNotificationChannel(
      'petals_channel',
      'Petals Moments',
      description: 'Notifications for new shared moments',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  static Future<void> saveFcmToken(String uid) async {
    if (kIsWeb) return;
    final token = await _fcm.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'petals_channel',
            'Petals Messages',
            channelDescription: 'Notifications for new chat messages and love notes',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  static void _showLocalNotification(RemoteMessage message) {
    if (kIsWeb) return;
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'petals_channel',
          'Petals Moments',
          channelDescription: 'Notifications for new shared moments',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
      ),
    );
  }
}

