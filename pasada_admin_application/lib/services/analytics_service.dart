import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AnalyticsService {
  final String _apiUrl = dotenv.env['API_URL'] ?? '';

  bool get isConfigured => _apiUrl.isNotEmpty;

  Uri _u(String path) => Uri.parse('$_apiUrl$path');

  // Internal traffic data
  Future<http.Response> ingestTrafficData(List<Map<String, dynamic>> trafficData) {
    return http.post(
      _u('/api/analytics/data/traffic'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'trafficData': trafficData}),
    );
  }

  Future<http.Response> getTrafficData() {
    return http.get(_u('/api/analytics/data/traffic'));
  }

  // External integrations
  Future<http.Response> getExternalTrafficStatus() {
    return http.get(_u('/api/analytics/external/traffic/status'));
  }

  Future<http.Response> runExternalTrafficAnalytics({
    required List<int> routeIds,
    bool includeHistoricalAnalysis = true,
    bool generateForecasts = true,
  }) {
    return http.post(
      _u('/api/analytics/external/traffic/run'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'routeIds': routeIds,
        'includeHistoricalAnalysis': includeHistoricalAnalysis,
        'generateForecasts': generateForecasts,
      }),
    );
  }

  Future<http.Response> getExternalRouteTrafficSummary(String routeId, {int days = 7}) {
    return http.get(_u('/api/analytics/external/route/$routeId/traffic-summary?days=$days'));
  }

  Future<http.Response> getExternalRoutePredictions(String routeId) {
    return http.get(_u('/api/analytics/external/route/$routeId/predictions'));
  }

  Future<http.Response> ingestExternalTrafficData(List<Map<String, dynamic>> trafficData) {
    return http.post(
      _u('/api/analytics/external/data/traffic'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'trafficData': trafficData}),
    );
  }

  Future<http.Response> getExternalAdminMetrics() {
    return http.get(_u('/api/analytics/external/admin/metrics'));
  }

  // Route analytics (local)
  Future<http.Response> getLocalRouteAnalytics(String routeId) {
    return http.get(_u('/api/analytics/routes/$routeId'));
  }

  // Hybrid analytics (combined local + external)
  Future<http.Response> getHybridRouteAnalytics(String routeId) {
    return http.get(_u('/api/analytics/hybrid/route/$routeId'));
  }
}

 
