import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:pasada_admin_application/services/auth_service.dart';
import 'package:pasada_admin_application/services/notification_history_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Background message handler for Firebase Cloud Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');
}

enum NotificationType {
  quotaReached,
  capacityOvercrowded,
  routeChanged,
  heavyRainAlert,
  systemAlert,
}

class NotificationData {
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final String? driverId;
  final String? routeId;

  NotificationData({
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.driverId,
    this.routeId,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'type': type.name,
    'data': data,
    'driverId': driverId,
    'routeId': routeId,
  };
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final AuthService _authService = AuthService();
  
  static bool _isInitialized = false;
  static String? _fcmToken;
  
  // Notification preferences
  static bool _quotaNotifications = true;
  static bool _capacityNotifications = true;
  static bool _routeChangeNotifications = true;
  static bool _weatherNotifications = true;

  /// Initialize Firebase Cloud Messaging (without requesting permissions)
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Set up message handlers first
      _setupMessageHandlers();
      _isInitialized = true;
      debugPrint('Notification service initialized (permissions not requested yet)');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Request notification permissions and set up FCM
  static Future<bool> requestPermissions() async {
    try {
      debugPrint('Requesting notification permissions...');
      
      // Check current permission status first
      final currentStatus = await getPermissionStatus();
      debugPrint('Current permission status: $currentStatus');
      
      // If already authorized, return true
      if (currentStatus == AuthorizationStatus.authorized) {
        debugPrint('Permissions already granted');
        if (_fcmToken == null) {
          _fcmToken = await _messaging.getToken();
          await _saveTokenToSupabase(_fcmToken!);
        }
        return true;
      }
      
      // If denied, we can't request again
      if (currentStatus == AuthorizationStatus.denied) {
        debugPrint('Permissions were previously denied');
        return false;
      }
      
      // Request notification permissions - this should trigger browser popup
      debugPrint('Requesting browser permission dialog...');
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      debugPrint('Permission status after request: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
        
        // Get FCM token
        _fcmToken = await _messaging.getToken();
        debugPrint('FCM Token: $_fcmToken');
        
        // Save token to Supabase for server-side notifications
        await _saveTokenToSupabase(_fcmToken!);
        
        return true;
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('User denied notification permission');
        return false;
      } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        debugPrint('Notification permission not determined - user may have dismissed the dialog');
        return false;
      } else {
        debugPrint('Notification permission status: ${settings.authorizationStatus}');
        return false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Save FCM token to Supabase for server-side notifications
  static Future<void> _saveTokenToSupabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('user_fcm_tokens')
            .upsert({
              'user_id': user.id,
              'fcm_token': token,
              'platform': 'web',
              'updated_at': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Set up message handlers for different notification types
  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped: ${message.messageId}');
      _handleNotificationTap(message);
    });
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      // Show local notification or update UI
      _showLocalNotification(
        title: notification.title ?? 'Pasada Admin',
        body: notification.body ?? '',
        data: message.data,
      );
    }
  }

  /// Handle notification taps
  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    
    switch (type) {
      case 'quota_reached':
        _navigateToDriverDetails(data['driver_id']);
        break;
      case 'capacity_overcrowded':
        _navigateToFleetManagement();
        break;
      case 'route_changed':
        _navigateToRouteDetails(data['route_id']);
        break;
      case 'heavy_rain_alert':
        _navigateToWeatherAlerts();
        break;
      default:
        _navigateToDashboard();
    }
  }

