import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../constants/app_colors.dart';
import '../generated/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;
  int? _customerId;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    final user = await StorageService.getUser();
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _customerId = user.id;

    final result = await ApiService.getNotifications(customerId: user.id);

    if (result['success'] && mounted) {
      final notificationData = result['data'] as NotificationData;
      setState(() {
        _notifications = notificationData.notifications;
        _unreadCount = notificationData.unreadCount;
        _isLoading = false;
      });
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to load notifications'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(NotificationItem notification) async {
    if (notification.isRead || _customerId == null) return;

    final result = await ApiService.markNotificationAsRead(
      customerId: _customerId!,
      notificationId: notification.id,
    );

    if (result['success']) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = NotificationItem(
            id: notification.id,
            customerId: notification.customerId,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            isRead: true,
            relatedId: notification.relatedId,
            relatedType: notification.relatedType,
            createdAt: notification.createdAt,
          );
          _unreadCount = _notifications.where((n) => !n.isRead).length;
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (_customerId == null || _unreadCount == 0) return;

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Marking all as read...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final result = await ApiService.markAllNotificationsAsRead(
      customerId: _customerId!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'All notifications marked as read'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadNotifications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to mark all as read'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleNotificationTap(NotificationItem notification) async {
    // Mark as read
    await _markAsRead(notification);

    // Handle deep linking based on notification type
    if (!mounted) return;

    switch (notification.type) {
      case 'order':
        // Navigate to My Orders tab in main navigation
        Navigator.pop(context, {'action': 'navigate', 'tab': 3}); // Tab 3 is My Orders
        break;

      case 'payment':
        // Navigate to Account tab in main navigation
        Navigator.pop(context, {'action': 'navigate', 'tab': 4}); // Tab 4 is Account
        break;

      case 'shipping':
        // Navigate to My Orders tab for shipping notifications
        Navigator.pop(context, {'action': 'navigate', 'tab': 3}); // Tab 3 is My Orders
        break;

      case 'general':
      default:
        // Show notification details in a dialog
        _showNotificationDetails(notification);
        break;
    }
  }

  void _showNotificationDetails(NotificationItem notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            Text(
              _formatDate(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order':
        return AppColors.primary;
      case 'payment':
        return AppColors.success;
      case 'shipping':
        return AppColors.info;
      case 'warning':
        return AppColors.warning;
      default:
        return AppColors.gray;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag;
      case 'payment':
        return Icons.payment;
      case 'shipping':
        return Icons.local_shipping;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark all read'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'re all caught up!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    final color = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? AppColors.white : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead ? Colors.grey[200]! : AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          if (!notification.isRead)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(notification.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

