// This is an example file showing how to use Firebase Notifications in your app
// You can delete this file once you understand how to integrate notifications

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_notification_service.dart';

class NotificationExampleScreen extends StatefulWidget {
  const NotificationExampleScreen({super.key});

  @override
  State<NotificationExampleScreen> createState() => _NotificationExampleScreenState();
}

class _NotificationExampleScreenState extends State<NotificationExampleScreen> {
  String _fcmToken = 'Loading...';
  final List<String> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
    _setupNotificationHandling();
  }

  Future<void> _loadFCMToken() async {
    final token = FirebaseNotificationService().fcmToken;
    setState(() {
      _fcmToken = token ?? 'Token not available';
    });
  }

  void _setupNotificationHandling() {
    // Handle notification taps
    FirebaseNotificationService().onNotificationTapped = (RemoteMessage message) {
      setState(() {
        _notifications.add('Tapped: ${message.notification?.title ?? 'No title'}');
      });

      // Example: Navigate based on notification data
      if (message.data.containsKey('screen')) {
        final screen = message.data['screen'];
        // Navigate to specific screen
        debugPrint('Navigate to: $screen');
      }
    };
  }

  Future<void> _subscribeToTopic(String topic) async {
    await FirebaseNotificationService().subscribeToTopic(topic);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscribed to $topic')),
      );
    }
  }

  Future<void> _unsubscribeFromTopic(String topic) async {
    await FirebaseNotificationService().unsubscribeFromTopic(topic);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unsubscribed from $topic')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Notifications'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FCM Token Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FCM Token',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _fcmToken,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use this token to send test notifications from Firebase Console',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Topic Subscription Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Topic Subscriptions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Subscribe to topics to receive group notifications',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () => _subscribeToTopic('orders'),
                          child: const Text('Subscribe to Orders'),
                        ),
                        ElevatedButton(
                          onPressed: () => _unsubscribeFromTopic('orders'),
                          child: const Text('Unsubscribe from Orders'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () => _subscribeToTopic('promotions'),
                          child: const Text('Subscribe to Promotions'),
                        ),
                        ElevatedButton(
                          onPressed: () => _unsubscribeFromTopic('promotions'),
                          child: const Text('Unsubscribe from Promotions'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notification History
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_notifications.isEmpty)
                      const Text(
                        'No notifications tapped yet',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.notification_important),
                            title: Text(_notifications[index]),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Testing Notifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Copy the FCM token above\n'
                      '2. Go to Firebase Console > Cloud Messaging\n'
                      '3. Click "Send test message"\n'
                      '4. Paste the token and send\n'
                      '5. The notification should appear on your device',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Example: How to integrate into your existing screens
// Add this to your home screen or navigation:
/*
// In your home screen or settings screen
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationExampleScreen(),
      ),
    );
  },
  child: const Text('Notification Settings'),
),
*/

// Example: Handle notifications for specific features
/*
// In your MyOrdersScreen or wherever you want to handle order notifications:
@override
void initState() {
  super.initState();
  
  // Set up notification handler for order updates
  FirebaseNotificationService().onNotificationTapped = (RemoteMessage message) {
    if (message.data.containsKey('orderId')) {
      final orderId = message.data['orderId'];
      // Navigate to order detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(orderId: orderId),
        ),
      );
    }
  };
}
*/

// Example: Subscribe users to relevant topics after login
/*
// In your login success handler:
Future<void> _handleLoginSuccess() async {
  // ... your existing login code ...
  
  // Subscribe to user-specific topics
  await FirebaseNotificationService().subscribeToTopic('all_users');
  await FirebaseNotificationService().subscribeToTopic('orders_${userId}');
  
  // Navigate to home screen
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const MainNavigation()),
  );
}
*/

// Example: Send FCM token to your backend
/*
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendFCMTokenToBackend() async {
  final token = FirebaseNotificationService().fcmToken;
  if (token == null) return;
  
  try {
    final response = await http.post(
      Uri.parse('https://your-api.com/api/fcm-token'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'fcm_token': token,
        'device_type': Platform.isIOS ? 'ios' : 'android',
      }),
    );
    
    if (response.statusCode == 200) {
      print('FCM token sent to backend successfully');
    }
  } catch (e) {
    print('Error sending FCM token: $e');
  }
}
*/

