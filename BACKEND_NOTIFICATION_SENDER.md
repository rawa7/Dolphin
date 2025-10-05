# Backend Notification Sender - PHP Example

This guide shows how to send FCM notifications from your PHP backend.

## 📋 Prerequisites

1. ✅ Firebase project created
2. ✅ Server key from Firebase Console
3. ✅ FCM tokens saved in database

## 🔑 Get Your Server Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click Settings (gear icon) → Project Settings
4. Go to "Cloud Messaging" tab
5. Copy the "Server key" (legacy)

> **Note**: Google recommends using Firebase Admin SDK, but Server Key works for simple implementations.

## 📝 PHP FCM Helper Functions

Create a file: `fcm_sender.php`

```php
<?php

/**
 * Send FCM notification to a single token
 */
function sendFCMNotification($token, $title, $body, $data = []) {
    $serverKey = 'YOUR_FIREBASE_SERVER_KEY'; // Get from Firebase Console
    
    $notification = [
        'title' => $title,
        'body' => $body,
        'sound' => 'default',
        'badge' => '1',
    ];
    
    $payload = [
        'to' => $token,
        'notification' => $notification,
        'data' => $data,
        'priority' => 'high',
    ];
    
    $headers = [
        'Authorization: key=' . $serverKey,
        'Content-Type: application/json',
    ];
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://fcm.googleapis.com/fcm/send');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    
    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    $response = json_decode($result, true);
    
    return [
        'success' => $httpCode === 200 && isset($response['success']) && $response['success'] > 0,
        'response' => $response,
        'http_code' => $httpCode,
    ];
}

/**
 * Send FCM notification to multiple tokens
 */
function sendFCMNotificationToMultiple($tokens, $title, $body, $data = []) {
    $serverKey = 'YOUR_FIREBASE_SERVER_KEY';
    
    // FCM supports max 1000 tokens per request
    $chunks = array_chunk($tokens, 1000);
    $results = [];
    
    foreach ($chunks as $tokenChunk) {
        $notification = [
            'title' => $title,
            'body' => $body,
            'sound' => 'default',
            'badge' => '1',
        ];
        
        $payload = [
            'registration_ids' => $tokenChunk,
            'notification' => $notification,
            'data' => $data,
            'priority' => 'high',
        ];
        
        $headers = [
            'Authorization: key=' . $serverKey,
            'Content-Type: application/json',
        ];
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, 'https://fcm.googleapis.com/fcm/send');
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
        
        $result = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        $response = json_decode($result, true);
        $results[] = [
            'success' => $httpCode === 200,
            'response' => $response,
            'tokens_sent' => count($tokenChunk),
        ];
    }
    
    return $results;
}

/**
 * Get active FCM tokens for a user
 */
function getUserFCMTokens($conn, $customerId) {
    $customerId = intval($customerId);
    $sql = "SELECT token FROM fcm_tokens 
            WHERE customer_id = $customerId AND is_active = 1";
    
    $result = mysqli_query($conn, $sql);
    $tokens = [];
    
    while ($row = mysqli_fetch_assoc($result)) {
        $tokens[] = $row['token'];
    }
    
    return $tokens;
}

/**
 * Get all active FCM tokens
 */
function getAllActiveFCMTokens($conn) {
    $sql = "SELECT token FROM fcm_tokens WHERE is_active = 1";
    
    $result = mysqli_query($conn, $sql);
    $tokens = [];
    
    while ($row = mysqli_fetch_assoc($result)) {
        $tokens[] = $row['token'];
    }
    
    return $tokens;
}

/**
 * Get active FCM tokens by platform
 */
function getFCMTokensByPlatform($conn, $platform) {
    $platform = mysqli_real_escape_string($conn, $platform);
    $sql = "SELECT token FROM fcm_tokens 
            WHERE is_active = 1 AND platform = '$platform'";
    
    $result = mysqli_query($conn, $sql);
    $tokens = [];
    
    while ($row = mysqli_fetch_assoc($result)) {
        $tokens[] = $row['token'];
    }
    
    return $tokens;
}

/**
 * Send notification to a specific user
 */
function notifyUser($conn, $customerId, $title, $body, $data = []) {
    $tokens = getUserFCMTokens($conn, $customerId);
    
    if (empty($tokens)) {
        return ['success' => false, 'message' => 'No tokens found for user'];
    }
    
    $results = [];
    foreach ($tokens as $token) {
        $result = sendFCMNotification($token, $title, $body, $data);
        $results[] = $result;
    }
    
    return [
        'success' => true,
        'tokens_sent' => count($tokens),
        'results' => $results,
    ];
}

/**
 * Send notification to all users
 */
function notifyAllUsers($conn, $title, $body, $data = []) {
    $tokens = getAllActiveFCMTokens($conn);
    
    if (empty($tokens)) {
        return ['success' => false, 'message' => 'No active tokens found'];
    }
    
    $results = sendFCMNotificationToMultiple($tokens, $title, $body, $data);
    
    return [
        'success' => true,
        'total_tokens' => count($tokens),
        'results' => $results,
    ];
}

?>
```

