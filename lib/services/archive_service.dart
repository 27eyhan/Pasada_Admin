import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArchiveService {
  static SupabaseClient get _supabase => Supabase.instance.client;

  static Future<bool> archiveAdmin({required int adminId}) async {
    try {
      // Soft-archive: set is_archived = true on adminTable
      final res = await _supabase
          .from('adminTable')
          .update({'is_archived': true})
          .match({'admin_id': adminId})
          .select()
          .maybeSingle();
      final ok = res != null;
      if (ok && kDebugMode) debugPrint('[ArchiveService] Archived admin $adminId successfully');
      return ok;
    } catch (e) {
      debugPrint('[ArchiveService] archiveAdmin error: $e');
      return false;
    }
  }

  static Future<bool> archiveDriver({required int driverId}) async {
    try {
      // Soft-archive: set is_archived = true on driverTable
      final res = await _supabase
          .from('driverTable')
          .update({'is_archived': true})
          .match({'driver_id': driverId})
          .select()
          .maybeSingle();
      final ok = res != null;
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


