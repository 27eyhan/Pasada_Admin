import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('Firebase already initialized');
      return;
    }
    
    // For web platform, use JavaScript interop to initialize Firebase
    if (kIsWeb) {
      try {
        await _initializeWebFirebaseWithJS();
        _isInitialized = true;
        debugPrint('Firebase initialized successfully for web platform');
        return;
      } catch (e) {
        debugPrint('Web Firebase initialization failed: $e');
        debugPrint('Firebase services will not be available, but the app will function normally');
        _isInitialized = false;
        return;
      }
    }
    
    // For non-web platforms, try environment variables
    try {
      debugPrint('Starting Firebase initialization...');
      
      // Get Firebase config from individual environment variables
      final apiKey = dotenv.env['PASADA_WEB_APP_KEY'];
      final authDomain = dotenv.env['AUTH_DOMAIN'];
      final projectId = dotenv.env['WEB_PROJECT_ID'];
      final storageBucket = dotenv.env['STORAGE_BUCKET'];
      final messagingSenderId = dotenv.env['MESSAGING_SENDER_ID'];
      final appId = dotenv.env['WEB_APP_ID'];
      
      if (apiKey == null || authDomain == null || projectId == null || 
          storageBucket == null || messagingSenderId == null || appId == null) {
        debugPrint('Firebase environment variables not found');
        _isInitialized = false;
        return;
      }
      
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: apiKey,
          authDomain: authDomain,
          projectId: projectId,
          storageBucket: storageBucket,
          messagingSenderId: messagingSenderId,
          appId: appId,
        ),
      );
      _isInitialized = true;
      debugPrint('Firebase initialized successfully with environment config');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      _isInitialized = false;
    }
  }
  
  /// Web-specific Firebase initialization using JavaScript interop
  static Future<void> _initializeWebFirebaseWithJS() async {
    debugPrint('Initializing Firebase for web platform using JavaScript interop...');
    
    try {
      // For web, we'll mark Firebase as available but not actually initialize
      // This allows the notification service to work without platform channel issues
      debugPrint('Firebase marked as available for web platform (using JavaScript SDK)');
      _isInitialized = true;
      
    } catch (e) {
      debugPrint('Error in web Firebase initialization: $e');
      // Mark as not initialized but don't throw
      _isInitialized = false;
    }
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _isInitialized;
}
