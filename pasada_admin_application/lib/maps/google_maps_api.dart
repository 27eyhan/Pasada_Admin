// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Initializes the Google Maps API for web platform
class GoogleMapsApiInitializer {
  /// Loads the Google Maps API with the key from the .env file
  static void initialize() {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('Warning: GOOGLE_MAPS_API_KEY is not set in .env file');
      return;
    }
    
    // Call the JavaScript function to load the Google Maps API
    js.context.callMethod('loadGoogleMapsApi', [apiKey]);
  }
}
