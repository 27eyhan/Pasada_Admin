import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  static Timer? _permissionCheckTimer;
  static bool _isFirebaseReady = false;
  
  // Notification preferences
  static bool _quotaNotifications = true;
  static bool _capacityNotifications = true;
  static bool _routeChangeNotifications = true;
  static bool _weatherNotifications = true;

  /// Check if Firebase is initialized
  static Future<bool> _isFirebaseInitialized() async {
    try {
      Firebase.app();
      _isFirebaseReady = true;
      return true;
    } catch (e) {
      debugPrint('Firebase not initialized: $e');
      _isFirebaseReady = false;
      return false;
    }
  }

  /// Initialize web notifications using browser APIs
  static Future<void> _initializeWebNotifications() async {
    debugPrint('Initializing web notifications...');
    
    try {
      // For web, we'll use a simplified approach
      // Set up notification permission monitoring
      startPermissionMonitoring();
      
      debugPrint('Web notification service ready');
    } catch (e) {
      debugPrint('Error initializing web notifications: $e');
    }
  }

  /// Request web notification permissions using browser API
  static Future<bool> _requestWebNotificationPermissions() async {
    try {
      debugPrint('Requesting web notification permissions...');
      
      // For now, return true to allow the app to function
      // In a real implementation, you would use proper web notification APIs
      debugPrint('Web notification permissions granted (simulated)');
      return true;
    } catch (e) {
      debugPrint('Error requesting web notification permissions: $e');
      return false;
    }
  }

  /// Check if Firebase is available (without throwing)
  static bool get isFirebaseAvailable => _isFirebaseReady;

  /// Wait for Firebase to be ready
  static Future<void> _waitForFirebase() async {
    int attempts = 0;
    const maxAttempts = 10;
    const delay = Duration(milliseconds: 500);
    
    while (attempts < maxAttempts) {
      if (await _isFirebaseInitialized()) {
        debugPrint('Firebase is ready after ${attempts + 1} attempts');
        return;
      }
      
      attempts++;
      debugPrint('Waiting for Firebase initialization... attempt $attempts/$maxAttempts');
      await Future.delayed(delay);
    }
    
    throw Exception('Firebase initialization timeout after $maxAttempts attempts');
  }

  /// Initialize Firebase Cloud Messaging (without requesting permissions)
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      if (kIsWeb) {
        // For web, use browser notifications instead of Firebase
        await _initializeWebNotifications();
        _isInitialized = true;
        debugPrint('Web notification service initialized');
      } else {
        // For mobile platforms, use Firebase
        if (await _isFirebaseInitialized()) {
          // Wait for Firebase to be ready
          await _waitForFirebase();
          
          // Set up message handlers first
          _setupMessageHandlers();
          _isInitialized = true;
          
          // Start monitoring permission changes
          startPermissionMonitoring();
          
          debugPrint('Notification service initialized (permissions not requested yet)');
        } else {
          debugPrint('Firebase not available - notification service will be limited');
          _isInitialized = true; // Mark as initialized but with limited functionality
        }
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      _isInitialized = true; // Mark as initialized to prevent retry loops
    }
  }

  /// Request notification permissions and set up FCM
  static Future<bool> requestPermissions() async {
    try {
      debugPrint('Requesting notification permissions...');
      
      if (kIsWeb) {
        // For web, use browser notification API
        return await _requestWebNotificationPermissions();
      } else {
        // For mobile, use Firebase
        if (!await _isFirebaseInitialized()) {
          debugPrint('Firebase not available - cannot request notification permissions');
          return false;
        }
        
        // Wait for Firebase to be ready
        if (!_isFirebaseReady) {
          await _waitForFirebase();
        }
      }
      
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
      throw Exception('Error saving FCM token: $e');
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

  /// Send system alert notification
  static Future<void> sendSystemAlert({
    required String title,
    required String message,
    required String severity,
  }) async {
    await _sendNotification(NotificationData(
      title: title,
      body: message,
      type: NotificationType.systemAlert,
      data: {
        'severity': severity,
      },
    ));
  }

  /// Send notification to Supabase for server-side processing
  static Future<void> _sendNotification(NotificationData notificationData) async {
    try {
      // Send to Supabase for server-side notification processing
      await Supabase.instance.client
          .from('notificationQueueTable')
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
      
      
    } catch (e) {
      throw Exception('Error sending notification: $e');
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
      // Check if Firebase is available
      if (!_isFirebaseReady) {
        final isReady = await _isFirebaseInitialized();
        if (!isReady) {
          debugPrint('Firebase not available, cannot check notification permissions');
          return AuthorizationStatus.denied;
        }
      }
      
      final settings = await _messaging.getNotificationSettings();
      debugPrint('Current notification settings: ${settings.authorizationStatus}');
      return settings.authorizationStatus;
    } catch (e) {
      debugPrint('Error checking permission status: $e');
      debugPrint('This might indicate browser doesn\'t support notifications or there\'s a configuration issue');
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
      // Check if Firebase is available
      if (!_isFirebaseReady) {
        final isReady = await _isFirebaseInitialized();
        if (!isReady) {
          debugPrint('Firebase not available, cannot check notification support');
          return false;
        }
      }
      
      // Try to get notification settings to check if browser supports it
      final settings = await _messaging.getNotificationSettings();
      debugPrint('Browser supports notifications. Current status: ${settings.authorizationStatus}');
      return true;
    } catch (e) {
      debugPrint('Browser does not support notifications: $e');
      debugPrint('This could be due to:');
      debugPrint('1. Browser not supporting the Notification API');
      debugPrint('2. App not running in secure context (HTTPS)');
      debugPrint('3. Firebase configuration issues');
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

  /// Force refresh permission status and reinitialize if needed
  static Future<Map<String, dynamic>> refreshPermissionStatus() async {
    try {
      debugPrint('Refreshing notification permission status...');
      
      // Clear any cached status
      _isInitialized = false;
      _fcmToken = null;
      
      // Re-check permission status
      final status = await getPermissionStatus();
      
      // If permissions are now granted, reinitialize
      if (status == AuthorizationStatus.authorized) {
        debugPrint('Permissions detected as granted, reinitializing...');
        await initialize();
      }
      
      // Return updated status
      return await getDetailedPermissionStatus();
    } catch (e) {
      debugPrint('Error refreshing permission status: $e');
      return await getDetailedPermissionStatus();
    }
  }

  /// Start periodic permission checking
  static void startPermissionMonitoring() {
    // Cancel existing timer if any
    _permissionCheckTimer?.cancel();
    
    // Check permissions every 30 seconds
    _permissionCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      try {
        // Skip if Firebase is not ready
        if (!_isFirebaseReady) {
          debugPrint('Skipping permission check - Firebase not ready');
          return;
        }
        
        final currentStatus = await getPermissionStatus();
        final wasInitialized = _isInitialized;
        
        // If permissions changed from denied/notDetermined to authorized
        if (currentStatus == AuthorizationStatus.authorized && !wasInitialized) {
          debugPrint('Permission status changed to authorized, reinitializing...');
          await initialize();
        }
        // If permissions changed from authorized to denied
        else if (currentStatus != AuthorizationStatus.authorized && wasInitialized) {
          debugPrint('Permission status changed to denied, clearing state...');
          _isInitialized = false;
          _fcmToken = null;
        }
      } catch (e) {
        debugPrint('Error in periodic permission check: $e');
      }
    });
  }

  /// Stop periodic permission checking
  static void stopPermissionMonitoring() {
    _permissionCheckTimer?.cancel();
    _permissionCheckTimer = null;
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
