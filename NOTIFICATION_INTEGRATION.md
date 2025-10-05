# Quick Notification Integration Guide

## ✅ What's Been Implemented

### 1. Core Implementation
- ✅ Firebase Core and Firebase Messaging dependencies added
- ✅ Flutter Local Notifications for foreground notifications
- ✅ Complete Firebase Notification Service
- ✅ Android manifest configured with permissions
- ✅ iOS Info.plist and AppDelegate configured
- ✅ Background message handler set up
- ✅ Firebase initialized in main.dart

### 2. Features Available
- ✅ Automatic FCM token generation
- ✅ Foreground notification display
- ✅ Background notification handling
- ✅ Notification tap handling
- ✅ Topic subscription/unsubscription
- ✅ Token refresh handling

## 🔧 Next Steps - Firebase Configuration

### Required Files (Download from Firebase Console)

1. **Android**: `google-services.json`
   - Location: `android/app/google-services.json`
   - Get from: Firebase Console > Project Settings > Your Android app

2. **iOS**: `GoogleService-Info.plist`
   - Location: `ios/Runner/GoogleService-Info.plist` (add via Xcode)
   - Get from: Firebase Console > Project Settings > Your iOS app

### Gradle Configuration Needed

Add to `android/build.gradle.kts`:
```kotlin
plugins {
    // ... existing plugins ...
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

Add to `android/app/build.gradle.kts`:
```kotlin
plugins {
    // ... existing plugins ...
    id("com.google.gms.google-services")
}
```

## 📱 How to Integrate with Your Screens

### Example 1: Handle Order Notifications in MyOrdersScreen

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/firebase_notification_service.dart';

class MyOrdersScreen extends StatefulWidget {
  // ... your existing code ...
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    _setupNotifications();
    // ... your existing initState code ...
  }

  void _setupNotifications() {
    FirebaseNotificationService().onNotificationTapped = (RemoteMessage message) {
      // Check if this is an order notification
      if (message.data.containsKey('type') && message.data['type'] == 'order_update') {
        final orderId = message.data['orderId'];
        if (orderId != null) {
          // Navigate to order detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(orderId: orderId),
            ),
          );
        }
      }
    };
  }
  
  // ... rest of your code ...
}
```

### Example 2: Subscribe to Topics After Login

Add to your `LoginScreen` after successful login:

```dart
Future<void> _handleLogin() async {
  // ... your existing login code ...
  
  if (loginSuccessful) {
    // Subscribe to notification topics
    await FirebaseNotificationService().subscribeToTopic('all_users');
    await FirebaseNotificationService().subscribeToTopic('order_updates');
    
    // Navigate to main screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }
}
```

### Example 3: Send FCM Token to Your Backend

Add this to your API service:

```dart
// In api_service.dart
Future<void> sendFCMToken(String token) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/fcm-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await StorageService.getToken()}',
      },
      body: json.encode({
        'fcm_token': token,
        'device_type': Platform.isIOS ? 'ios' : 'android',
      }),
    );
    
    if (response.statusCode == 200) {
      print('FCM token sent successfully');
    }
  } catch (e) {
    print('Error sending FCM token: $e');
  }
}

// Call this after login or when token is available
final token = FirebaseNotificationService().fcmToken;
if (token != null) {
  await ApiService.sendFCMToken(token);
}
```

### Example 4: Display FCM Token in Settings