## 🎯 Usage Examples

### Example 1: Order Status Update

```php
<?php
require_once 'fcm_sender.php';
include '../resources/config.php';

// When order status changes
$orderId = 123;
$customerId = 456;
$orderStatus = 'shipped';

// Send notification to user
$result = notifyUser(
    $conn,
    $customerId,
    'Order Update',
    "Your order #$orderId has been $orderStatus!",
    [
        'type' => 'order_update',
        'orderId' => (string)$orderId,
        'status' => $orderStatus,
        'screen' => 'order_detail',
    ]
);

if ($result['success']) {
    echo "Notification sent to {$result['tokens_sent']} device(s)";
} else {
    echo "Failed to send notification: {$result['message']}";
}
?>
```

### Example 2: New Order Notification

```php
<?php
// When new order is created
$customerId = 456;
$orderNumber = 'ORD-2024-001';

notifyUser(
    $conn,
    $customerId,
    'Order Confirmed',
    "Your order $orderNumber has been confirmed!",
    [
        'type' => 'order_confirmed',
        'orderNumber' => $orderNumber,
    ]
);
?>
```

### Example 3: Promotional Message to All Users

```php
<?php
// Send promotion to all users
$result = notifyAllUsers(
    $conn,
    'Special Offer! 🎉',
    '50% off on all international shipping this week!',
    [
        'type' => 'promotion',
        'promo_code' => 'SHIP50',
    ]
);

echo "Sent to {$result['total_tokens']} users";
?>
```

### Example 4: Platform-Specific Notification

```php
<?php
// Send to iOS users only
$iosTokens = getFCMTokensByPlatform($conn, 'ios');
$results = sendFCMNotificationToMultiple(
    $iosTokens,
    'iOS Update Available',
    'New version of the app is now available!',
    ['type' => 'app_update']
);
?>
```

### Example 5: Custom Notification Sender API

Create: `send_notification.php`

```php
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit();
}

include '../resources/config.php';
require_once 'fcm_sender.php';

$input = json_decode(file_get_contents('php://input'), true);

$customerId = isset($input['customer_id']) ? intval($input['customer_id']) : null;
$title = isset($input['title']) ? trim($input['title']) : '';
$body = isset($input['body']) ? trim($input['body']) : '';
$data = isset($input['data']) ? $input['data'] : [];
$sendToAll = isset($input['send_to_all']) ? (bool)$input['send_to_all'] : false;

if ($title === '' || $body === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'title and body are required']);
    exit();
}

if ($sendToAll) {
    // Send to all users
    $result = notifyAllUsers($conn, $title, $body, $data);
} elseif ($customerId) {
    // Send to specific user
    $result = notifyUser($conn, $customerId, $title, $body, $data);
} else {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'customer_id or send_to_all required']);
    exit();
}

echo json_encode($result);
?>
```

