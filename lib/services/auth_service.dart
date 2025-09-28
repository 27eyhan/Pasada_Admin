import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:convert';

class AuthService {
  // Private constructor to prevent external instantiation
  AuthService._internal();

  // The single, static instance
  static final AuthService _instance = AuthService._internal();

  // Factory constructor to return the same instance every time
  factory AuthService() {
    return _instance;
  }

  static const String _adminIdKey = 'adminID';
  static const String _sessionTokenKey = 'sessionToken';
  static const String _sessionExpiryKey = 'sessionExpiryMs';
  static const String _sessionTimeoutMinutesKey = 'sessionTimeoutMinutes';
  static const String _sessionTimeoutEnabledKey = 'sessionTimeoutEnabled';
  static const String _rtUpdateFrequencyKey = 'rtUpdateFrequency'; // 'realtime' | '5min' | '15min' | 'manual'
  static const String _rtAutoRefreshEnabledKey = 'rtAutoRefreshEnabled';
  static const String _rtRefreshIntervalSecondsKey = 'rtRefreshIntervalSeconds';
  static const String _pushNotificationsKey = 'pushNotifications';
  static const String _rideUpdatesKey = 'rideUpdates';
  SharedPreferences? _prefs;
  int? _adminID;
  String? _sessionToken;
  int? _sessionExpiryMs; // epoch millis
  int _timeoutMinutes = 30;
  bool _timeoutEnabled = true;
  String _updateFrequency = 'realtime';
  bool _autoRefreshEnabled = true;
  int _refreshIntervalSeconds = 30;
  bool _pushNotifications = true;
  bool _rideUpdates = true;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> loadAdminID() async {
    await _initPrefs();
    _adminID = _prefs?.getInt(_adminIdKey);
    if (_adminID != null) {
      debugPrint("AuthService: Admin ID loaded from prefs: $_adminID");
    } else {
      debugPrint("AuthService: No Admin ID found in prefs.");
    }
  }

  Future<void> loadSession() async {
    await _initPrefs();
    _adminID = _prefs?.getInt(_adminIdKey);
    _sessionToken = _prefs?.getString(_sessionTokenKey);
    _sessionExpiryMs = _prefs?.getInt(_sessionExpiryKey);
    _timeoutMinutes = _prefs?.getInt(_sessionTimeoutMinutesKey) ?? 30;
    _timeoutEnabled = _prefs?.getBool(_sessionTimeoutEnabledKey) ?? true;
    _updateFrequency = _prefs?.getString(_rtUpdateFrequencyKey) ?? 'realtime';
    _autoRefreshEnabled = _prefs?.getBool(_rtAutoRefreshEnabledKey) ?? true;
    _refreshIntervalSeconds = _prefs?.getInt(_rtRefreshIntervalSecondsKey) ?? 30;
    _pushNotifications = _prefs?.getBool(_pushNotificationsKey) ?? true;
    _rideUpdates = _prefs?.getBool(_rideUpdatesKey) ?? true;
    debugPrint('AuthService: Session loaded (adminID=$_adminID, hasToken=${_sessionToken != null}, expiryMs=$_sessionExpiryMs)');
  }

  // Getter to access the ID
  int? get currentAdminID => _adminID;

  // Method to set the ID (e.g., after login)
  Future<void> setAdminID(int? id) async {
    await _initPrefs();
    _adminID = id;
    if (id != null) {
      await _prefs?.setInt(_adminIdKey, id);
      debugPrint("AuthService: Admin ID set to $_adminID and saved to prefs");
    } else {
      await _prefs?.remove(_adminIdKey); // Also clear from prefs if id is null
      debugPrint("AuthService: Admin ID set to null and removed from prefs");
    }
  }

  Future<void> clearAdminID() async {
    await _initPrefs();
    _adminID = null;
    await _prefs?.remove(_adminIdKey);
    debugPrint("AuthService: Admin ID cleared from state and prefs.");
  }

  // Secure-ish session handling (token + expiry)
  bool get isSessionValid {
    if (_adminID == null || _sessionToken == null || _sessionExpiryMs == null) return false;
    return DateTime.now().millisecondsSinceEpoch < (_sessionExpiryMs ?? 0);
  }

  String? get sessionToken => _sessionToken;

  Future<void> createSession(int adminId, {Duration ttl = const Duration(hours: 12)}) async {
    await _initPrefs();
    _adminID = adminId;
    // Generate a cryptographically secure random token
    final secure = Random.secure();
    final bytes = List<int>.generate(32, (_) => secure.nextInt(256));
    _sessionToken = base64Url.encode(bytes);
    _sessionExpiryMs = DateTime.now().add(ttl).millisecondsSinceEpoch;

    await _prefs?.setInt(_adminIdKey, adminId);
    await _prefs?.setString(_sessionTokenKey, _sessionToken!);
    await _prefs?.setInt(_sessionExpiryKey, _sessionExpiryMs!);
    debugPrint('AuthService: Session created for admin=$adminId exp=$_sessionExpiryMs');
  }

  Future<void> clearSession() async {
    await _initPrefs();
    _adminID = null;
    _sessionToken = null;
    _sessionExpiryMs = null;
    await _prefs?.remove(_adminIdKey);
    await _prefs?.remove(_sessionTokenKey);
    await _prefs?.remove(_sessionExpiryKey);
    debugPrint('AuthService: Session cleared');
  }

  // Session timeout preferences
  int get sessionTimeoutMinutes => _timeoutMinutes;
  bool get sessionTimeoutEnabled => _timeoutEnabled;

  Future<void> setSessionTimeout({required int minutes, required bool enabled}) async {
    await _initPrefs();
    _timeoutMinutes = minutes;
    _timeoutEnabled = enabled;
    await _prefs?.setInt(_sessionTimeoutMinutesKey, minutes);
    await _prefs?.setBool(_sessionTimeoutEnabledKey, enabled);
    debugPrint('AuthService: Session timeout set minutes=$minutes enabled=$enabled');
  }

  // Real-time updates settings
  String get updateFrequency => _updateFrequency; // 'realtime' | '5min' | '15min' | '30min'
  bool get autoRefreshEnabled => _autoRefreshEnabled;
  int get refreshIntervalSeconds => _refreshIntervalSeconds;

  Future<void> setRealtimeUpdateSettings({
    required String frequency,
    required bool autoRefresh,
    required int intervalSeconds,
  }) async {
    await _initPrefs();
    _updateFrequency = frequency;
    _autoRefreshEnabled = autoRefresh;
    _refreshIntervalSeconds = intervalSeconds;
    await _prefs?.setString(_rtUpdateFrequencyKey, frequency);
    await _prefs?.setBool(_rtAutoRefreshEnabledKey, autoRefresh);
    await _prefs?.setInt(_rtRefreshIntervalSecondsKey, intervalSeconds);
    debugPrint('AuthService: Realtime settings frequency=$frequency autoRefresh=$autoRefresh interval=$intervalSeconds');
  }

  // Notification preferences
  bool get pushNotifications => _pushNotifications;
  bool get rideUpdates => _rideUpdates;

  Future<void> setNotificationSettings({
    required bool pushNotifications,
    required bool rideUpdates,
  }) async {
    await _initPrefs();
    _pushNotifications = pushNotifications;
    _rideUpdates = rideUpdates;
    await _prefs?.setBool(_pushNotificationsKey, pushNotifications);
    await _prefs?.setBool(_rideUpdatesKey, rideUpdates);
    debugPrint('AuthService: Notification settings pushNotifications=$pushNotifications rideUpdates=$rideUpdates');
  }
} 