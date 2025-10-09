import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SessionService {
  SessionService._internal();
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;

  static String get tableName {
    final envPrimary = dotenv.env['ADMIN_SESSIONS_TABLE']?.trim();
    final envAlt = dotenv.env['adminSessionsTable']?.trim();
    final envName = (envPrimary != null && envPrimary.isNotEmpty)
        ? envPrimary
        : (envAlt != null && envAlt.isNotEmpty)
            ? envAlt
            : null;
    // Fallback to a sensible default table name when unset/empty
    // Ensure not empty to avoid requests hitting /rest/v1/ with no table path
    return (envName == null || envName.isEmpty) ? 'admin_sessions' : envName;
  }
  static const String _deviceIdKey = 'deviceId';

  RealtimeChannel? _sessionChannel;

  Future<String> ensureDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = const Uuid().v4();
    await prefs.setString(_deviceIdKey, generated);
    return generated;
    }

  Future<void> registerSingleSession({
    required SupabaseClient supabase,
    required int adminId,
    required String sessionToken,
    required DateTime expiresAt,
  }) async {
    try {
      final deviceId = await ensureDeviceId();
      // Remove all previous sessions for this admin
      try {
        await supabase.from(tableName).delete().eq('admin_id', adminId);
      } catch (e) {
        debugPrint('[SessionService.registerSingleSession] delete previous error: $e');
      }

      // Insert the new active session
      await supabase.from(tableName).insert({
        'admin_id': adminId,
        'session_token': sessionToken,
        'device_id': deviceId,
        'expires_at': expiresAt.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SessionService.registerSingleSession] error: $e (table=$tableName)');
      rethrow;
    }
  }

  Future<bool> validateCurrentSession({
    required SupabaseClient supabase,
    required int adminId,
    required String sessionToken,
  }) async {
    try {
      final res = await supabase
          .from(tableName)
          .select('session_token, expires_at')
          .eq('admin_id', adminId)
          .limit(1)
          .maybeSingle();
      if (res == null) return false;
      final token = res['session_token']?.toString();
      if (token != sessionToken) return false;
      final expires = DateTime.tryParse(res['expires_at']?.toString() ?? '');
      if (expires != null && DateTime.now().isAfter(expires)) return false;
      return true;
    } catch (e) {
      debugPrint('[SessionService.validateCurrentSession] error: $e');
      return false;
    }
  }

  void startSingleSessionWatch({
    required SupabaseClient supabase,
    required int adminId,
    required String sessionToken,
    required VoidCallback onInvalidated,
  }) {
    stopWatch();
    _sessionChannel = supabase.channel('watch-admin-session-$adminId');
    _sessionChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: tableName,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'admin_id',
            value: adminId,
          ),
          callback: (payload) {
            try {
              final newToken = payload.newRecord['session_token']?.toString();
              if (newToken != sessionToken) {
                onInvalidated();
              }
            } catch (_) {}
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: tableName,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'admin_id',
            value: adminId,
          ),
          callback: (payload) {
            try {
              final newToken = payload.newRecord['session_token']?.toString();
              if (newToken != sessionToken) {
                onInvalidated();
              }
            } catch (_) {}
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: tableName,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'admin_id',
            value: adminId,
          ),
          callback: (payload) {
            onInvalidated();
          },
        )
        .subscribe();
  }

  void stopWatch() {
    try {
      _sessionChannel?.unsubscribe();
      _sessionChannel = null;
    } catch (_) {}
  }
}


