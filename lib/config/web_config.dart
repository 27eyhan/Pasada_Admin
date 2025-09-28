import 'package:flutter/foundation.dart';

class WebConfig {
  // Environment variables for web deployment
  static const String _weatherApiKey = String.fromEnvironment('WEATHER_API_KEY');
  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static String? get weatherApiKey {
    if (kIsWeb) {
      return _weatherApiKey.isNotEmpty ? _weatherApiKey : null;
    }
    return null;
  }

  static String? get supabaseUrl {
    if (kIsWeb) {
      return _supabaseUrl.isNotEmpty ? _supabaseUrl : null;
    }
    return null;
  }

  static String? get supabaseAnonKey {
    if (kIsWeb) {
      return _supabaseAnonKey.isNotEmpty ? _supabaseAnonKey : null;
    }
    return null;
  }

  static String? get googleMapsApiKey {
    if (kIsWeb) {
      return _googleMapsApiKey.isNotEmpty ? _googleMapsApiKey : null;
    }
    return null;
  }
}
