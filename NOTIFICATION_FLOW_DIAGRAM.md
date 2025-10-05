# 📊 Firebase Cloud Messaging - Complete Flow Diagram

## 🔄 Token Lifecycle Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         APP STARTS                                   │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ main.dart                                                     │   │
│  │ • Firebase.initializeApp()                                   │   │
│  │ • FirebaseNotificationService().initialize()                 │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    INITIALIZATION                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ firebase_notification_service.dart                           │   │
│  │ 1. Request notification permission                           │   │
│  │ 2. Initialize local notifications                            │   │
│  │ 3. Get device ID (Android ID / iOS Vendor ID)               │   │
│  │ 4. Generate FCM token                                        │   │
│  │ 5. Setup message handlers                                    │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      USER LOGS IN                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ login_screen.dart                                            │   │
│  │ 1. Call ApiService.login()                                   │   │
│  │ 2. Save user data to storage                                 │   │
│  │ 3. FirebaseNotificationService().saveTokenToBackend()        │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                   SAVE TOKEN TO BACKEND                              │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ api_service.dart → saveFCMToken()                            │   │
│  │                                                               │   │
│  │ POST https://dolphinshippingiq.com/api/save_fcm.php         │   │
│  │ {                                                             │   │
│  │   "token": "eKj7...xyz",                                     │   │
│  │   "customer_id": 123,                                        │   │
│  │   "platform": "android",                                     │   │
│  │   "device_id": "android_id_abc"                              │   │
│  │ }                                                             │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              ↓                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ Backend (save_fcm.php)                                       │   │
│  │                                                               │   │
│  │ INSERT INTO fcm_tokens                                       │   │
│  │ (customer_id, token, platform, device_id, is_active)        │   │
│  │ VALUES (123, 'eKj7...xyz', 'android', 'android_id_abc', 1)  │   │
│  │ ON DUPLICATE KEY UPDATE ...                                  │   │
│  │                                                               │   │
│  │ ✅ Token saved in database                                   │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                   NOTIFICATION RECEIVED                              │
│                                                                       │
│  ┌────────────────────────────┐  ┌────────────────────────────┐    │
│  │    Backend PHP Code        │  │    Firebase FCM Server     │    │
│  │                            │  │                            │    │
│  │ notifyUser(                │  │  Sends notification to    │    │
│  │   $conn,                   │→→│  device using FCM token   │→→┐ │
│  │   $customerId,             │  │                            │  │ │
│  │   "Order Update",          │  │                            │  │ │
│  │   "Order shipped!",        │  │                            │  │ │
│  │   ['orderId' => '123']     │  │                            │  │ │
│  │ )                          │  │                            │  │ │
│  └────────────────────────────┘  └────────────────────────────┘  │ │
│                                                                   │ │
└───────────────────────────────────────────────────────────────────┼─┘
                                                                    │
                                                                    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    FLUTTER APP RECEIVES                              │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ App State: FOREGROUND                                         │  │
