# Firebase Cloud Messaging Setup Guide

This guide will help you complete the Firebase setup for your Dolphin Shipping app.

## What's Already Done ✅

1. ✅ Firebase dependencies added to `pubspec.yaml`
2. ✅ Firebase Notification Service created
3. ✅ Firebase initialized in `main.dart`
4. ✅ Android configuration completed
5. ✅ iOS configuration completed

## What You Need to Do Next

### Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Follow the setup wizard

### Step 2: Add Android App to Firebase

1. In Firebase Console, click "Add app" and select Android
2. Enter your Android package name (found in `android/app/build.gradle.kts`)
3. Download the `google-services.json` file
4. Place it in: `android/app/google-services.json`
5. Add the following to `android/build.gradle.kts` (in the plugins section if not already there):
   ```kotlin
   id("com.google.gms.google-services") version "4.4.2" apply false
   ```
6. Add the following to `android/app/build.gradle.kts` (at the top, after other plugins):
   ```kotlin
   id("com.google.gms.google-services")
   ```

### Step 3: Add iOS App to Firebase

1. In Firebase Console, click "Add app" and select iOS
2. Enter your iOS bundle ID (found in Xcode or `ios/Runner.xcodeproj/project.pbxproj`)
3. Download the `GoogleService-Info.plist` file
4. Open your project in Xcode: `open ios/Runner.xcworkspace`
5. Right-click on "Runner" folder in Xcode and select "Add Files to Runner"
6. Select the downloaded `GoogleService-Info.plist`
7. Make sure "Copy items if needed" is checked
8. Click "Add"

### Step 4: Install Dependencies

Run the following commands:

```bash
# Get Flutter dependencies
flutter pub get

# For iOS, install CocoaPods
cd ios
pod install
cd ..
```

### Step 5: Enable Cloud Messaging

1. In Firebase Console, go to "Cloud Messaging"
2. For iOS: Upload your APNs authentication key or certificate
   - Go to Apple Developer Portal
   - Create an APNs key under Certificates, Identifiers & Profiles
   - Download and upload to Firebase

## How to Use Firebase Notifications

### Getting the FCM Token

The FCM token is automatically generated when the app starts. You can access it via:

```dart
final token = FirebaseNotificationService().fcmToken;
print('FCM Token: $token');
```

### Subscribing to Topics

```dart
await FirebaseNotificationService().subscribeToTopic('news');
await FirebaseNotificationService().subscribeToTopic('promotions');
```

### Unsubscribing from Topics

```dart
await FirebaseNotificationService().unsubscribeFromTopic('news');
```

### Handling Notification Taps

Set up a callback to handle when users tap on notifications:

```dart
FirebaseNotificationService().onNotificationTapped = (RemoteMessage message) {
  // Handle the notification tap
  print('Notification tapped: ${message.data}');
  
  // Navigate to a specific screen based on notification data
  if (message.data.containsKey('orderId')) {
    // Navigate to order detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(orderId: message.data['orderId']),
      ),
    );
  }
};
```

## Testing Notifications

### Test from Firebase Console

1. Go to Firebase Console > Cloud Messaging
2. Click "Send your first message"
3. Enter notification title and text
4. Click "Send test message"
5. Enter your FCM token (printed in console when app starts)
6. Click "Test"

### Test with curl

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "FCM_TOKEN",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test message"
    },
    "data": {
      "orderId": "123",
      "type": "order_update"
    }
  }'
```

## Notification Behavior

- **Foreground**: Shows local notification with sound
- **Background**: Shows system notification
- **Terminated**: Shows system notification
- **Tap**: Triggers `onNotificationTapped` callback

## Troubleshooting

### Android Issues

1. **Notifications not showing**: Check if notification permission is granted (Android 13+)
2. **Token not generated**: Ensure `google-services.json` is in the correct location
3. **Build errors**: Run `flutter clean` and `flutter pub get`

### iOS Issues

1. **Notifications not showing**: 
   - Check if push notifications are enabled in Xcode capabilities
   - Verify APNs key is uploaded to Firebase
2. **Token not generated**: Ensure `GoogleService-Info.plist` is added to Xcode project
3. **Build errors**: Run `cd ios && pod deintegrate && pod install`

## Important Notes

- Firebase initialization happens in `main.dart` before the app runs
- Notification permissions are requested automatically on app start
- FCM token is saved and can be sent to your backend for targeted notifications
- Background message handler is set up to handle notifications when app is terminated

## Next Steps

After completing the setup:

1. Test notifications in all app states (foreground, background, terminated)
2. Implement notification handling in your app screens
3. Send the FCM token to your backend server
4. Set up server-side notification sending logic

## Useful Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Documentation](https://firebase.flutter.dev/docs/overview)
- [iOS Push Notification Setup](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [Android Notification Channels](https://developer.android.com/develop/ui/views/notifications/channels)

