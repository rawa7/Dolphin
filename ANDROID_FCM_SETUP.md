# Android FCM (Firebase Cloud Messaging) Setup - Complete Guide

## ✅ Current Configuration Status

Your Android FCM setup is **COMPLETE** and properly configured. Here's what's already in place:

### 1. Google Services Configuration ✅

**File**: `android/app/google-services.json`
- Project ID: `dolphin-99b00`
- Package name: `dolphin.shipping.erbil.dolphin`
- App ID: `1:950824660207:android:f674d21b7c0f3d92e03f1a`

### 2. Build Configuration ✅

**File**: `android/build.gradle.kts`
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}
```

**File**: `android/app/build.gradle.kts`
```kotlin
plugins {
    id("com.google.gms.google-services")  // ✅ Google Services plugin applied
}
```

### 3. Android Manifest Configuration ✅

**File**: `android/app/src/main/AndroidManifest.xml`

#### Permissions:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>  <!-- For Android 13+ -->
```

#### FCM Service:
```xml
<service
    android:name="com.google.firebase.messaging.FirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

#### Notification Configuration:
```xml
<!-- Default notification icon -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@mipmap/ic_launcher" />

<!-- Default notification color -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@android:color/white" />

<!-- Default notification channel -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel" />
```

### 4. Flutter Firebase Service ✅

**File**: `lib/services/firebase_notification_service.dart`

The service handles:
- ✅ Firebase initialization
- ✅ FCM token generation and retrieval
- ✅ Notification permissions request
- ✅ Foreground notification handling
- ✅ Background notification handling
- ✅ Notification channel creation (Android 8.0+)

## 🎯 Key Differences: Android vs iOS

| Feature | Android | iOS |
|---------|---------|-----|
| **Token Generation** | Direct via FCM | Requires APNs token first |
| **Permissions** | Runtime permission for Android 13+ | Always required |
| **Configuration File** | `google-services.json` | `GoogleService-Info.plist` |
| **Additional Setup** | Manifest entries | Entitlements file |
| **Background Notifications** | Works automatically | Requires proper APNs setup |

## 📱 Testing FCM on Android

### 1. Check FCM Token Generation
When the app starts, you should see in the logs:
```
FCM token obtained: [YOUR_TOKEN]
FCM token stored successfully
```

### 2. Test Foreground Notifications
When app is open, notifications will be handled by Flutter and displayed as in-app notifications.

### 3. Test Background Notifications
When app is in background or closed:
- Notifications will appear in the system tray
- Tapping them will open the app
- Data payload will be processed

### 4. Send Test Notification
Use Firebase Console or your backend to send a test notification:

**Notification Payload Example**:
```json
{
  "to": "FCM_TOKEN_HERE",
  "notification": {
    "title": "Test Notification",
    "body": "This is a test from Dolphin Shipping",
    "sound": "default"
  },
  "data": {
    "type": "order_update",
    "order_id": "123"
  },
  "priority": "high"
}
```

## 🔧 Troubleshooting

### Issue: No FCM Token
**Solution**: Check that:
- Google Play Services is installed on the device
- Internet connection is available
- `google-services.json` has correct package name

### Issue: Notifications Not Showing
**Solution**: 
- Check notification permissions are granted
- Verify notification channel is created
- Check device notification settings for the app

### Issue: Background Notifications Not Working
**Solution**:
- Ensure app is not force-stopped
- Check battery optimization settings
- Verify Firebase service is properly configured

## 📝 Android Version Considerations

### Android 13+ (API 33+)
- **Runtime notification permission required**
- Your app already handles this via `firebase_notification_service.dart`

### Android 8.0+ (API 26+)
- **Notification channels required**
- Your app creates "high_importance_channel" automatically

### Android 7.0 and below
- Works automatically with basic configuration

## ✅ Your Setup is Ready!

All Android FCM configuration is properly set up. The app should:
1. ✅ Request notification permissions (Android 13+)
2. ✅ Generate and retrieve FCM token
3. ✅ Receive foreground notifications
4. ✅ Receive background notifications
5. ✅ Display notifications in system tray
6. ✅ Handle notification taps

## 🎉 Next Steps

1. **Run the app** on your Android device
2. **Check logs** for FCM token generation
3. **Grant notification permissions** when prompted
4. **Test notifications** using Firebase Console or your backend
5. **Verify** notifications appear both in foreground and background

Your Android setup is complete and production-ready! 🚀

