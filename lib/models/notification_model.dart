class NotificationItem {
  final int id;
  final int customerId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final int relatedId;
  final String relatedType;
  final String createdAt;

  NotificationItem({
    required this.id,
    required this.customerId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.relatedId,
    required this.relatedType,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0),
      customerId: json['customer_id'] is int ? json['customer_id'] : (json['customer_id'] != null ? int.tryParse(json['customer_id'].toString()) ?? 0 : 0),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == '1',
      relatedId: json['related_id'] is int ? json['related_id'] : (json['related_id'] != null ? int.tryParse(json['related_id'].toString()) ?? 0 : 0),
      relatedType: json['related_type']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'related_id': relatedId,
      'related_type': relatedType,
      'created_at': createdAt,
    };
  }
}

class NotificationData {
  final List<NotificationItem> notifications;
  final int totalCount;
  final int unreadCount;
  final int currentCount;
  final int limit;
  final int offset;

  NotificationData({
    required this.notifications,
    required this.totalCount,
    required this.unreadCount,
    required this.currentCount,
    required this.limit,
    required this.offset,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    var notificationsList = json['notifications'] as List? ?? [];
    List<NotificationItem> notifications = notificationsList
        .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return NotificationData(
      notifications: notifications,
      totalCount: json['total_count'] is int ? json['total_count'] : (json['total_count'] != null ? int.tryParse(json['total_count'].toString()) ?? 0 : 0),
      unreadCount: json['unread_count'] is int ? json['unread_count'] : (json['unread_count'] != null ? int.tryParse(json['unread_count'].toString()) ?? 0 : 0),
      currentCount: json['current_count'] is int ? json['current_count'] : (json['current_count'] != null ? int.tryParse(json['current_count'].toString()) ?? 0 : 0),
      limit: json['limit'] is int ? json['limit'] : (json['limit'] != null ? int.tryParse(json['limit'].toString()) ?? 50 : 50),
      offset: json['offset'] is int ? json['offset'] : (json['offset'] != null ? int.tryParse(json['offset'].toString()) ?? 0 : 0),
    );
  }
}

