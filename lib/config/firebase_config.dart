import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    try {
      // Get Firebase config from individual environment variables
      final apiKey = dotenv.env['PASADA_WEB_APP_KEY'];
      final authDomain = dotenv.env['AUTH_DOMAIN'];
      final projectId = dotenv.env['WEB_PROJECT_ID'];
      final storageBucket = dotenv.env['STORAGE_BUCKET'];
      final messagingSenderId = dotenv.env['MESSAGING_SENDER_ID'];
      final appId = dotenv.env['WEB_APP_ID'];
      
      if (apiKey == null || authDomain == null || projectId == null || 
          storageBucket == null || messagingSenderId == null || appId == null) {
        debugPrint('Firebase environment variables not found, using default Firebase config');
        await _initializeWithDefaults();
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
      debugPrint('Firebase initialized with environment config');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      await _initializeWithDefaults();
    }
  }
  
  /// Initialize Firebase with default configuration
  static Future<void> _initializeWithDefaults() async {
    // Default Firebase configuration - replace with your actual values
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'your-api-key-here',
        authDomain: 'your-project.firebaseapp.com',
        projectId: 'your-project-id',
        storageBucket: 'your-project.appspot.com',
        messagingSenderId: 'your-sender-id',
        appId: 'your-app-id',
      ),
    );
    debugPrint('Firebase initialized with default config');
  }
}
