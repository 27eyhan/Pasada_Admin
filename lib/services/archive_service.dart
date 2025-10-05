import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArchiveService {
  static SupabaseClient get _supabase => Supabase.instance.client;

  static Future<bool> archiveAdmin({required int adminId}) async {
    try {
      final res = await _supabase.rpc('archive_admin', params: {
        'p_admin_id': adminId,
      });
      final ok = res == true || res == 1 || res == 'true';
      if (ok && kDebugMode) debugPrint('[ArchiveService] Archived admin $adminId successfully');
      return ok;
    } catch (e) {
      debugPrint('[ArchiveService] archiveAdmin error: $e');
      return false;
    }
  }

  static Future<bool> archiveDriver({required int driverId}) async {
    try {
      final res = await _supabase.rpc('archive_driver', params: {
        'p_driver_id': driverId,
      });
      final ok = res == true || res == 1 || res == 'true';
      if (ok && kDebugMode) debugPrint('[ArchiveService] Archived driver $driverId successfully');
      return ok;
    } catch (e) {
      debugPrint('[ArchiveService] archiveDriver error: $e');
      return false;
    }
  }

  static Future<bool> archiveBooking({required int bookingId}) async {
    try {
      final res = await _supabase.rpc('archive_booking', params: {
        'p_booking_id': bookingId,
      });
      final ok = res == true || res == 1 || res == 'true';
      if (ok && kDebugMode) debugPrint('[ArchiveService] Archived booking $bookingId successfully');
      return ok;
    } catch (e) {
      debugPrint('[ArchiveService] archiveBooking error: $e');
      return false;
    }
  }
}


