import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    try {
      // Get Firebase config from environment variables
      final firebaseConfig = dotenv.env['WEB_FIREBASE_KEY'];
      
      if (firebaseConfig == null || firebaseConfig.isEmpty) {
        debugPrint('WEB_FIREBASE_KEY not found, using default Firebase config');
        await _initializeWithDefaults();
        return;
      }
      
      // Try to parse the JSON config
      try {
        final config = json.decode(firebaseConfig) as Map<String, dynamic>;
        
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: config['apiKey'] as String,
            authDomain: config['authDomain'] as String,
            projectId: config['projectId'] as String,
            storageBucket: config['storageBucket'] as String,
            messagingSenderId: config['messagingSenderId'] as String,
            appId: config['appId'] as String,
          ),
        );
        debugPrint('Firebase initialized with environment config');
      } catch (e) {
        debugPrint('Error parsing WEB_FIREBASE_KEY JSON: $e');
        debugPrint('Falling back to default Firebase config');
        await _initializeWithDefaults();
      }
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
