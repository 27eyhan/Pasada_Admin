import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArchiveService {
  static SupabaseClient get _supabase => Supabase.instance.client;

  static Future<void> archiveAdmin({required int adminId}) async {
    try {
      await _supabase.rpc('archive_admin', params: {
        'p_admin_id': adminId,
      });
      if (kDebugMode) debugPrint('[ArchiveService] Archived admin $adminId');
    } catch (e) {
      debugPrint('[ArchiveService] archiveAdmin error: $e');
      rethrow;
    }
  }

  static Future<void> archiveDriver({required int driverId}) async {
    try {
      await _supabase.rpc('archive_driver', params: {
        'p_driver_id': driverId,
      });
      if (kDebugMode) debugPrint('[ArchiveService] Archived driver $driverId');
    } catch (e) {
      debugPrint('[ArchiveService] archiveDriver error: $e');
      rethrow;
    }
  }

  static Future<void> archiveBooking({required int bookingId}) async {
    try {
      await _supabase.rpc('archive_booking', params: {
        'p_booking_id': bookingId,
      });
      if (kDebugMode) debugPrint('[ArchiveService] Archived booking $bookingId');
    } catch (e) {
      debugPrint('[ArchiveService] archiveBooking error: $e');
      rethrow;
    }
  }
}


