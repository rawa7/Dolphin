# Your App Information for Firebase Setup

Use these values when registering your app in Firebase Console:

## Android Configuration

**Package Name / Application ID:**
```
dolphin.shipping.erbil.dolphin
```

Use this when:
- Adding Android app in Firebase Console
- Downloading `google-services.json`

## iOS Configuration

**Bundle Identifier:**
```
dolphin.shipping.erbil.dolphin
```

Use this when:
- Adding iOS app in Firebase Console
- Downloading `GoogleService-Info.plist`

## App Name

**Display Name:** Dolphin Shipping

---

## Quick Firebase Setup Checklist

### Android Setup
- [ ] Go to Firebase Console
- [ ] Add Android app with package name: `dolphin.shipping.erbil.dolphin`
- [ ] Download `google-services.json`
- [ ] Place file at: `android/app/google-services.json`
- [ ] Update `android/build.gradle.kts` with Google Services plugin
- [ ] Update `android/app/build.gradle.kts` to apply the plugin

### iOS Setup
- [ ] In same Firebase project, add iOS app
- [ ] Use bundle ID: `dolphin.shipping.erbil.dolphin`
- [ ] Download `GoogleService-Info.plist`
- [ ] Open Xcode: `open ios/Runner.xcworkspace`
- [ ] Add `GoogleService-Info.plist` to Runner folder in Xcode
- [ ] Upload APNs key to Firebase Console (for push notifications)

### Final Steps
- [ ] Run: `flutter pub get`
- [ ] Run: `cd ios && pod install && cd ..`
- [ ] Run: `flutter run`
- [ ] Test notifications from Firebase Console

---

**Next:** See `FIREBASE_QUICK_START.md` for step-by-step instructions!

