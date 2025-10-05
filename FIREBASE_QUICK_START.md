# Firebase Notifications - Quick Start 🚀

## ✅ What's Done

All code implementation is complete! Your Flutter app is ready for Firebase notifications.

## 🔥 What You Need to Do (5 Steps)

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Follow the wizard

### Step 2: Download Config Files

**For Android:**
- Add Android app in Firebase Console
- Download `google-services.json`
- Place at: `android/app/google-services.json`

**For iOS:**
- Add iOS app in Firebase Console
- Download `GoogleService-Info.plist`
- Open Xcode: `open ios/Runner.xcworkspace`
- Right-click Runner folder → "Add Files to Runner"
- Select `GoogleService-Info.plist` (check "Copy items if needed")

### Step 3: Update Gradle Files

**File: `android/build.gradle.kts`**
```kotlin
plugins {
    // ... existing plugins ...
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

**File: `android/app/build.gradle.kts`**
Add after other plugins:
```kotlin
plugins {
    // ... existing plugins ...
    id("com.google.gms.google-services")
}
```

### Step 4: Install Dependencies
```bash
flutter pub get
cd ios && pod install && cd ..
```

### Step 5: Test!
```bash
# Run the app
flutter run

# Check console for FCM token
# Send test notification from Firebase Console
```

## 🧪 Quick Test

1. Run your app
2. Look for "FCM Token: xyz..." in console
3. Copy the token
4. Go to Firebase Console → Cloud Messaging
5. Click "Send test message"
6. Paste token and send
7. You should see the notification! 🎉

## 📱 Integration Examples

### Get FCM Token
```dart
final token = FirebaseNotificationService().fcmToken;
```

### Subscribe to Topics
```dart
await FirebaseNotificationService().subscribeToTopic('orders');
```

### Handle Notification Taps
```dart
FirebaseNotificationService().onNotificationTapped = (message) {
  // Handle tap - navigate to screen
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => OrderDetailScreen(
      orderId: message.data['orderId']
    ),
  ));
};
```

## 📚 Full Documentation

- **Setup Guide**: See `FIREBASE_SETUP_GUIDE.md`
- **Integration Examples**: See `NOTIFICATION_INTEGRATION.md`
- **Code Examples**: See `lib/services/notification_example.dart`

## 🆘 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Token is null | Check Firebase config files are added correctly |
| No notifications on iOS | Upload APNs key to Firebase Console |
| No notifications on Android 13+ | Permission is auto-requested on first launch |
| Build errors | Run `flutter clean && flutter pub get` |

## 📞 Need Help?

1. Check console logs for errors
2. Review `FIREBASE_SETUP_GUIDE.md` for detailed instructions
3. See `notification_example.dart` for working code examples

---

**Next Step**: Download your Firebase config files and you're ready to go! 🎉

