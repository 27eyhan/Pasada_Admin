import 'package:shared_preferences/shared_preferences.dart';

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
  SharedPreferences? _prefs;
  int? _adminID;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> loadAdminID() async {
    await _initPrefs();
    _adminID = _prefs?.getInt(_adminIdKey);
    if (_adminID != null) {
      print("AuthService: Admin ID loaded from prefs: $_adminID");
    } else {
      print("AuthService: No Admin ID found in prefs.");
    }
  }

  // Getter to access the ID
  int? get currentAdminID => _adminID;

  // Method to set the ID (e.g., after login)
  Future<void> setAdminID(int? id) async {
    await _initPrefs();
    _adminID = id;
    if (id != null) {
      await _prefs?.setInt(_adminIdKey, id);
      print("AuthService: Admin ID set to $_adminID and saved to prefs");
    } else {
      await _prefs?.remove(_adminIdKey); // Also clear from prefs if id is null
      print("AuthService: Admin ID set to null and removed from prefs");
    }
  }

  Future<void> clearAdminID() async {
    await _initPrefs();
    _adminID = null;
    await _prefs?.remove(_adminIdKey);
    print("AuthService: Admin ID cleared from state and prefs.");
  }
} 