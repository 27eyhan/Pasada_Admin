import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RouteTrafficService {
  final String _apiUrl = dotenv.env['API_URL'] ?? '';

  Future<Map<String, dynamic>?> getRouteTrafficData(int routeId) async {
    if (_apiUrl.isEmpty) {
      return null;
    }
    try {
      final url = Uri.parse('$_apiUrl/api/route-traffic');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'routeId': routeId}),
      );
      if (response.statusCode != 200) {
        return null;
      }
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return null;
    }
  }

  String _getTrafficDensity(String duration, String durationInTraffic) {
    try {
      // Parse duration strings (assuming format like "15 mins" or "25 minutes")
      final normalDuration = _parseDurationToMinutes(duration);
      final currentDuration = _parseDurationToMinutes(durationInTraffic);

      if (normalDuration == null || currentDuration == null) {
        return 'Unknown';
      }

      final trafficRatio = currentDuration / normalDuration;

      if (trafficRatio <= 1.2) {
        return 'Light';
      } else if (trafficRatio <= 1.8) {
        return 'Normal';
      } else {
        return 'Heavy';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  int? _parseDurationToMinutes(String durationStr) {
    try {
      // Remove common words and extract numbers
      final cleanStr = durationStr
          .toLowerCase()
          .replaceAll('mins', '')
          .replaceAll('min', '')
          .replaceAll('minutes', '')
          .replaceAll('minute', '')
          .trim();

      return int.tryParse(cleanStr);
    } catch (e) {
      return null;
    }
  }

  Future<String> getRouteTrafficForAI(int routeId) async {
    // Check if API URL is configured
    if (_apiUrl.isEmpty) {
      return 'Error: API_URL is not configured in .env file. Please add API_URL=your_api_url_here to your .env file.';
    }

    final data = await getRouteTrafficData(routeId);

    if (data == null) {
      return 'Error: Unable to retrieve traffic data for route #$routeId. Please check API configuration or route ID.';
    }

    final duration = data['duration']?.toString() ?? 'Unknown';
    final durationInTraffic =
        data['durationInTraffic']?.toString() ?? 'Unknown';
    final trafficDensity = _getTrafficDensity(duration, durationInTraffic);

    // Calculate estimated times for different traffic levels
    final normalDuration = _parseDurationToMinutes(duration) ?? 0;
    final lightTrafficETA = normalDuration;
    final normalTrafficETA =
        (normalDuration * 1.5).round(); // 50% increase for normal traffic
    final heavyTrafficETA =
        (normalDuration * 2.0).round(); // 100% increase for heavy traffic

    return '''Route Traffic Analysis for Route #$routeId:
- Normal Duration: $duration
- Current Duration: $durationInTraffic  
- Current Traffic Density: $trafficDensity

Traffic Density ETAs:
- Light: $lightTrafficETA minutes
- Normal: $normalTrafficETA minutes  
- Heavy: $heavyTrafficETA minutes

Please provide a response in this exact format:

The following route has traffic density in ETA:
Light: $lightTrafficETA minutes
Normal: $normalTrafficETA minutes
Heavy: $heavyTrafficETA minutes

[Then provide explanation and suggestions in the next paragraph]

Analyze the current traffic conditions and provide practical fleet management suggestions and recommendations for drivers or passengers using this route.''';
  }

  @Deprecated('Use getRouteTrafficForAI instead')
  Future<String> getRouteTraffic(int routeId) async {
    final data = await getRouteTrafficData(routeId);

    if (data == null) {
      return 'Error: Unable to retrieve traffic data for route #$routeId.';
    }

    final duration = data['duration'];
    final durationInTraffic = data['durationInTraffic'];
    final trafficDensity = _getTrafficDensity(duration, durationInTraffic);

    return 'Traffic for route #$routeId: current duration $durationInTraffic (normal: $duration). Traffic Density: $trafficDensity';
  }
}