  /// Show local notification (for foreground messages)
  static void _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    // This would typically use a local notification plugin
    // For now, we'll use a simple debug print
    debugPrint('Local Notification: $title - $body');
  }

  /// Navigation handlers
  static void _navigateToDriverDetails(String? driverId) {
    // Navigate to driver details page
    debugPrint('Navigate to driver details: $driverId');
  }

  static void _navigateToFleetManagement() {
    // Navigate to fleet management page
    debugPrint('Navigate to fleet management');
  }

  static void _navigateToRouteDetails(String? routeId) {
    // Navigate to route details page
    debugPrint('Navigate to route details: $routeId');
  }

  static void _navigateToWeatherAlerts() {
    // Navigate to weather alerts page
    debugPrint('Navigate to weather alerts');
  }

  static void _navigateToDashboard() {
    // Navigate to main dashboard
    debugPrint('Navigate to dashboard');
  }

  /// Check if driver meets quota and send notification
  static Future<void> checkQuotaNotification({
    required String driverId,
    required int currentRides,
    required int quotaTarget,
  }) async {
    if (!_quotaNotifications) return;
    
    if (currentRides >= quotaTarget) {
      await _sendNotification(NotificationData(
        title: 'Quota Target Reached! 🎯',
        body: 'Driver has completed $currentRides rides, meeting the quota of $quotaTarget rides.',
        type: NotificationType.quotaReached,
        driverId: driverId,
        data: {
          'current_rides': currentRides,
          'quota_target': quotaTarget,
        },
      ));
    }
  }

  /// Check capacity overcrowding and send notification
  static Future<void> checkCapacityNotification({
    required String driverId,
    required int totalPassengers,
    required int sittingPassengers,
    required int standingPassengers,
  }) async {
    if (!_capacityNotifications) return;
    
    bool isOvercrowded = false;
    String alertMessage = '';
    
    if (totalPassengers > 32) {
      isOvercrowded = true;
      alertMessage = 'Total capacity exceeded: $totalPassengers/32 passengers';
    } else if (sittingPassengers > 27) {
      isOvercrowded = true;
      alertMessage = 'Sitting capacity exceeded: $sittingPassengers/27 passengers';
    } else if (standingPassengers > 5) {
      isOvercrowded = true;
      alertMessage = 'Standing capacity exceeded: $standingPassengers/5 passengers';
    }
    
    if (isOvercrowded) {
      await _sendNotification(NotificationData(
        title: 'Capacity Overcrowded! ⚠️',
        body: alertMessage,
        type: NotificationType.capacityOvercrowded,
        driverId: driverId,
        data: {
          'total_passengers': totalPassengers,
          'sitting_passengers': sittingPassengers,
          'standing_passengers': standingPassengers,
        },
      ));
    }
  }

  /// Send route change notification
  static Future<void> sendRouteChangeNotification({
    required String driverId,
    required String routeId,
    required String oldRoute,
    required String newRoute,
  }) async {
    if (!_routeChangeNotifications) return;
    
    await _sendNotification(NotificationData(
      title: 'Route Changed 🛣️',
      body: 'Driver changed route from $oldRoute to $newRoute',
      type: NotificationType.routeChanged,
      driverId: driverId,
      routeId: routeId,
      data: {
        'old_route': oldRoute,
        'new_route': newRoute,
      },
    ));
  }

  /// Send heavy rain alert notification
  static Future<void> sendHeavyRainAlert({
    required String location,
    required String severity,
    required String expectedDuration,
  }) async {
    if (!_weatherNotifications) return;
    
    await _sendNotification(NotificationData(
      title: 'Heavy Rain Alert! 🌧️',
      body: 'Heavy rain expected in $location. Severity: $severity. Duration: $expectedDuration',
      type: NotificationType.heavyRainAlert,
      data: {
        'location': location,
        'severity': severity,
        'duration': expectedDuration,
      },
    ));
  }

  /// Send notification to Supabase for server-side processing
  static Future<void> _sendNotification(NotificationData notificationData) async {
    try {
      // Send to Supabase for server-side notification processing
      await Supabase.instance.client
          .from('notification_queue')
          .insert({
            'title': notificationData.title,
            'body': notificationData.body,
            'type': notificationData.type.name,
            'data': notificationData.data,
            'driver_id': notificationData.driverId,
            'route_id': notificationData.routeId,
            'created_at': DateTime.now().toIso8601String(),
          });
      
      // Add to notification history
      await NotificationHistoryService.addNotification(
        title: notificationData.title,
        body: notificationData.body,
        type: notificationData.type,
        data: notificationData.data,
        driverId: notificationData.driverId,
        routeId: notificationData.routeId,
      );
      
      debugPrint('Notification queued: ${notificationData.title}');
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// Update notification preferences
  static Future<void> updateNotificationPreferences({
    bool? quotaNotifications,
    bool? capacityNotifications,
    bool? routeChangeNotifications,
    bool? weatherNotifications,
  }) async {
    if (quotaNotifications != null) _quotaNotifications = quotaNotifications;
    if (capacityNotifications != null) _capacityNotifications = capacityNotifications;
    if (routeChangeNotifications != null) _routeChangeNotifications = routeChangeNotifications;
    if (weatherNotifications != null) _weatherNotifications = weatherNotifications;
    
    // Save to AuthService
    await _authService.setNotificationSettings(
      pushNotifications: _quotaNotifications || _capacityNotifications || 
                        _routeChangeNotifications || _weatherNotifications,
      rideUpdates: _quotaNotifications,
    );
  }

  /// Get current notification preferences
  static Map<String, bool> getNotificationPreferences() {
    return {
      'quotaNotifications': _quotaNotifications,
      'capacityNotifications': _capacityNotifications,
      'routeChangeNotifications': _routeChangeNotifications,
      'weatherNotifications': _weatherNotifications,
    };
  }

  /// Check if notifications are enabled
  static bool get isNotificationsEnabled => _isInitialized;

  /// Get FCM token
  static String? get fcmToken => _fcmToken;

  /// Check current permission status
  static Future<AuthorizationStatus> getPermissionStatus() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus;
    } catch (e) {
      debugPrint('Error checking permission status: $e');
      return AuthorizationStatus.denied;
    }
  }

  /// Check if permissions are granted
  static Future<bool> arePermissionsGranted() async {
    final status = await getPermissionStatus();
    return status == AuthorizationStatus.authorized;
  }

  /// Check if browser supports notifications
  static Future<bool> isNotificationSupported() async {
    try {
      // Try to get notification settings to check if browser supports it
      await _messaging.getNotificationSettings();
      return true;
    } catch (e) {
      debugPrint('Browser does not support notifications: $e');
      return false;
    }
  }

  /// Get detailed permission status for UI display
  static Future<Map<String, dynamic>> getDetailedPermissionStatus() async {
    try {
      final status = await getPermissionStatus();
      final isSupported = await isNotificationSupported();
      
      String statusText;
      String description;
      bool canRequest = false;
      
      switch (status) {
        case AuthorizationStatus.authorized:
          statusText = 'Enabled';
          description = 'Notifications are enabled and working';
          canRequest = false;
          break;
        case AuthorizationStatus.denied:
          statusText = 'Blocked';
          description = 'Notifications are blocked. Enable them in browser settings';
          canRequest = false;
          break;
        case AuthorizationStatus.notDetermined:
          statusText = 'Not Requested';
          description = 'Click to enable notifications';
          canRequest = true;
          break;
        case AuthorizationStatus.provisional:
          statusText = 'Provisional';
          description = 'Notifications are in provisional mode';
          canRequest = true;
          break;
        }
      
      return {
        'status': status,
        'statusText': statusText,
        'description': description,
        'canRequest': canRequest,
        'isSupported': isSupported,
        'hasToken': _fcmToken != null,
      };
    } catch (e) {
      debugPrint('Error getting detailed permission status: $e');
      return {
        'status': AuthorizationStatus.denied,
        'statusText': 'Error',
        'description': 'Unable to check notification status',
        'canRequest': false,
        'isSupported': false,
        'hasToken': false,
      };
    }
  }

  /// Show permission request dialog (for first-time users)
  static Future<void> showPermissionRequestDialog(BuildContext context) async {
    final status = await getPermissionStatus();
    
    if (status == AuthorizationStatus.notDetermined) {
      // Show dialog explaining why notifications are needed
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.notifications, color: Colors.blue),
                SizedBox(width: 12),
                Text('Enable Notifications'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stay informed about your fleet with real-time notifications:'),
                SizedBox(height: 12),
                Text('• Driver quota achievements'),
                Text('• Vehicle capacity alerts'),
                Text('• Route changes'),
                Text('• Weather warnings'),
                SizedBox(height: 12),
                Text('Would you like to enable notifications?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Not Now'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await requestPermissions();
                },
                child: Text('Enable'),
              ),
            ],
          );
        },
      );
    }
  }
}
