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

  // Booking frequency analytics
  Future<http.Response> getBookingFrequency({int days = 14}) {
    return http.get(_u('/api/analytics/bookings/frequency?days=$days'));
  }

  Future<http.Response> persistBookingFrequencyDaily({int days = 14}) {
    return http.post(_u('/api/analytics/bookings/frequency/persist/daily?days=$days'));
  }

  Future<http.Response> persistBookingFrequencyForecast({int days = 14}) {
    return http.post(_u('/api/analytics/bookings/frequency/persist/forecast?days=$days'));
  }

  Future<http.Response> getBookingFrequencyDaily({int days = 14}) {
    return http.get(_u('/api/analytics/bookings/frequency/daily?days=$days'));
  }

  Future<http.Response> getLatestBookingFrequencyForecast() {
    return http.get(_u('/api/analytics/bookings/frequency/forecast/latest'));
  }

  // Migration and synchronization endpoints
  Future<http.Response> checkQuestDBStatus() {
    return http.get(_u('/api/status/questdb'));
  }

  Future<http.Response> checkMigrationStatus() {
    return http.get(_u('/api/admin/migration/status'));
  }

  Future<http.Response> executeMigration() {
    return http.post(_u('/api/admin/migration/run'));
  }

  // Daily traffic collection status
  Future<http.Response> getDailyCollectionStatus() {
    return http.get(_u('/api/analytics/admin/collection-status'));
  }

  // Weekly analytics processing
  Future<http.Response> processWeeklyAnalytics() {
    return http.post(_u('/api/analytics/admin/process-weekly'));
  }

  Future<http.Response> processWeeklyAnalyticsWithOffset(int weekOffset) {
    return http.post(_u('/api/analytics/admin/process-weekly/$weekOffset'));
  }

  // =============================
  // Database-Based Gemini Analysis
  // =============================

  // Per-Route Analysis
  Future<http.Response> getDatabaseRouteAnalysis({required int routeId, int days = 7}) {
    return http.get(_u('/api/analytics/database-analysis/route/$routeId?days=$days'));
  }

  // System-wide Overview Analysis
  Future<http.Response> getDatabaseOverviewAnalysis({int days = 7}) {
    return http.get(_u('/api/analytics/database-analysis/overview?days=$days'));
  }

  // Free-form Manong Q&A (Grounded)
  Future<http.Response> askManong({
    required String question,
    int? routeId,
    int days = 7,
  }) {
    final body = <String, dynamic>{
      'question': question,
      'days': days,
    };
    if (routeId != null) body['routeId'] = routeId;
    return http.post(
      _u('/api/analytics/ai/ask'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
  }

  // Booking Frequency with Manong Explanation
  Future<http.Response> getBookingFrequencyWithExplanation({int days = 14}) {
    return http.get(_u('/api/analytics/bookings/frequency?days=$days'));
  }
}

 
