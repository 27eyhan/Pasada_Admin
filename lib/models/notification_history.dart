import 'package:pasada_admin_application/services/notification_service.dart';

enum NotificationStatus {
  sent,
  delivered,
  read,
  clicked,
  dismissed,
}

class NotificationHistoryItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final NotificationStatus status;
  final Map<String, dynamic>? data;
  final String? driverId;
  final String? routeId;
  final bool isRead;

  NotificationHistoryItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.status,
    this.data,
    this.driverId,
    this.routeId,
    this.isRead = false,
  });

  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) {
    return NotificationHistoryItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type']?.toString(),
        orElse: () => NotificationType.systemAlert,
      ),
      timestamp: parseTimestamp(json['timestamp']),
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == json['status']?.toString(),
        orElse: () => NotificationStatus.sent,
      ),
      data: json['data'] as Map<String, dynamic>?,
      driverId: json['driver_id']?.toString(),
      routeId: json['route_id']?.toString(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  /// Parse timestamp from various formats
  static DateTime parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }
    
    if (timestamp is int) {
      // Check if it's milliseconds or seconds
      if (timestamp > 2147483647) {
        // It's in milliseconds, convert to seconds
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        // It's in seconds
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
    } else if (timestamp is String) {
      try {
        // Try to parse as ISO string
        return DateTime.parse(timestamp);
      } catch (e) {
        // If parsing fails, try to parse as Unix timestamp string
        final intValue = int.tryParse(timestamp);
        if (intValue != null) {
          return parseTimestamp(intValue);
        }
        return DateTime.now();
      }
    } else if (timestamp is DateTime) {
      // Already a DateTime object
      return timestamp;
    } else {
      // Fallback to current time
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'data': data,
      'driver_id': driverId,
      'route_id': routeId,
      'is_read': isRead,
    };
  }

  NotificationHistoryItem copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    NotificationStatus? status,
    Map<String, dynamic>? data,
    String? driverId,
    String? routeId,
    bool? isRead,
  }) {
    return NotificationHistoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      data: data ?? this.data,
      driverId: driverId ?? this.driverId,
      routeId: routeId ?? this.routeId,
      isRead: isRead ?? this.isRead,
    );
  }
}

