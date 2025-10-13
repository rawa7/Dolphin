# iOS CocoaPods Fix

## ⚠️ Issue: Unable to find target named 'Runner'

### Error Message
```
[!] Unable to find a target named `Runner` in project `Runner.xcodeproj`, did find `RunnerTests`.
```

### Root Cause
The Xcode project file is corrupted or missing the main "Runner" target configuration.

## Quick Fix (Recommended)

### Option 1: Use Android for Now
Since Android is fully configured and working, test Firebase notifications on Android:

```bash
flutter run -d "adb-R5CW82N6VWY-B5Q17x._adb-tls-connect._tcp"
```

### Option 2: Rebuild iOS Project from Xcode

1. **Open Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Check if Runner target exists:**
   - In Xcode, select "Runner" project in left panel
   - Check "Targets" section
   - "Runner" target should be listed

3. **If Runner target is missing:**
   - File → Close Workspace
   - Delete derived data:
     ```bash
     rm -rf ~/Library/Developer/Xcode/DerivedData
     ```
   - Reopen workspace:
     ```bash
     open ios/Runner.xcworkspace
     ```

### Option 3: Recreate iOS Folder (Advanced)

⚠️ **WARNING: This will reset iOS configuration**

```bash
# Backup current iOS folder
cp -r ios ios_backup

# Remove iOS folder
rm -rf ios

# Recreate iOS folder
flutter create --platforms=ios .

# Restore custom configurations:
# - Copy back GoogleService-Info.plist
# - Reapply AppDelegate.swift changes
# - Restore Info.plist changes
```

## Understanding the Error

### What Happened
CocoaPods looks for a target named "Runner" in the Xcode project to install dependencies. The Xcode project file (.xcodeproj) is missing or has a corrupted target configuration.

### Why It Happens
- Xcode project file corruption
- Incomplete Flutter iOS setup
- Missing target configuration
- Xcode version incompatibilities

## Alternative: Test on Android First

Since we've fully configured Android with:
- ✅ Google Services plugin
- ✅ Core library desugaring
- ✅ google-services.json

**Recommendation:** Test Firebase notifications on Android first, then fix iOS separately.

## iOS Setup (When Fixed)

Once the Runner target issue is resolved:

1. **Add GoogleService-Info.plist:**
   ```bash
   open ios/Runner.xcworkspace
   ```
   - Right-click "Runner" folder
   - "Add Files to Runner"
   - Select `GoogleService-Info.plist`
   - Check "Copy items if needed"

2. **Verify AppDelegate.swift** has Firebase code (already done)

3. **Run pod install:**
   ```bash
   cd ios && pod install && cd ..
   ```

4. **Run on iOS:**
   ```bash
   flutter run -d iPhone
   ```

## Verification Steps

### Check Xcode Project
```bash
# List targets in project
xcodebuild -list -project ios/Runner.xcodeproj
```

Should show:
```
Targets:
    Runner
    RunnerTests
```

### Check Podfile
```bash
cat ios/Podfile | grep "target 'Runner'"
```

Should show:
```
target 'Runner' do
```

## Quick Commands

### Clean Everything
```bash
cd ios
rm -rf Pods Podfile.lock .symlinks
cd ..
flutter clean
flutter pub get
```

### Rebuild Pods
```bash
cd ios
pod deintegrate
pod install
cd ..
```

### Check Xcode
```bash
open ios/Runner.xcworkspace
```

## Current Status

- ✅ **Android**: Fully configured and ready
- ⚠️ **iOS**: Xcode project needs repair

## Next Steps

1. **For immediate testing:** Use Android
2. **For iOS fix:** 
   - Option 1: Open Xcode and check targets
   - Option 2: Recreate iOS folder
   - Option 3: Continue with Android for now

## Support

### If Xcode Shows Runner Target
- Clean and rebuild pods
- Ensure all Firebase files are added

### If Xcode Doesn't Show Runner Target
- Project file is corrupted
- Need to recreate iOS folder
- Or restore from backup

---

**Current Recommendation:** Test on Android first (it's fully configured), then address iOS separately.

**Android Command:**
```bash
flutter run -d "adb-R5CW82N6VWY-B5Q17x._adb-tls-connect._tcp"
```

This will let you verify Firebase notifications work, then we can fix iOS afterward.

