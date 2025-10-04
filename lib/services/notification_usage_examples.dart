import 'package:pasada_admin_application/services/notification_service.dart';

/// Example usage of the NotificationService
/// This file demonstrates how to use the notification service in your application
class NotificationUsageExamples {
  
  /// Example: Check if driver meets quota and send notification
  static Future<void> exampleQuotaNotification() async {
    // Simulate driver data
    String driverId = 'driver_123';
    int currentRides = 25;
    int quotaTarget = 25;
    
    // Check and send quota notification
    await NotificationService.checkQuotaNotification(
      driverId: driverId,
      currentRides: currentRides,
      quotaTarget: quotaTarget,
    );
  }
  
  /// Example: Check capacity overcrowding and send notification
  static Future<void> exampleCapacityNotification() async {
    // Simulate passenger data
    String driverId = 'driver_456';
    int totalPassengers = 35; // Over 32 limit
    int sittingPassengers = 28; // Over 27 limit
    int standingPassengers = 7; // Over 5 limit
    
    // Check and send capacity notification
    await NotificationService.checkCapacityNotification(
      driverId: driverId,
      totalPassengers: totalPassengers,
      sittingPassengers: sittingPassengers,
      standingPassengers: standingPassengers,
    );
  }
  
  /// Example: Send route change notification
  static Future<void> exampleRouteChangeNotification() async {
    String driverId = 'driver_789';
    String routeId = 'route_456';
    String oldRoute = 'Route A - Downtown';
    String newRoute = 'Route B - Airport';
    
    // Send route change notification
    await NotificationService.sendRouteChangeNotification(
      driverId: driverId,
      routeId: routeId,
      oldRoute: oldRoute,
      newRoute: newRoute,
    );
  }
  
  /// Example: Send heavy rain alert notification
  static Future<void> exampleHeavyRainAlert() async {
    String location = 'Downtown Area';
    String severity = 'High';
    String expectedDuration = '2-3 hours';
    
    // Send weather alert notification
    await NotificationService.sendHeavyRainAlert(
      location: location,
      severity: severity,
      expectedDuration: expectedDuration,
    );
  }
  
  /// Example: Update notification preferences
  static Future<void> exampleUpdatePreferences() async {
    // Update specific notification types
    await NotificationService.updateNotificationPreferences(
      quotaNotifications: true,
      capacityNotifications: true,
      routeChangeNotifications: false, // Disable route change notifications
      weatherNotifications: true,
    );
  }
  
  /// Example: Get current notification preferences
  static void exampleGetPreferences() {
    final preferences = NotificationService.getNotificationPreferences();
    
    print('Quota Notifications: ${preferences['quotaNotifications']}');
    print('Capacity Notifications: ${preferences['capacityNotifications']}');
    print('Route Change Notifications: ${preferences['routeChangeNotifications']}');
    print('Weather Notifications: ${preferences['weatherNotifications']}');
  }
  
  /// Example: Check if notifications are enabled
  static void exampleCheckNotificationStatus() {
    bool isEnabled = NotificationService.isNotificationsEnabled;
    String? fcmToken = NotificationService.fcmToken;
    
    print('Notifications Enabled: $isEnabled');
    print('FCM Token: $fcmToken');
  }
}

/// Integration examples for your existing services
class NotificationIntegrationExamples {
  
  /// Example: Integrate with driver service
  static Future<void> integrateWithDriverService() async {
    // When driver completes a ride
    // Check if they've reached their quota
    await NotificationService.checkQuotaNotification(
      driverId: 'current_driver_id',
      currentRides: 30, // Current ride count
      quotaTarget: 30, // Quota target
    );
  }
  
  /// Example: Integrate with passenger counting service
  static Future<void> integrateWithPassengerService() async {
    // When passenger count changes
    // Check for overcrowding
    await NotificationService.checkCapacityNotification(
      driverId: 'current_driver_id',
      totalPassengers: 33, // Current total
      sittingPassengers: 25, // Current sitting
      standingPassengers: 8, // Current standing
    );
  }
  
  /// Example: Integrate with route management service
  static Future<void> integrateWithRouteService() async {
    // When driver changes route
    await NotificationService.sendRouteChangeNotification(
      driverId: 'current_driver_id',
      routeId: 'new_route_id',
      oldRoute: 'Previous Route Name',
      newRoute: 'New Route Name',
    );
  }
  
  /// Example: Integrate with weather service
  static Future<void> integrateWithWeatherService() async {
    // When weather service detects heavy rain
    await NotificationService.sendHeavyRainAlert(
      location: 'Current Service Area',
      severity: 'Moderate to Heavy',
      expectedDuration: '1-2 hours',
    );
  }
}