│  │ ┌──────────────────────────────────────────────────────────┐ │  │
│  │ │ FirebaseMessaging.onMessage                               │ │  │
│  │ │ • _handleForegroundMessage()                              │ │  │
│  │ │ • _showLocalNotification()                                │ │  │
│  │ │ • Display notification with sound                         │ │  │
│  │ └──────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ App State: BACKGROUND                                         │  │
│  │ ┌──────────────────────────────────────────────────────────┐ │  │
│  │ │ FirebaseMessaging.onBackgroundMessage                     │ │  │
│  │ │ • firebaseMessagingBackgroundHandler()                    │ │  │
│  │ │ • System displays notification                            │ │  │
│  │ └──────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ App State: TERMINATED                                         │  │
│  │ ┌──────────────────────────────────────────────────────────┐ │  │
│  │ │ System displays notification                              │ │  │
│  │ │ Tap opens app → getInitialMessage()                       │ │  │
│  │ └──────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                  USER TAPS NOTIFICATION                              │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ firebase_notification_service.dart                           │   │
│  │                                                               │   │
│  │ FirebaseMessaging.onMessageOpenedApp                         │   │
│  │ • _handleNotificationTap(message)                            │   │
│  │ • onNotificationTapped callback triggered                    │   │
│  │                                                               │   │
│  │ Example: Navigate to order detail screen                     │   │
│  │ if (message.data['orderId']) {                               │   │
│  │   Navigator.push(OrderDetailScreen(...))                     │   │
│  │ }                                                             │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    TOKEN REFRESH (Periodic)                          │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ firebase_notification_service.dart                           │   │
│  │                                                               │   │
│  │ FirebaseMessaging.onTokenRefresh                             │   │
│  │ • New token received                                         │   │
│  │ • _saveTokenToBackend(newToken)                              │   │
│  │ • Backend updates database (upsert)                          │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                     USER LOGS OUT                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ account_screen.dart                                          │   │
│  │ 1. FirebaseNotificationService().deleteTokenFromBackend()    │   │
│  │ 2. StorageService.clearUser()                                │   │
│  │ 3. Navigate to login screen                                  │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                DELETE TOKEN FROM BACKEND                             │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ api_service.dart → deleteFCMToken()                          │   │
│  │                                                               │   │
│  │ POST https://dolphinshippingiq.com/api/delete_fcm.php       │   │
│  │ {                                                             │   │
│  │   "token": "eKj7...xyz",                                     │   │
│  │   "customer_id": 123,                                        │   │
│  │   "device_id": "android_id_abc"                              │   │
│  │ }                                                             │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              ↓                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ Backend (delete_fcm.php)                                     │   │
│  │                                                               │   │
│  │ UPDATE fcm_tokens                                            │   │
│  │ SET is_active = 0, updated_at = NOW()                        │   │
│  │ WHERE token = 'eKj7...xyz' AND customer_id = 123            │   │
│  │                                                               │   │
│  │ ✅ Token deactivated in database                             │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

## 🗂️ Database Structure

```
fcm_tokens table:
┌──────────────┬────────────────────────┬──────────┬──────────────────┬───────────┬──────────────┬──────────────┬──────────────┐
│ customer_id  │ token                  │ platform │ device_id        │ is_active │ created_at   │ updated_at   │ last_seen    │
├──────────────┼────────────────────────┼──────────┼──────────────────┼───────────┼──────────────┼──────────────┼──────────────┤
│ 123          │ eKj7pq...xyz          │ android  │ android_id_abc   │ 1         │ 2024-01-15   │ 2024-01-20   │ 2024-01-20   │
│ 123          │ fL8krt...uvw          │ ios      │ ios_vendor_def   │ 1         │ 2024-01-16   │ 2024-01-20   │ 2024-01-20   │
│ 456          │ gM9lsu...rst          │ android  │ android_id_ghi   │ 1         │ 2024-01-17   │ 2024-01-19   │ 2024-01-19   │
│ 789          │ hN0mtv...opq          │ ios      │ ios_vendor_jkl   │ 0         │ 2024-01-10   │ 2024-01-18   │ 2024-01-15   │
└──────────────┴────────────────────────┴──────────┴──────────────────┴───────────┴──────────────┴──────────────┴──────────────┘

Note:
• is_active = 1: Active token, can receive notifications
• is_active = 0: Deactivated (user logged out or token expired)
• Multiple tokens per user = Multiple devices
• platform: android, ios, or web
```

## 📲 Notification States

