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
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.systemAlert,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NotificationStatus.sent,
      ),
      data: json['data'] as Map<String, dynamic>?,
      driverId: json['driver_id'] as String?,
      routeId: json['route_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
    );
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

