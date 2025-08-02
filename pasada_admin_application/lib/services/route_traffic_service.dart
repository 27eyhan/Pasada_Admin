import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RouteTrafficService {
  final String _apiUrl = dotenv.env['API_URL'] ?? '';

  Future<String> getRouteTraffic(int routeId) async {
    if (_apiUrl.isEmpty) {
      return 'Error: API_URL not configured.';
    }
    try {
      final url = Uri.parse('$_apiUrl/api/route-traffic');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'routeId': routeId}),
      );
      if (response.statusCode != 200) {
        return 'Error from server: ${response.statusCode} ${response.body}';
      }
      final data = json.decode(response.body);
      final duration = data['duration'];
      final durationInTraffic = data['durationInTraffic'];
      return 'Traffic for route #$routeId: current duration $durationInTraffic (normal: $duration).';
    } catch (e) {
      return 'Error retrieving traffic data: $e';
    }
  }
}
