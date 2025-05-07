class AuthService {
  // Private constructor to prevent external instantiation
  AuthService._internal();

  // The single, static instance
  static final AuthService _instance = AuthService._internal();

  // Factory constructor to return the same instance every time
  factory AuthService() {
    return _instance;
  }

  // The logged-in admin ID
  int? _adminID;

  // Getter to access the ID
  int? get currentAdminID => _adminID;

  // Method to set the ID (e.g., after login)
  void setAdminID(int? id) {
    _adminID = id;
    print("AuthService: Admin ID set to $_adminID"); // For debugging
  }

  void clearAdminID() {
    _adminID = null;
    print("AuthService: Admin ID cleared."); // For debugging
  }
} 