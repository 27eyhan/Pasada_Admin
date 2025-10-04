import 'package:pasada_admin_application/models/notification_history.dart';
import 'package:pasada_admin_application/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationHistoryService {
  static final List<NotificationHistoryItem> _notifications = [];
  static bool _isInitialized = false;

  /// Initialize notification history service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load existing notifications from Supabase
      await _loadNotificationsFromSupabase();
      _isInitialized = true;
      debugPrint('Notification history service initialized');
    } catch (e) {
      debugPrint('Error initializing notification history service: $e');
    }
  }

  /// Load notifications from Supabase
  static Future<void> _loadNotificationsFromSupabase() async {
    try {
      final response = await Supabase.instance.client
          .from('notificationHistoryTable')
          .select()
          .order('timestamp', ascending: false)
          .limit(100);

      _notifications.clear();
      for (final item in response) {
        _notifications.add(NotificationHistoryItem.fromJson(item));
      }
      
      debugPrint('Loaded ${_notifications.length} notifications from history');
    } catch (e) {
      debugPrint('Error loading notifications from Supabase: $e');
    }
  }

  /// Add notification to history
  static Future<void> addNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    String? driverId,
    String? routeId,
  }) async {
    try {
      final notification = NotificationHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        timestamp: DateTime.now(),
        status: NotificationStatus.sent,
        data: data,
        driverId: driverId,
        routeId: routeId,
      );

      // Add to local list
      _notifications.insert(0, notification);

      // Save to Supabase
      await Supabase.instance.client
          .from('notificationHistoryTable')
          .insert(notification.toJson());

      debugPrint('Notification added to history: ${notification.title}');
    } catch (e) {
      debugPrint('Error adding notification to history: $e');
    }
  }

  /// Get all notifications
  static List<NotificationHistoryItem> getAllNotifications() {
    return List.unmodifiable(_notifications);
  }

  /// Get unread notifications count
  static int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  /// Get recent notifications (last 20)
  static List<NotificationHistoryItem> getRecentNotifications({int limit = 20}) {
    return _notifications.take(limit).toList();
  }

  /// Get notifications by type
  static List<NotificationHistoryItem> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        
        // Update in Supabase
        await Supabase.instance.client
            .from('notificationHistoryTable')
            .update({'is_read': true})
            .eq('id', notificationId);
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      
      // Update all in Supabase
      await Supabase.instance.client
          .from('notificationHistoryTable')
          .update({'is_read': true})
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      
      // Delete from Supabase
      await Supabase.instance.client
          .from('notificationHistoryTable')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      _notifications.clear();
      
      // Clear from Supabase
      await Supabase.instance.client
          .from('notificationHistoryTable')
          .delete()
          .neq('id', '');
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
    }
  }

  /// Get notification statistics
  static Map<String, int> getNotificationStats() {
    final stats = <String, int>{};
    
    for (final type in NotificationType.values) {
      stats[type.name] = _notifications.where((n) => n.type == type).length;
    }
    
    stats['total'] = _notifications.length;
    stats['unread'] = getUnreadCount();
    stats['read'] = _notifications.where((n) => n.isRead).length;
    
    return stats;
  }

  /// Search notifications
  static List<NotificationHistoryItem> searchNotifications(String query) {
    if (query.isEmpty) return _notifications;
    
    final lowercaseQuery = query.toLowerCase();
    return _notifications.where((n) {
      return n.title.toLowerCase().contains(lowercaseQuery) ||
             n.body.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Get notifications by date range
  static List<NotificationHistoryItem> getNotificationsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _notifications.where((n) {
      return n.timestamp.isAfter(startDate) && n.timestamp.isBefore(endDate);
    }).toList();
  }
}
