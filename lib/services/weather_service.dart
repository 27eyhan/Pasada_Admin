import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pasada_admin_application/models/weather_model.dart';
import 'package:pasada_admin_application/config/web_config.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.weatherapi.com/v1';
  static const String _endpoint = '/current.json';
  
  String? get _apiKey {
    // Try dotenv first, then fallback to web config
    final dotenvKey = dotenv.env['WEATHER_API_KEY'];
    if (dotenvKey != null && dotenvKey.isNotEmpty) {
      return dotenvKey;
    }
    return WebConfig.weatherApiKey;
  }

  Future<WeatherModel?> getCurrentWeather(String city) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('Weather API key not found. Please check your .env file.');
      return null;
    }

    try {
      final url = '$_baseUrl$_endpoint?key=$_apiKey&q=$city&aqi=no';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return WeatherModel.fromJson(data);
      } else {
        print('Weather API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Weather service error: $e');
      return null;
    }
  }

  Future<WeatherModel?> getCurrentWeatherByCoordinates(double lat, double lon) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('Weather API key not found. Please check your .env file.');
      return null;
    }

    try {
      final url = '$_baseUrl$_endpoint?key=$_apiKey&q=$lat,$lon&aqi=no';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return WeatherModel.fromJson(data);
      } else {
        print('Weather API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Weather service error: $e');
      return null;
    }
  }
}
