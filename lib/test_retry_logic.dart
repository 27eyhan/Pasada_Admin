import 'package:pasada_admin_application/services/notification_trigger_service.dart';
import 'package:flutter/foundation.dart';

/// Example usage of the retry logic in NotificationTriggerService
class RetryLogicExample {
  
  /// Demonstrate how to use the retry logic
  static Future<void> demonstrateRetryLogic() async {
    debugPrint('=== Retry Logic Demonstration ===\n');
    
    // 1. Show current status
    debugPrint('1. Current monitoring status:');
    final status = NotificationTriggerService.getComprehensiveStatus();
    debugPrint('   Monitoring active: ${status['isMonitoring']}');
    debugPrint('   Retry attempts: ${status['retry']['maxRetryAttempts']}');
    debugPrint('   Circuit breaker: ${status['retry']['circuitBreakerOpen']}\n');
    
    // 2. Configure retry settings
    debugPrint('2. Configuring retry settings...');
    NotificationTriggerService.updateRetryConfiguration(
      maxRetryAttempts: 5,
      baseRetryDelay: const Duration(seconds: 2),
      maxRetryDelay: const Duration(minutes: 2),
      circuitBreakerThreshold: 3,
      circuitBreakerTimeout: const Duration(minutes: 5),
    );
    debugPrint('   Retry configuration updated\n');
    
    // 3. Test retry logic with simulated failures
    debugPrint('3. Testing retry logic with 2 simulated failures...');
    await NotificationTriggerService.testRetryLogic(simulatedFailures: 2);
    debugPrint('');
    
    // 4. Show retry status after test
    debugPrint('4. Retry status after test:');
    final retryStatus = NotificationTriggerService.getRetryStatus();
    debugPrint('   Consecutive failures: ${retryStatus['consecutiveFailures']}');
    debugPrint('   Circuit breaker open: ${retryStatus['circuitBreakerOpen']}\n');
    
    // 5. Reset retry state
    debugPrint('5. Resetting retry state...');
    NotificationTriggerService.resetRetryState();
    debugPrint('   Retry state reset\n');
    
    // 6. Test circuit breaker
    debugPrint('6. Testing circuit breaker with 4 consecutive failures...');
    await NotificationTriggerService.testRetryLogic(simulatedFailures: 4);
    debugPrint('');
    
    // 7. Show final status
    debugPrint('7. Final status:');
    final finalStatus = NotificationTriggerService.getRetryStatus();
    debugPrint('   Consecutive failures: ${finalStatus['consecutiveFailures']}');
    debugPrint('   Circuit breaker open: ${finalStatus['circuitBreakerOpen']}');
    debugPrint('   Circuit breaker opened at: ${finalStatus['circuitBreakerOpenTime']}\n');
    
    // 8. Force close circuit breaker
    debugPrint('8. Force closing circuit breaker...');
    NotificationTriggerService.forceCloseCircuitBreaker();
    debugPrint('   Circuit breaker manually closed\n');
    
    debugPrint('=== Retry Logic Demonstration Complete ===');
  }
  
  /// Example of how to set up monitoring with custom retry settings
  static void setupCustomMonitoring() {
    debugPrint('Setting up custom monitoring with retry logic...');
    
    // Configure retry settings for production
    NotificationTriggerService.updateRetryConfiguration(
      maxRetryAttempts: 3,
      baseRetryDelay: const Duration(seconds: 5),
      maxRetryDelay: const Duration(minutes: 5),
      circuitBreakerThreshold: 5,
      circuitBreakerTimeout: const Duration(minutes: 10),
    );
    
    // Set up periodic monitoring
    NotificationTriggerService.setupPeriodicMonitoring(
      interval: const Duration(minutes: 2),
      startImmediately: true,
    );
    
    debugPrint('Custom monitoring started with retry logic');
  }
  
  /// Example of monitoring status checking
  static void checkMonitoringHealth() {
    debugPrint('Checking monitoring health...');
    
    final status = NotificationTriggerService.getComprehensiveStatus();
    
    debugPrint('Monitoring Status:');
    debugPrint('  Active: ${status['isMonitoring']}');
    debugPrint('  Interval: ${status['interval']} minutes');
    
    debugPrint('Retry Status:');
    debugPrint('  Consecutive failures: ${status['retry']['consecutiveFailures']}');
    debugPrint('  Circuit breaker: ${status['retry']['circuitBreakerOpen'] ? 'OPEN' : 'CLOSED'}');
    debugPrint('  Max retry attempts: ${status['retry']['maxRetryAttempts']}');
    debugPrint('  Base retry delay: ${status['retry']['baseRetryDelay']} seconds');
    
    if (status['retry']['circuitBreakerOpen']) {
      debugPrint('Circuit breaker is open - monitoring is paused');
      debugPrint('   Opened at: ${status['retry']['circuitBreakerOpenTime']}');
    } else {
      debugPrint('Monitoring is healthy');
    }
  }
}