**Usage:**
```bash
# Send to specific user
curl -X POST https://dolphinshippingiq.com/api/send_notification.php \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": 123,
    "title": "Test Notification",
    "body": "This is a test message",
    "data": {"type": "test"}
  }'

# Send to all users
curl -X POST https://dolphinshippingiq.com/api/send_notification.php \
  -H "Content-Type: application/json" \
  -d '{
    "send_to_all": true,
    "title": "Announcement",
    "body": "Important system message",
    "data": {"type": "announcement"}
  }'
```

## 🔄 Automated Notifications

### Order Status Changes

Add to your order update code:

```php
// In your order status update function
function updateOrderStatus($orderId, $newStatus) {
    global $conn;
    
    // Update order in database
    $sql = "UPDATE orders SET status = '$newStatus' WHERE id = $orderId";
    mysqli_query($conn, $sql);
    
    // Get order details
    $order = getOrderById($orderId);
    $customerId = $order['customer_id'];
    
    // Send notification
    require_once 'fcm_sender.php';
    notifyUser(
        $conn,
        $customerId,
        'Order Update',
        "Your order #{$order['order_number']} is now $newStatus",
        [
            'type' => 'order_status',
            'orderId' => (string)$orderId,
            'status' => $newStatus,
        ]
    );
}
```

### Daily Summary

Create a cron job:

```php
<?php
// daily_summary.php - Run via cron at 8 AM daily

include '../resources/config.php';
require_once 'fcm_sender.php';

// Get all users with pending orders
$sql = "SELECT DISTINCT customer_id FROM orders 
        WHERE status = 'pending' OR status = 'processing'";
$result = mysqli_query($conn, $sql);

while ($row = mysqli_fetch_assoc($result)) {
    $customerId = $row['customer_id'];
    
    // Count pending orders
    $countSql = "SELECT COUNT(*) as count FROM orders 
                 WHERE customer_id = $customerId 
                 AND (status = 'pending' OR status = 'processing')";
    $countResult = mysqli_query($conn, $countSql);
    $count = mysqli_fetch_assoc($countResult)['count'];
    
    if ($count > 0) {
        notifyUser(
            $conn,
            $customerId,
            'Order Summary',
            "You have $count order(s) in progress",
            ['type' => 'daily_summary']
        );
    }
}

echo "Daily summary sent successfully";
?>
```

## 📊 Notification Analytics

Track notification success:

```php
<?php
// Add after sending notification
function logNotification($conn, $customerId, $title, $success) {
    $sql = "INSERT INTO notification_logs 
            (customer_id, title, success, sent_at) 
            VALUES ($customerId, '$title', $success, NOW())";
    mysqli_query($conn, $sql);
}

// Usage
$result = notifyUser($conn, $customerId, $title, $body, $data);
logNotification($conn, $customerId, $title, $result['success']);
?>
```

## 🐛 Troubleshooting

### Invalid Server Key
- Double-check server key from Firebase Console
- Make sure it's the "Server key" not "Sender ID"

### Token Invalid/Not Registered
- Token may be expired or deleted
- Mark token as inactive in database
- User will get new token on next login

### Notification Not Received
- Check token is active in database
- Verify app has notification permission
- Test with Firebase Console first
- Check platform (iOS needs APNs configured)

## 🔐 Security Best Practices

1. **Never expose server key** in client code
2. **Validate user permissions** before sending
3. **Rate limit** notification sending
4. **Log all notifications** for audit trail
5. **Use HTTPS** for all API endpoints

## 📈 Performance Tips

1. **Batch notifications** (max 1000 per request)
2. **Use background jobs** for large sends
3. **Clean up inactive tokens** regularly
4. **Monitor FCM quotas**
5. **Cache token lists** when possible

---

**Ready to send notifications!** 🚀

Your backend can now send push notifications to your Flutter app users.

