import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverActivityLogs {
  final int driverId;
  final BuildContext context;

  DriverActivityLogs({
    required this.driverId,
    required this.context,
  });

  // Log driver activity when status changes
  Future<void> logDriverActivity(String drivingStatus, DateTime timestamp) async {
    try {
      debugPrint('Starting logDriverActivity for driver $driverId with driving status $drivingStatus');
      final supabase = Supabase.instance.client;
      
      // First, check if this is an active status (Online, Driving, or Idling)
      // Only proceed with logging if it's one of these statuses
      if (drivingStatus == 'Online' || drivingStatus == 'Driving' || drivingStatus == 'Idling') {
        debugPrint('Status is active, proceeding with activity logging');
        
        // Check if there's an ongoing session without a logout
        final ongoingSession = await supabase
            .from('driverActivityLog')
            .select()
            .eq('driver_id', driverId)
            .filter('logout_timestamp', 'is', null)
            .maybeSingle();
        
        debugPrint('Checked for ongoing session: ${ongoingSession != null ? 'Found' : 'Not found'}');
        
        if (ongoingSession != null) {
          // Calculate session duration in seconds
          final loginTime = DateTime.parse(ongoingSession['login_timestamp']);
          final duration = timestamp.difference(loginTime).inSeconds;
          
          debugPrint('Updating session with log_id: ${ongoingSession['log_id']} - duration: $duration seconds');
          
          // Update the existing session with logout time and duration
          final updateResponse = await supabase
              .from('driverActivityLog')
              .update({
                'logout_timestamp': timestamp.toIso8601String(),
                'session_duration': duration,
                'status': 'SAVED', // Mark as SAVED once updated
              })
              .eq('log_id', ongoingSession['log_id'])
              .select();
          
          debugPrint('Update response: $updateResponse');
          debugPrint('Updated session duration: ${updateResponse.isNotEmpty ? updateResponse[0]['session_duration'] : 'unknown'} seconds');
          debugPrint('Updated existing driver activity log: ID ${ongoingSession['log_id']} with logout time and duration');
        }
        
        // Always create a new activity log for active statuses
        // Generate a unique log_id using seconds timestamp to avoid PostgreSQL integer overflow
        final int logId = DateTime.now().millisecondsSinceEpoch ~/ 1000 + (driverId % 1000);
        
        debugPrint('Creating new activity log with ID $logId for driver $driverId with driving status $drivingStatus');
        
        final activityData = {
          'log_id': logId,
          'driver_id': driverId,
          'login_timestamp': timestamp.toIso8601String(),
          'status': 'SAVED', // Set status to SAVED
        };
        
        debugPrint('Activity data for insertion: $activityData');
        
        final insertResponse = await supabase
            .from('driverActivityLog')
            .insert(activityData)
            .select();
        
        debugPrint('Insertion response: $insertResponse');
        debugPrint('Successfully created new driver activity log: ID $logId for driver $driverId with driving status $drivingStatus');
      } else {
        debugPrint('Driver status is $drivingStatus - not logging activity (only logs for Online, Driving, or Idling)');
        
        // If driver is not in an active state, check if there's an ongoing session to close
        final ongoingSession = await supabase
            .from('driverActivityLog')
            .select()
            .eq('driver_id', driverId)
            .filter('logout_timestamp', 'is', null)
            .maybeSingle();
            
        if (ongoingSession != null) {
          // Calculate session duration in seconds
          final loginTime = DateTime.parse(ongoingSession['login_timestamp']);
          final duration = timestamp.difference(loginTime).inSeconds;
          
          // Close the existing session since driver is no longer active
          await supabase
              .from('driverActivityLog')
              .update({
                'logout_timestamp': timestamp.toIso8601String(),
                'session_duration': duration,
                'status': 'SAVED',
              })
              .eq('log_id', ongoingSession['log_id']);
              
          debugPrint('Closed ongoing session due to inactive status');
        }
      }
      
    } catch (e) {
      debugPrint('Error logging driver activity: ${e.toString()}');
      // Check if exception is a PostgreSQL error with more details
      if (e is PostgrestException) {
        debugPrint('PostgreSQL error code: ${e.code}');
        debugPrint('PostgreSQL error message: ${e.message}');
        debugPrint('PostgreSQL error details: ${e.details}');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging driver activity: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Get all active drivers (status is Online, Driving, or Idling)
  Future<List<Map<String, dynamic>>> getActiveDrivers() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('driverTable')
          .select('driver_id, full_name, driving_status')
          .or('driving_status.eq.Online,driving_status.eq.Driving,driving_status.eq.Idling');
      
      return response;
    } catch (e) {
      debugPrint('Error getting active drivers: ${e.toString()}');
      return [];
    }
  }

  // Fetch driver activity logs for a specific date range
  Future<List<Map<String, dynamic>>> fetchDriverActivityLogs(DateTime startDate, DateTime endDate) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('driverActivityLog')
          .select('log_id, driver_id, login_timestamp, logout_timestamp, session_duration, status')
          .eq('driver_id', driverId)
          .gte('login_timestamp', startDate.toIso8601String())
          .lte('login_timestamp', endDate.toIso8601String())
          .order('login_timestamp');
      
      return response;
    } catch (e) {
      return [];
    }
  }
} 