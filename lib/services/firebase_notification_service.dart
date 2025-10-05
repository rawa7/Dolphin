import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'storage_service.dart';
import 'api_service.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification?.title}');
  }
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  String? _fcmToken;
  String? _deviceId;
  String? get fcmToken => _fcmToken;
  String? get deviceId => _deviceId;
  
  // Callback for when a notification is tapped
  Function(RemoteMessage)? onNotificationTapped;
  
  // Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      if (kDebugMode) {
        print('User granted permission: ${settings.authorizationStatus}');
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get device ID
      await _getDeviceId();

      // Get the FCM token
      await _getFCMToken();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (kDebugMode) {
          print('FCM Token refreshed: $newToken');
        }
        // Save the new token to backend
        _saveTokenToBackend(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if the app was opened from a terminated state via notification
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      if (kDebugMode) {
        print('Firebase Messaging initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase Messaging: $e');
      }
    }
  }

  // Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          print('Notification tapped: ${response.payload}');
        }
        // Handle notification tap from local notification
      },
    );

    // Create an Android notification channel for high priority notifications
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Get device ID
  Future<void> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceId = androidInfo.id; // This is the Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor; // iOS Vendor ID
      }
      if (kDebugMode) {
        print('Device ID: $_deviceId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting device ID: $e');
      }
    }
  }

  // Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $_fcmToken');
      }
      // Save token to backend
      if (_fcmToken != null) {
        await _saveTokenToBackend(_fcmToken!);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  // Save FCM token to backend
  Future<void> _saveTokenToBackend(String token) async {
    try {
      // Get current user
      final user = await StorageService.getUser();
      if (user == null) {
        if (kDebugMode) {
          print('No user found, skipping token save');
        }
        return;
      }

      // Determine platform
      String platform = 'unknown';
      if (Platform.isAndroid) {
        platform = 'android';
      } else if (Platform.isIOS) {
        platform = 'ios';
      }

      // Save token to backend
      final result = await ApiService.saveFCMToken(
        token: token,
        customerId: user.id.toString(),
        platform: platform,
        deviceId: _deviceId,
      );

      if (kDebugMode) {
        if (result['success']) {
          print('FCM token saved to backend successfully');
        } else {
          print('Failed to save FCM token: ${result['message']}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving token to backend: $e');
      }
    }
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Received foreground message: ${message.messageId}');
      print('Message data: ${message.data}');
      print('Message notification: ${message.notification?.title}');
    }

    // Show local notification when app is in foreground
    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification tapped: ${message.data}');
    }
    
    if (onNotificationTapped != null) {
      onNotificationTapped!(message);
    }
  }

  // Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic: $e');
      }
    }
  }

  // Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic: $e');
      }
    }
  }

  // Public method to save token to backend (call after login)
  Future<bool> saveTokenToBackend() async {
    if (_fcmToken == null) {
      if (kDebugMode) {
        print('No FCM token available to save');
      }
      return false;
    }
    await _saveTokenToBackend(_fcmToken!);
    return true;
  }

  // Delete FCM token from backend and Firebase
  Future<void> deleteTokenFromBackend() async {
    try {
      // Get current user
      final user = await StorageService.getUser();
      
      // Delete from backend
      final result = await ApiService.deleteFCMToken(
        token: _fcmToken,
        customerId: user?.id.toString(),
        deviceId: _deviceId,
      );

      if (kDebugMode) {
        if (result['success']) {
          print('FCM token deleted from backend successfully');
        } else {
          print('Failed to delete FCM token: ${result['message']}');
        }
      }

      // Delete local token from Firebase
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      
      if (kDebugMode) {
        print('FCM token deleted from device');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting token: $e');
      }
    }
  }

  // Delete FCM token (legacy method - kept for compatibility)
  Future<void> deleteToken() async {
    await deleteTokenFromBackend();
  }
}