Add a settings screen or info section to show the FCM token:

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final token = FirebaseNotificationService().fcmToken;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('FCM Token'),
            subtitle: Text(token ?? 'Loading...'),
            trailing: IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                if (token != null) {
                  Clipboard.setData(ClipboardData(text: token));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Token copied!')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## 🧪 Testing Checklist

### Before Testing
- [ ] Firebase project created
- [ ] Android app registered in Firebase
- [ ] iOS app registered in Firebase
- [ ] `google-services.json` downloaded and placed
- [ ] `GoogleService-Info.plist` downloaded and added to Xcode
- [ ] Gradle files updated
- [ ] `flutter pub get` executed
- [ ] `cd ios && pod install` executed

### Testing Scenarios
- [ ] App launches without errors
- [ ] FCM token is generated (check console logs)
- [ ] Send test notification from Firebase Console
- [ ] Notification appears when app is in foreground
- [ ] Notification appears when app is in background
- [ ] Notification appears when app is terminated
- [ ] Tapping notification opens the app
- [ ] Topic subscription works
- [ ] Topic unsubscription works

### Test Notification Payload Examples

#### Basic Notification
```json
{
  "to": "FCM_TOKEN_HERE",
  "notification": {
    "title": "New Order",
    "body": "You have received a new shipping order"
  }
}
```

#### Notification with Data for Routing
```json
{
  "to": "FCM_TOKEN_HERE",
  "notification": {
    "title": "Order Update",
    "body": "Your order #123 has been shipped"
  },
  "data": {
    "type": "order_update",
    "orderId": "123",
    "screen": "order_detail"
  }
}
```

#### Topic Notification
```json
{
  "to": "/topics/order_updates",
  "notification": {
    "title": "System Maintenance",
    "body": "The system will be under maintenance tonight"
  },
  "data": {
    "type": "announcement"
  }
}
```

## 📊 Notification States Explained

| App State | Behavior | Handler |
|-----------|----------|---------|
| **Foreground** | Shows local notification with sound | `FirebaseMessaging.onMessage` |
| **Background** | Shows system notification | `FirebaseMessaging.onBackgroundMessage` |
| **Terminated** | Shows system notification | `FirebaseMessaging.onBackgroundMessage` |
| **Tapped** | Opens app and triggers callback | `FirebaseMessaging.onMessageOpenedApp` |

## 🎯 Common Use Cases

### 1. Order Status Updates
```dart
// Backend sends:
{
  "type": "order_status",
  "orderId": "123",
  "status": "shipped"
}

// App handles:
if (message.data['type'] == 'order_status') {
  // Refresh order list or navigate to order detail
}
```

### 2. Promotional Notifications
```dart
// Subscribe users to promotions
await FirebaseNotificationService().subscribeToTopic('promotions');

// Backend sends to topic 'promotions'
```

### 3. User-Specific Notifications
```dart
// Subscribe to user-specific topic after login
await FirebaseNotificationService().subscribeToTopic('user_${userId}');

// Backend sends to topic 'user_123'
```

## 🐛 Common Issues and Solutions

### Issue: Token is null
**Solution**: 
- Ensure Firebase is initialized before accessing the token
- Check that Firebase config files are properly added
- Wait for initialization to complete

### Issue: Notifications not showing on iOS
**Solution**:
- Check APNs key is uploaded to Firebase Console
- Verify push notifications capability is enabled in Xcode
- Ensure app is properly signed

### Issue: Notifications not showing on Android 13+
**Solution**:
- POST_NOTIFICATIONS permission is required
- Permission is automatically requested by the notification service
- Users must grant the permission

### Issue: Background notifications not working
**Solution**:
- Ensure background message handler is registered
- Check that it's a top-level function
- Verify notification payload includes both `notification` and `data` fields

## 📚 Additional Resources

- See `lib/services/notification_example.dart` for complete examples
- See `FIREBASE_SETUP_GUIDE.md` for detailed Firebase setup
- [Firebase Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

## 🚀 Production Considerations

Before releasing to production:

1. **Security**: Never expose your Firebase server key
2. **Token Management**: Store FCM tokens securely on your backend
3. **Topics**: Use meaningful topic names (e.g., 'all_users', 'premium_users')
4. **Data Validation**: Always validate notification data before routing
5. **Error Handling**: Implement proper error handling for all notification operations
6. **Analytics**: Track notification delivery and interaction rates
7. **Unsubscribe**: Provide way for users to unsubscribe from notifications
8. **Token Cleanup**: Remove old tokens from your backend when users logout

## 💡 Pro Tips

1. **Test on Real Devices**: Notifications behave differently on simulators/emulators
2. **Use Data Payloads**: Include routing information in the `data` field
3. **Silent Notifications**: Use `content_available` for iOS silent notifications
4. **Rich Notifications**: Support images and actions in notifications
5. **Scheduling**: Use Firebase Cloud Functions to schedule notifications
6. **A/B Testing**: Use Firebase A/B testing for notification effectiveness