```
┌─────────────────────────────────────────────────────────────────┐
│                    Notification Handling                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────┐                                             │
│  │   FOREGROUND   │  App is open and active                     │
│  │                │  • Local notification shown                 │
│  │                │  • With sound and badge                     │
│  │                │  • Handled by onMessage                     │
│  └────────────────┘                                             │
│                                                                  │
│  ┌────────────────┐                                             │
│  │   BACKGROUND   │  App is minimized                           │
│  │                │  • System notification shown                │
│  │                │  • Handled by onBackgroundMessage           │
│  │                │  • Tap opens app                            │
│  └────────────────┘                                             │
│                                                                  │
│  ┌────────────────┐                                             │
│  │   TERMINATED   │  App is closed                              │
│  │                │  • System notification shown                │
│  │                │  • Tap opens app                            │
│  │                │  • Handled by getInitialMessage             │
│  └────────────────┘                                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 🎯 Notification Data Flow

```
Backend                FCM Server              Flutter App
   │                       │                       │
   │  1. Send request      │                       │
   │  ──────────────────→  │                       │
   │                       │                       │
   │  2. Process & queue   │                       │
   │                       │                       │
   │                       │  3. Push notification │
   │                       │  ──────────────────→  │
   │                       │                       │
   │                       │                       │  4. Display
   │                       │                       │  ───────────→
   │                       │                       │
   │                       │  5. User taps         │
   │                       │  ←──────────────────  │
   │                       │                       │
   │                       │                       │  6. Navigate
   │                       │                       │  to screen
   │                       │                       │  ───────────→
```

## 📊 Complete System Architecture

```
┌───────────────────────────────────────────────────────────────────┐
│                      DOLPHIN SHIPPING APP                          │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │                      Flutter Frontend                         │ │
│  │  ┌────────────────────────────────────────────────────────┐  │ │
│  │  │ • login_screen.dart    → Save token on login           │  │ │
│  │  │ • account_screen.dart  → Delete token on logout        │  │ │
│  │  │ • home_screen.dart     → Display notifications         │  │ │
│  │  │ • order_detail_screen  → Handle notification taps      │  │ │
│  │  └────────────────────────────────────────────────────────┘  │ │
│  │  ┌────────────────────────────────────────────────────────┐  │ │
│  │  │ • firebase_notification_service.dart                    │  │ │
│  │  │   - Token generation                                    │  │ │
│  │  │   - Notification handling                               │  │ │
│  │  │   - Backend integration                                 │  │ │
│  │  └────────────────────────────────────────────────────────┘  │ │
│  │  ┌────────────────────────────────────────────────────────┐  │ │
│  │  │ • api_service.dart                                      │  │ │
│  │  │   - saveFCMToken()                                      │  │ │
│  │  │   - deleteFCMToken()                                    │  │ │
│  │  └────────────────────────────────────────────────────────┘  │ │
│  └──────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
                                ↕
┌───────────────────────────────────────────────────────────────────┐
│                    Firebase Cloud Services                         │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ • Firebase Cloud Messaging                                    │ │
│  │ • Token management                                            │ │
│  │ • Message routing                                             │ │
│  │ • Delivery tracking                                           │ │
│  └──────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
                                ↕
┌───────────────────────────────────────────────────────────────────┐
│                      PHP Backend Server                            │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ API Endpoints:                                                │ │
│  │ • save_fcm.php    → Store FCM tokens                         │ │
│  │ • delete_fcm.php  → Deactivate tokens                        │ │
│  │ • fcm_sender.php  → Send notifications                       │ │
│  └──────────────────────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ Functions:                                                    │ │
│  │ • notifyUser()                                                │ │
│  │ • notifyAllUsers()                                            │ │
│  │ • sendFCMNotification()                                       │ │
│  └──────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
                                ↕
┌───────────────────────────────────────────────────────────────────┐
│                        MySQL Database                              │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ fcm_tokens table:                                             │ │
│  │ • customer_id                                                 │ │
│  │ • token (unique)                                              │ │
│  │ • platform                                                    │ │
│  │ • device_id                                                   │ │
│  │ • is_active                                                   │ │
│  │ • timestamps                                                  │ │
│  └──────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
```

---

**All systems integrated and operational! 🚀**

