import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> initializeAndGetToken() async {
    if (Platform.isIOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      if (kDebugMode) {
        print('FCM authorization status: ${settings.authorizationStatus}');
      }
    }

    // Android 13+ does runtime permission internally
    final token = await _messaging.getToken();
    if (kDebugMode) {
        print('FCM token: $token');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('FCM foreground message: ${message.messageId}');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('FCM opened app from notification: ${message.messageId}');
      }
    });

    return token;
  }
}


