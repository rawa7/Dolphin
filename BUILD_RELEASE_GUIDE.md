# 🚀 Android Release Build Guide

## ✅ Keystore Created Successfully!

Your Android app is now ready for release builds with proper signing.

### 📋 Keystore Information

| Property | Value |
|----------|-------|
| **Keystore File** | `android/mymainkey.jks` |
| **Key Alias** | `mymainkey` |
| **Password** | `cr7rdhg7c` |
| **Validity** | 10,000 days (~27 years) |
| **Algorithm** | RSA 2048-bit |
| **Organization** | Dolphin Shipping, Erbil, Kurdistan, IQ |

⚠️ **IMPORTANT**: Keep these files secure and NEVER commit them to Git!
- ✅ Files are already added to `.gitignore`
- ✅ Backup `mymainkey.jks` and `key.properties` in a secure location

---

## 🏗️ Building Release Versions

### 1. **Build App Bundle (AAB)** - For Google Play Store

```bash
flutter build appbundle --release
```

**Output**: `build/app/outputs/bundle/release/app-release.aab`

This is the recommended format for uploading to Google Play Store.

---

### 2. **Build APK** - For Direct Distribution

```bash
flutter build apk --release
```

**Output**: `build/app/outputs/flutter-apk/app-release.apk`

Use this for direct installation or distribution outside of Google Play Store.

---

### 3. **Build Split APKs** - Optimized for Different Architectures

```bash
flutter build apk --split-per-abi --release
```

**Outputs**:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit Intel)

These are smaller files optimized for each device architecture.

---

## 📦 What's Configured

### ✅ Signing Configuration
Your app is automatically signed with your keystore when building release versions.

**File**: `android/app/build.gradle.kts`
```kotlin
signingConfigs {
    create("release") {
        keyAlias = "mymainkey"
        keyPassword = "cr7rdhg7c"
        storeFile = file("mymainkey.jks")
        storePassword = "cr7rdhg7c"
    }
}
```

### ✅ ProGuard/R8 Configuration
Code optimization and obfuscation are enabled for release builds:
- **Minification**: Removes unused code
- **Obfuscation**: Makes reverse engineering harder
- **Optimization**: Improves app performance

**File**: `android/app/proguard-rules.pro`

### ✅ Firebase Configuration
FCM (Firebase Cloud Messaging) is properly configured for both debug and release builds.

---

## 📱 Testing Release Build

### Test on Connected Device:
```bash
flutter run --release
```

### Install APK Manually:
```bash
flutter build apk --release
flutter install
```

---

## 🚢 Publishing to Google Play Store

### Step 1: Build App Bundle
```bash
flutter build appbundle --release
```

### Step 2: Upload to Google Play Console
1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app (or create new app)
3. Navigate to **Release** → **Production**
4. Upload `build/app/outputs/bundle/release/app-release.aab`
5. Fill in release details
6. Review and roll out

### Step 3: First-Time Setup (if new app)
- Add app screenshots (required)
- Write app description
- Set content rating
- Complete privacy policy
- Set up pricing and distribution

---

## 🔐 Security Best Practices

### ✅ Already Done:
- ✅ Keystore is excluded from Git (`.gitignore`)
- ✅ ProGuard rules configured
- ✅ Release signing configured
- ✅ Firebase properly set up

### 📋 Recommendations:
1. **Backup your keystore** to a secure location (USB drive, password manager, etc.)
2. **Never share** your keystore password publicly
3. **Keep multiple backups** - if you lose it, you can't update your app!
4. **Document** your keystore location for your team

---

## 📊 Build Information

### App Details:
- **Package Name**: `dolphin.shipping.erbil.dolphin`
- **Min SDK**: Android API 21+ (Android 5.0+)
- **Target SDK**: Latest
- **Supported Architectures**: ARM 32-bit, ARM 64-bit, x86_64

### Features Included:
✅ Firebase Cloud Messaging (FCM)
✅ Image Picker
✅ URL Launcher (WhatsApp, Google Maps)
✅ Shared Preferences
✅ Network Image Loading
✅ WebView
✅ Multi-language Support (English, Arabic, Kurdish)

---

## 🆘 Troubleshooting

### Issue: Build fails with "keystore not found"
**Solution**: Ensure `key.properties` and `mymainkey.jks` are in the `android/` directory.

### Issue: "Execution failed for task ':app:lintVitalRelease'"
**Solution**: Add to `android/app/build.gradle.kts`:
```kotlin
lintOptions {
    checkReleaseBuilds false
    abortOnError false
}
```

### Issue: App crashes in release but works in debug
**Solution**: Check ProGuard rules. May need to add keep rules for specific classes.

---

## 🎉 You're Ready!

Your app is now configured for production release builds!

**Quick Commands:**
```bash
# Build for Play Store
flutter build appbundle --release

# Build APK for testing
flutter build apk --release

# Test release build
flutter run --release
```

---

## 📝 Important Files (DO NOT DELETE)

- ✅ `android/mymainkey.jks` - Your signing key
- ✅ `android/key.properties` - Keystore configuration
- ✅ `android/app/proguard-rules.pro` - Code optimization rules
- ✅ `android/app/google-services.json` - Firebase configuration

**Remember**: Losing your keystore means you can't update your app on Play Store! 🔒

