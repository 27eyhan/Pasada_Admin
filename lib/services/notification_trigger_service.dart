import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/services/notification_service.dart';

/// Service to automatically trigger notifications based on system changes
class NotificationTriggerService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  // Timer for periodic monitoring
  static Timer? _monitoringTimer;
  
  // Configuration for monitoring intervals
  static const Duration _defaultMonitoringInterval = Duration(minutes: 2);
  static Duration _monitoringInterval = _defaultMonitoringInterval;
  
  // Monitoring state
  static bool _isMonitoring = false;
  
  // Retry configuration
  static int _maxRetryAttempts = 3;
  static Duration _baseRetryDelay = const Duration(seconds: 5);
  static Duration _maxRetryDelay = const Duration(minutes: 5);
  static int _consecutiveFailures = 0;
  static int _circuitBreakerThreshold = 5;
  static bool _circuitBreakerOpen = false;
  static DateTime? _circuitBreakerOpenTime;
  static Duration _circuitBreakerTimeout = const Duration(minutes: 10);
  
  /// Monitor vehicle capacity changes and trigger notifications
  static Future<void> monitorVehicleCapacityChanges() async {
    try {
      // Get all vehicles with their current passenger counts
      final response = await _supabase
          .from('vehicleTable')
          .select('vehicle_id, plate_number, passenger_capacity, sitting_passenger, standing_passenger, driverTable!left(driver_id, full_name)');
      
      for (final vehicle in response) {
        final vehicleId = vehicle['vehicle_id'];
        final plateNumber = vehicle['plate_number'] ?? 'Unknown';
        final capacity = vehicle['passenger_capacity'] as int? ?? 0;
        final sittingPassengers = vehicle['sitting_passenger'] as int? ?? 0;
        final standingPassengers = vehicle['standing_passenger'] as int? ?? 0;
        final totalPassengers = sittingPassengers + standingPassengers;
        
        // Get driver info
        final driverData = vehicle['driverTable'];
        String? driverId;
        String? driverName;
        if (driverData != null && driverData is List && driverData.isNotEmpty) {
          final driver = driverData.first as Map<String, dynamic>;
          driverId = driver['driver_id']?.toString();
          driverName = driver['full_name'];
        }
        
        // Check for capacity violations
        await _checkVehicleCapacityViolations(
          vehicleId: vehicleId,
          plateNumber: plateNumber,
          capacity: capacity,
          totalPassengers: totalPassengers,
          sittingPassengers: sittingPassengers,
          standingPassengers: standingPassengers,
          driverId: driverId,
          driverName: driverName,
        );
      }
    } catch (e) {
      // Handle error silently to avoid disrupting the main application
    }
  }
  
  /// Check for vehicle capacity violations and send notifications
  static Future<void> _checkVehicleCapacityViolations({
    required int vehicleId,
    required String plateNumber,
    required int capacity,
    required int totalPassengers,
    required int sittingPassengers,
    required int standingPassengers,
    String? driverId,
    String? driverName,
  }) async {
    bool shouldNotify = false;
    
    // Check total capacity (32 max)
    if (totalPassengers > 32) {
      shouldNotify = true;
    }
    // Check sitting capacity (27 max)
    else if (sittingPassengers > 27) {
      shouldNotify = true;
    }
    // Check standing capacity (5 max)
    else if (standingPassengers > 5) {
      shouldNotify = true;
    }
    // Check if approaching limits (80% threshold)
    else if (totalPassengers >= (32 * 0.8).round()) {
      shouldNotify = true;
    }
    
    if (shouldNotify) {
      await NotificationService.checkCapacityNotification(
        driverId: driverId ?? 'system',
        totalPassengers: totalPassengers,
        sittingPassengers: sittingPassengers,
        standingPassengers: standingPassengers,
      );
    }
  }
  
  /// Monitor driver status changes and trigger notifications
  static Future<void> monitorDriverStatusChanges() async {
    try {
      // Get all drivers with their current status
      final response = await _supabase
          .from('driverTable')
          .select('driver_id, full_name, driving_status, vehicle_id, vehicleTable!left(plate_number)');
      
      for (final driver in response) {
        final driverId = driver['driver_id'];
        final driverName = driver['full_name'] ?? 'Unknown Driver';
        final status = driver['driving_status'] ?? 'offline';
        final vehicleData = driver['vehicleTable'];
        String? plateNumber;
        
        if (vehicleData != null && vehicleData is List && vehicleData.isNotEmpty) {
          final vehicle = vehicleData.first as Map<String, dynamic>;
          plateNumber = vehicle['plate_number'];
        }
        
        // Check for status changes that should trigger notifications
        await _checkDriverStatusNotifications(
          driverId: driverId,
          driverName: driverName,
          status: status,
          plateNumber: plateNumber,
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  /// Check driver status and send appropriate notifications
  static Future<void> _checkDriverStatusNotifications({
    required int driverId,
    required String driverName,
    required String status,
    String? plateNumber,
  }) async {
    String title;
    String message;
    
    switch (status.toLowerCase()) {
      case 'online':
        title = 'Driver Online! 🟢';
        message = '$driverName is now online${plateNumber != null ? ' (Vehicle: $plateNumber)' : ''}';
        break;
      case 'driving':
        title = 'Driver Started Route! 🚌';
        message = '$driverName has started driving${plateNumber != null ? ' (Vehicle: $plateNumber)' : ''}';
        break;
      case 'idling':
        title = 'Driver Idling! ⏸️';
        message = '$driverName is currently idling${plateNumber != null ? ' (Vehicle: $plateNumber)' : ''}';
        break;
      case 'offline':
        title = 'Driver Offline! 🔴';
        message = '$driverName has gone offline${plateNumber != null ? ' (Vehicle: $plateNumber)' : ''}';
        break;
      default:
        return; // No notification for unknown status
    }
    
    await NotificationService.sendSystemAlert(
      title: title,
      message: message,
      severity: status.toLowerCase() == 'offline' ? 'high' : 'medium',
    );
  }
  
  /// Monitor quota changes and trigger notifications
  static Future<void> monitorQuotaChanges() async {
    try {
      // Get quota data for all drivers
      final response = await _supabase
          .from('driverQuotasTable')
          .select('driver_id, daily_target, daily_current, weekly_target, weekly_current, monthly_target, monthly_current, driverTable!left(full_name)');
      
      for (final quota in response) {
        final driverId = quota['driver_id'];
        
        // Check daily quota
        final dailyTarget = quota['daily_target'] as int? ?? 0;
        final dailyCurrent = quota['daily_current'] as int? ?? 0;
        
        if (dailyTarget > 0 && dailyCurrent >= dailyTarget) {
          await NotificationService.checkQuotaNotification(
            driverId: driverId.toString(),
            currentRides: dailyCurrent,
            quotaTarget: dailyTarget,
          );
        }
        
        // Check weekly quota
        final weeklyTarget = quota['weekly_target'] as int? ?? 0;
        final weeklyCurrent = quota['weekly_current'] as int? ?? 0;
        
        if (weeklyTarget > 0 && weeklyCurrent >= weeklyTarget) {
          await NotificationService.checkQuotaNotification(
            driverId: driverId.toString(),
            currentRides: weeklyCurrent,
            quotaTarget: weeklyTarget,
          );
        }
        
        // Check monthly quota
        final monthlyTarget = quota['monthly_target'] as int? ?? 0;
        final monthlyCurrent = quota['monthly_current'] as int? ?? 0;
        
        if (monthlyTarget > 0 && monthlyCurrent >= monthlyTarget) {
          await NotificationService.checkQuotaNotification(
            driverId: driverId.toString(),
            currentRides: monthlyCurrent,
            quotaTarget: monthlyTarget,
          );
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  /// Monitor route changes and trigger notifications
  static Future<void> monitorRouteChanges() async {
    try {
      // Get vehicles with route information
      final response = await _supabase
          .from('vehicleTable')
          .select('vehicle_id, plate_number, route_id, driverTable!left(driver_id, full_name), official_routes!left(route_name, origin_name, destination_name)');
      
      for (final vehicle in response) {
        final routeId = vehicle['route_id'];
        final driverData = vehicle['driverTable'];
        final routeData = vehicle['official_routes'];
        
        String? driverName;
        if (driverData != null && driverData is List && driverData.isNotEmpty) {
          final driver = driverData.first as Map<String, dynamic>;
          driverName = driver['full_name'];
        }
        
        String? routeName;
        if (routeData != null && routeData is List && routeData.isNotEmpty) {
          final route = routeData.first as Map<String, dynamic>;
          routeName = route['route_name'];
        }
        
        // Send route change notification if route information is available
        if (routeName != null && driverName != null) {
          await NotificationService.sendRouteChangeNotification(
            driverId: driverData.first['driver_id']?.toString() ?? 'unknown',
            routeId: routeId?.toString() ?? 'unknown',
            oldRoute: 'Previous Route',
            newRoute: routeName,
          );
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  /// Start monitoring all system changes
  static Future<void> startMonitoring() async {
    // Monitor vehicle capacity changes
    await monitorVehicleCapacityChanges();
    
    // Monitor driver status changes
    await monitorDriverStatusChanges();
    
    // Monitor quota changes
    await monitorQuotaChanges();
    
    // Monitor route changes
    await monitorRouteChanges();
  }
  
  /// Set up periodic monitoring (call this from main app)
  static void setupPeriodicMonitoring({
    Duration? interval,
    bool startImmediately = true,
  }) {
    // Cancel existing timer if running
    stopPeriodicMonitoring();
    
    // Set custom interval if provided
    if (interval != null) {
      _monitoringInterval = interval;
    } else {
      _monitoringInterval = _defaultMonitoringInterval;
    }
    
    // Start monitoring if requested
    if (startImmediately) {
      startPeriodicMonitoring();
    }
  }
  
  /// Start periodic monitoring with the configured interval
  static void startPeriodicMonitoring() {
    if (_isMonitoring) {
      return; // Already monitoring
    }
    
    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(_monitoringInterval, (timer) async {
      await _executeMonitoringWithRetry();
    });
  }
  
  /// Stop periodic monitoring
  static void stopPeriodicMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _isMonitoring = false;
  }
  
  /// Check if monitoring is currently active
  static bool get isMonitoring => _isMonitoring;
  
  /// Get current monitoring interval
  static Duration get monitoringInterval => _monitoringInterval;
  
  /// Update monitoring interval (restarts monitoring if active)
  static void updateMonitoringInterval(Duration newInterval) {
    final wasMonitoring = _isMonitoring;
    stopPeriodicMonitoring();
    _monitoringInterval = newInterval;
    if (wasMonitoring) {
      startPeriodicMonitoring();
    }
  }
  
  /// Get monitoring status information
  static Map<String, dynamic> getMonitoringStatus() {
    return {
      'isMonitoring': _isMonitoring,
      'interval': _monitoringInterval.inMinutes,
      'defaultInterval': _defaultMonitoringInterval.inMinutes,
    };
  }
  
  /// Pause monitoring temporarily (can be resumed)
  static void pauseMonitoring() {
    stopPeriodicMonitoring();
  }
  
  /// Resume monitoring with current settings
  static void resumeMonitoring() {
    if (!_isMonitoring) {
      startPeriodicMonitoring();
    }
  }
  
  /// Reset to default monitoring settings
  static void resetToDefaults() {
    final wasMonitoring = _isMonitoring;
    stopPeriodicMonitoring();
    _monitoringInterval = _defaultMonitoringInterval;
    if (wasMonitoring) {
      startPeriodicMonitoring();
    }
  }
  
  /// Manually trigger monitoring (useful for testing or immediate checks)
  static Future<void> triggerManualMonitoring() async {
    try {
      await startMonitoring();
    } catch (e) {
      debugPrint('Error in manual monitoring trigger: $e');
      rethrow; // Re-throw for manual triggers so caller can handle
    }
  }
  
  /// Execute monitoring with retry logic
  static Future<void> _executeMonitoringWithRetry() async {
    // Check circuit breaker
    if (_circuitBreakerOpen) {
      if (_circuitBreakerOpenTime != null && 
          DateTime.now().difference(_circuitBreakerOpenTime!) > _circuitBreakerTimeout) {
        // Reset circuit breaker after timeout
        _circuitBreakerOpen = false;
        _consecutiveFailures = 0;
        _circuitBreakerOpenTime = null;
        debugPrint('Circuit breaker reset - attempting monitoring again');
      } else {
        debugPrint('Circuit breaker is open - skipping monitoring cycle');
        return;
      }
    }
    
    int attempt = 0;
    Exception? lastException;
    
    while (attempt < _maxRetryAttempts) {
      try {
        await startMonitoring();
        
        // Success - reset failure counters
        _consecutiveFailures = 0;
        _circuitBreakerOpen = false;
        _circuitBreakerOpenTime = null;
        return;
        
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        attempt++;
        _consecutiveFailures++;
        
        debugPrint('Monitoring attempt $attempt failed: $e');
        
        // Check if we should open circuit breaker
        if (_consecutiveFailures >= _circuitBreakerThreshold) {
          _circuitBreakerOpen = true;
          _circuitBreakerOpenTime = DateTime.now();
          debugPrint('Circuit breaker opened due to $_consecutiveFailures consecutive failures');
          return;
        }
        
        // If this was the last attempt, don't wait
        if (attempt >= _maxRetryAttempts) {
          break;
        }
        
        // Calculate exponential backoff delay
        final delay = _calculateRetryDelay(attempt);
        debugPrint('Retrying in ${delay.inSeconds} seconds...');
        await Future.delayed(delay);
      }
    }
    
    // All retry attempts failed
    debugPrint('All monitoring retry attempts failed. Last error: $lastException');
  }
  
  /// Calculate exponential backoff delay with jitter
  static Duration _calculateRetryDelay(int attempt) {
    // Exponential backoff: baseDelay * (2^attempt)
    final exponentialDelay = _baseRetryDelay.inMilliseconds * (1 << (attempt - 1));
    
    // Cap at maximum delay
    final cappedDelay = exponentialDelay > _maxRetryDelay.inMilliseconds 
        ? _maxRetryDelay.inMilliseconds 
        : exponentialDelay;
    
    // Add jitter (±25% random variation)
    final jitterRange = (cappedDelay * 0.25).round();
    final jitter = (DateTime.now().millisecondsSinceEpoch % (jitterRange * 2)) - jitterRange;
    
    return Duration(milliseconds: cappedDelay + jitter);
  }
  
  /// Get retry and circuit breaker status
  static Map<String, dynamic> getRetryStatus() {
    return {
      'consecutiveFailures': _consecutiveFailures,
      'circuitBreakerOpen': _circuitBreakerOpen,
      'circuitBreakerOpenTime': _circuitBreakerOpenTime?.toIso8601String(),
      'maxRetryAttempts': _maxRetryAttempts,
      'circuitBreakerThreshold': _circuitBreakerThreshold,
      'baseRetryDelay': _baseRetryDelay.inSeconds,
      'maxRetryDelay': _maxRetryDelay.inSeconds,
    };
  }
  
  /// Reset retry and circuit breaker state
  static void resetRetryState() {
    _consecutiveFailures = 0;
    _circuitBreakerOpen = false;
    _circuitBreakerOpenTime = null;
    debugPrint('Retry state reset');
  }
  
  /// Force close circuit breaker (for manual recovery)
  static void forceCloseCircuitBreaker() {
    _circuitBreakerOpen = false;
    _consecutiveFailures = 0;
    _circuitBreakerOpenTime = null;
    debugPrint('Circuit breaker manually closed');
  }
  
  /// Update retry configuration
  static void updateRetryConfiguration({
    int? maxRetryAttempts,
    Duration? baseRetryDelay,
    Duration? maxRetryDelay,
    int? circuitBreakerThreshold,
    Duration? circuitBreakerTimeout,
  }) {
    bool configChanged = false;
    
    if (maxRetryAttempts != null && maxRetryAttempts > 0) {
      _maxRetryAttempts = maxRetryAttempts;
      configChanged = true;
      debugPrint('Updated maxRetryAttempts to $maxRetryAttempts');
    }
    
    if (baseRetryDelay != null) {
      _baseRetryDelay = baseRetryDelay;
      configChanged = true;
      debugPrint('Updated baseRetryDelay to ${baseRetryDelay.inSeconds}s');
    }
    
    if (maxRetryDelay != null) {
      _maxRetryDelay = maxRetryDelay;
      configChanged = true;
      debugPrint('Updated maxRetryDelay to ${maxRetryDelay.inSeconds}s');
    }
    
    if (circuitBreakerThreshold != null && circuitBreakerThreshold > 0) {
      _circuitBreakerThreshold = circuitBreakerThreshold;
      configChanged = true;
      debugPrint('Updated circuitBreakerThreshold to $circuitBreakerThreshold');
    }
    
    if (circuitBreakerTimeout != null) {
      _circuitBreakerTimeout = circuitBreakerTimeout;
      configChanged = true;
      debugPrint('Updated circuitBreakerTimeout to ${circuitBreakerTimeout.inMinutes}m');
    }
    
    if (configChanged) {
      debugPrint('Retry configuration updated successfully');
    } else {
      debugPrint('No valid configuration changes provided');
    }
  }
  
  /// Get comprehensive monitoring status including retry information
  static Map<String, dynamic> getComprehensiveStatus() {
    final monitoringStatus = getMonitoringStatus();
    final retryStatus = getRetryStatus();
    
    return {
      ...monitoringStatus,
      'retry': retryStatus,
    };
  }
  
  /// Test retry logic with simulated failures (for development/testing)
  static Future<void> testRetryLogic({int simulatedFailures = 2}) async {
    debugPrint('Testing retry logic with $simulatedFailures simulated failures...');
    
    // Reset retry state for clean test
    resetRetryState();
    
    // Simulate failures by creating a test version of the monitoring
    int failureCount = 0;
    
    // Create a test version that simulates failures
    Future<void> testMonitoring() async {
      failureCount++;
      if (failureCount <= simulatedFailures) {
        throw Exception('Simulated failure #$failureCount');
      }
      // After simulated failures, call the real monitoring
      await startMonitoring();
    };
    
    try {
      // Override the monitoring call for testing
      await _executeMonitoringWithRetryTest(testMonitoring);
      debugPrint('Retry logic test completed successfully');
    } catch (e) {
      debugPrint('Retry logic test failed: $e');
    }
  }
  
  /// Test version of execute monitoring with retry
  static Future<void> _executeMonitoringWithRetryTest(Future<void> Function() testMonitoring) async {
    // Check circuit breaker
    if (_circuitBreakerOpen) {
      if (_circuitBreakerOpenTime != null && 
          DateTime.now().difference(_circuitBreakerOpenTime!) > _circuitBreakerTimeout) {
        // Reset circuit breaker after timeout
        _circuitBreakerOpen = false;
        _consecutiveFailures = 0;
        _circuitBreakerOpenTime = null;
        debugPrint('Circuit breaker reset - attempting monitoring again');
      } else {
        debugPrint('Circuit breaker is open - skipping monitoring cycle');
        return;
      }
    }
    
    int attempt = 0;
    Exception? lastException;
    
    while (attempt < _maxRetryAttempts) {
      try {
        await testMonitoring();
        
        // Success - reset failure counters
        _consecutiveFailures = 0;
        _circuitBreakerOpen = false;
        _circuitBreakerOpenTime = null;
        return;
        
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        attempt++;
        _consecutiveFailures++;
        
        debugPrint('Monitoring attempt $attempt failed: $e');
        
        // Check if we should open circuit breaker
        if (_consecutiveFailures >= _circuitBreakerThreshold) {
          _circuitBreakerOpen = true;
          _circuitBreakerOpenTime = DateTime.now();
          debugPrint('Circuit breaker opened due to $_consecutiveFailures consecutive failures');
          return;
        }
        
        // If this was the last attempt, don't wait
        if (attempt >= _maxRetryAttempts) {
          break;
        }
        
        // Calculate exponential backoff delay
        final delay = _calculateRetryDelay(attempt);
        debugPrint('Retrying in ${delay.inSeconds} seconds...');
        await Future.delayed(delay);
      }
    }
    
    // All retry attempts failed
    debugPrint('All monitoring retry attempts failed. Last error: $lastException');
  }
}
