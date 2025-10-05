import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationTransferService {
  /// Transfer notifications from queue to history table
  static Future<int> transferNotificationsToHistory() async {
    try {
      final response = await Supabase.instance.client
          .rpc('transfer_notifications_to_history');
      
      final transferredCount = response as int;
      debugPrint('Transferred $transferredCount notifications to history');
      
      return transferredCount;
    } catch (e) {
      debugPrint('Error transferring notifications: $e');
      rethrow;
    }
  }

  /// Clean up old notifications from queue
  static Future<int> cleanupOldNotifications() async {
    try {
      final response = await Supabase.instance.client
          .rpc('cleanup_old_notifications');
      
      final cleanedCount = response as int;
      debugPrint('Cleaned up $cleanedCount old notifications');
      
      return cleanedCount;
    } catch (e) {
      debugPrint('Error cleaning up notifications: $e');
      rethrow;
    }
  }

  /// Get queue statistics
  static Future<Map<String, dynamic>> getQueueStatistics() async {
    try {
      final queueResponse = await Supabase.instance.client
          .from('notificationQueueTable')
          .select('status')
          .order('created_at', ascending: false);

      final historyResponse = await Supabase.instance.client
          .from('notificationHistoryTable')
          .select('status')
          .order('timestamp', ascending: false);

      final queueCount = queueResponse.length;
      final historyCount = historyResponse.length;

      // Count by status
      final queueByStatus = <String, int>{};
      final historyByStatus = <String, int>{};

      for (final item in queueResponse) {
        final status = item['status'] as String? ?? 'unknown';
        queueByStatus[status] = (queueByStatus[status] ?? 0) + 1;
      }

      for (final item in historyResponse) {
        final status = item['status'] as String? ?? 'unknown';
        historyByStatus[status] = (historyByStatus[status] ?? 0) + 1;
      }

      return {
        'queue_total': queueCount,
        'history_total': historyCount,
        'queue_by_status': queueByStatus,
        'history_by_status': historyByStatus,
      };
    } catch (e) {
      debugPrint('Error getting queue statistics: $e');
      return {
        'queue_total': 0,
        'history_total': 0,
        'queue_by_status': <String, int>{},
        'history_by_status': <String, int>{},
      };
    }
  }

  /// Check if transfer is needed
  static Future<bool> isTransferNeeded() async {
    try {
      final response = await Supabase.instance.client
          .from('notificationQueueTable')
          .select('id')
          .inFilter('status', ['sent', 'delivered', 'read'])
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if transfer is needed: $e');
      return false;
    }
  }

  /// Get notifications that need transfer
  static Future<List<Map<String, dynamic>>> getNotificationsNeedingTransfer() async {
    try {
      final response = await Supabase.instance.client
          .from('notificationQueueTable')
          .select('*')
          .inFilter('status', ['sent', 'delivered', 'read'])
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting notifications needing transfer: $e');
      return [];
    }
  }

  /// Manual transfer with progress tracking
  static Future<Map<String, dynamic>> manualTransferWithProgress() async {
    try {
      final notifications = await getNotificationsNeedingTransfer();
      final totalCount = notifications.length;
      int transferredCount = 0;
      int errorCount = 0;
      final errors = <String>[];

      debugPrint('Starting manual transfer of $totalCount notifications');

      for (final notification in notifications) {
        try {
          // Convert timestamp if needed
          int timestamp = notification['timestamp'] as int;
          if (timestamp > 2147483647) {
            timestamp = timestamp ~/ 1000;
          }

          // Insert into history
          await Supabase.instance.client
              .from('notificationHistoryTable')
              .insert({
                'title': notification['title'],
                'body': notification['body'],
                'type': notification['type'],
                'timestamp': timestamp,
                'status': notification['status'],
                'data': notification['data'],
                'driver_id': notification['driver_id'],
                'route_id': notification['route_id'],
                'is_read': notification['status'] == 'read',
                'created_at': notification['created_at'] ?? DateTime.now().toIso8601String(),
              });

          // Delete from queue
          await Supabase.instance.client
              .from('notificationQueueTable')
              .delete()
              .eq('id', notification['id']);

          transferredCount++;
        } catch (e) {
          errorCount++;
          errors.add('Notification ${notification['id']}: $e');
          debugPrint('Error transferring notification ${notification['id']}: $e');
        }
      }

      return {
        'total': totalCount,
        'transferred': transferredCount,
        'errors': errorCount,
        'error_details': errors,
        'success': errorCount == 0,
      };
    } catch (e) {
      debugPrint('Error in manual transfer: $e');
      return {
        'total': 0,
        'transferred': 0,
        'errors': 1,
        'error_details': ['General error: $e'],
        'success': false,
      };
    }
  }
}
