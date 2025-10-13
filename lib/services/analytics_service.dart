import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AnalyticsService {
  final String _apiUrl = dotenv.env['API_URL'] ?? '';
  final String _analyticsApiUrl = dotenv.env['ANALYTICS_API_URL'] ?? '';
  final String _analyticsProxyPrefix = dotenv.env['ANALYTICS_PROXY_PREFIX'] ?? '/analytics-proxy';

  bool get isConfigured => _apiUrl.isNotEmpty;
  bool get isAnalyticsConfigured => _analyticsApiUrl.isNotEmpty;
  
  // Check if analytics service is actually available
  Future<bool> checkAnalyticsServiceHealth() async {
    if (!isAnalyticsConfigured) {
      debugPrint('[AnalyticsService] Analytics API URL not configured');
      return false;
    }
    try {
      final uri = _au('/api/admin/metrics');
      debugPrint('[AnalyticsService] Testing metrics endpoint: $uri');
      final response = await http.get(uri).timeout(Duration(seconds: 5));
      debugPrint('[AnalyticsService] Health check response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[AnalyticsService] Health check failed: $e');
      return false;
    }
  }

  // Test all analytics endpoints systematically
  Future<Map<String, dynamic>> testAllEndpoints() async {
    final results = <String, dynamic>{};
    
    debugPrint('[AnalyticsService] ========== ENDPOINT TESTING STARTED ==========');
    debugPrint('[AnalyticsService] Main API URL: $_apiUrl');
    debugPrint('[AnalyticsService] Analytics API URL: $_analyticsApiUrl');
    debugPrint('[AnalyticsService] Is Configured: $isConfigured');
    debugPrint('[AnalyticsService] Is Analytics Configured: $isAnalyticsConfigured');
    
    // Test metrics endpoint first (health equivalent)
    results['metrics'] = await _testEndpoint('GET', '/api/admin/metrics', 'Service Metrics');
    
    // Test analytics dashboard endpoints
    results['weekly_summary'] = await _testEndpoint('GET', '/api/admin/analytics/weekly/summary', 'Weekly Summary');
    results['route_summary'] = await _testEndpoint('GET', '/api/admin/analytics/route/1/summary?days=120', 'Route Summary (Route 1, 120 days)');
    results['weekly_trends'] = await _testEndpoint('GET', '/api/admin/analytics/weekly/trends', 'Weekly Trends');
    results['today_traffic'] = await _testEndpoint('GET', '/api/analytics/traffic/today', 'Today Traffic (All Routes)');
    results['today_traffic_route'] = await _testEndpoint('GET', '/api/analytics/traffic/today/1', 'Today Traffic (Route 1)');
    results['route_daily'] = await _testEndpoint('GET', '/api/admin/analytics/route/1/daily', 'Route Daily Analytics');
    results['peak_patterns'] = await _testEndpoint('GET', '/api/admin/analytics/weekly/peak-patterns', 'Peak Patterns');
    
    // Test admin management endpoints
    results['migration_status'] = await _testEndpoint('GET', '/api/admin/migration/status', 'Migration Status');
    results['traffic_status'] = await _testEndpoint('GET', '/api/admin/traffic/status', 'Traffic Status');
    results['questdb_status'] = await _testEndpoint('GET', '/api/status/questdb', 'QuestDB Status');
    results['system_metrics'] = await _testEndpoint('GET', '/api/admin/metrics', 'System Metrics');
    
    debugPrint('[AnalyticsService] ========== ENDPOINT TESTING COMPLETED ==========');
    
    return results;
  }
  
  Future<Map<String, dynamic>> _testEndpoint(String method, String path, String description) async {
    final result = <String, dynamic>{
      'method': method,
      'path': path,
      'description': description,
      'success': false,
      'statusCode': null,
      'error': null,
      'responseTime': null,
    };
    
    try {
      final startTime = DateTime.now();
      final uri = _au(path);
      
      debugPrint('[AnalyticsService] Testing: $method $uri ($description)');
      
      http.Response response;
      
      if (method == 'GET') {
        response = await http.get(uri).timeout(Duration(seconds: 10));
      } else if (method == 'POST') {
        response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
        ).timeout(Duration(seconds: 10));
      } else {
        throw Exception('Unsupported method: $method');
      }
      
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;
      
      result['success'] = response.statusCode >= 200 && response.statusCode < 300;
      result['statusCode'] = response.statusCode;
      result['responseTime'] = responseTime;
      
      debugPrint('[AnalyticsService] ✅ $description: ${response.statusCode} (${responseTime}ms)');
      
      if (response.body.isNotEmpty && response.body.length < 500) {
        debugPrint('[AnalyticsService] Response preview: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      }
      
    } catch (e) {
      result['error'] = e.toString();
      debugPrint('[AnalyticsService] ❌ $description failed: $e');
    }
    
    return result;
  }

  Uri _u(String path) => Uri.parse('$_apiUrl$path');
  Uri _au(String path) {
    // If a proxy prefix is configured, prefer it to avoid CORS on web
    if (_analyticsProxyPrefix.isNotEmpty) {
      final uri = Uri.parse('$_analyticsProxyPrefix$path');
      debugPrint('[AnalyticsService] Using proxy for analytics: $uri');
      return uri;
    }
    return Uri.parse('$_analyticsApiUrl$path');
  }

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

  Future<http.Response> cancelMigration() {
    return http.post(_u('/api/admin/migration/cancel'));
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

  // =============================
  // Manong Chat (Grounded) - free-form conversation
  // =============================
  Future<http.Response> chatManong({
    required List<Map<String, String>> messages,
    int days = 7,
  }) {
    // Retain only {role, content}
    final sanitized = messages.map((m) => {
      'role': m['role'] ?? 'user',
      'content': m['content'] ?? '',
    }).toList();
    return http.post(
      _u('/api/analytics/ai/chat'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'messages': sanitized,
        'days': days,
      }),
    );
  }

  // =============================
  // NEW ANALYTICS DASHBOARD ENDPOINTS
  // =============================
  
  // Weekly analytics summary
  Future<http.Response> getWeeklySummary() async {
    final uri = _au('/api/admin/analytics/weekly/summary');
    debugPrint('[AnalyticsService] Calling getWeeklySummary: $uri');
    try {
      final response = await http.get(uri).timeout(Duration(seconds: 10));
      debugPrint('[AnalyticsService] getWeeklySummary response: ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('[AnalyticsService] getWeeklySummary failed: $e');
      rethrow;
    }
  }
  
  // Route performance summary (optional days window)
  Future<http.Response> getRouteSummary(String routeId, {int? days}) async {
    final base = '/api/admin/analytics/route/$routeId/summary';
    final uri = days != null
        ? _au('$base?days=$days')
        : _au(base);
    debugPrint('[AnalyticsService] Calling getRouteSummary for route $routeId: $uri');
    try {
      final response = await http.get(uri).timeout(Duration(seconds: 5));
      debugPrint('[AnalyticsService] getRouteSummary response: ${response.statusCode}');
      if (response.statusCode == 404) {
        debugPrint('[AnalyticsService] Route $routeId has no data (404)');
      }
      return response;
    } catch (e) {
      debugPrint('[AnalyticsService] getRouteSummary failed: $e');
      // Return a mock response instead of throwing to prevent crashes
      return http.Response('{"success": false, "error": "Service timeout"}', 408);
    }
  }
  
  // Fast weekly analytics endpoint (optimized for speed)
  Future<http.Response> getFastWeeklyAnalytics(String routeId) async {
    final uri = _au('/api/admin/analytics/weekly/summary');
    debugPrint('[AnalyticsService] Calling getFastWeeklyAnalytics: $uri');
    try {
      final response = await http.get(uri).timeout(Duration(seconds: 3));
      debugPrint('[AnalyticsService] getFastWeeklyAnalytics response: ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('[AnalyticsService] getFastWeeklyAnalytics failed: $e');
      // Return a mock response instead of throwing to prevent crashes
      return http.Response('{"success": false, "error": "Service timeout"}', 408);
    }
  }
  
  // Safe method to get weekly analytics with fallback
  Future<Map<String, dynamic>?> getWeeklyAnalyticsSafe(String routeId) async {
    try {
      final response = await getFastWeeklyAnalytics(routeId);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[AnalyticsService] getWeeklyAnalyticsSafe failed: $e');
    }
    return null;
  }

  // Get current week traffic analytics for the green graph
  Future<http.Response> getCurrentWeekTrafficAnalytics(String routeId) async {
    final uri = _au('/api/admin/analytics/route/$routeId/current-week');
    debugPrint('[AnalyticsService] Calling getCurrentWeekTrafficAnalytics for route $routeId: $uri');
    try {
      final response = await http.get(uri).timeout(Duration(seconds: 15));
      debugPrint('[AnalyticsService] getCurrentWeekTrafficAnalytics response: ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('[AnalyticsService] getCurrentWeekTrafficAnalytics failed: $e');
      // Return a mock response instead of throwing to prevent crashes
      return http.Response('{"success": false, "error": "Service timeout"}', 408);
    }
  }
  
  // Weekly traffic trends
  Future<http.Response> getWeeklyTrends() {
    return http.get(_au('/api/admin/analytics/weekly/trends'));
  }
  
  // Weekly traffic trends with parameters
  Future<http.Response> getWeeklyTrendsWithParams({int? weeks, String? routeId}) {
    final params = <String, String>{};
    if (weeks != null) params['weeks'] = weeks.toString();
    if (routeId != null) params['routeId'] = routeId;
    
    final uri = _au('/api/admin/analytics/weekly/trends').replace(queryParameters: params);
    return http.get(uri);
  }
  
  // Today's traffic (all routes)
  Future<http.Response> getTodayTraffic() {
    return http.get(_au('/api/analytics/traffic/today'));
  }
  
  // Today's traffic for specific route
  Future<http.Response> getTodayTrafficForRoute(String routeId) async {
    final uri = _au('/api/analytics/traffic/today/$routeId');
    debugPrint('[AnalyticsService] Calling getTodayTrafficForRoute for route $routeId: $uri');
    try {
      final response = await http.get(uri).timeout(Duration(seconds: 3));
      debugPrint('[AnalyticsService] getTodayTrafficForRoute response: ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('[AnalyticsService] getTodayTrafficForRoute failed: $e');
      // Return a mock response instead of throwing to prevent crashes
      return http.Response('{"success": false, "error": "Service timeout"}', 408);
    }
  }
  
  // Daily analytics for specific route
  Future<http.Response> getRouteDailyAnalytics(String routeId) async {
    final uri = _au('/api/admin/analytics/route/$routeId/daily');
    debugPrint('[AnalyticsService] Calling getRouteDailyAnalytics for route $routeId: $uri');
    try {
      final response = await http.get(uri).timeout(Duration(seconds: 3));
      debugPrint('[AnalyticsService] getRouteDailyAnalytics response: ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('[AnalyticsService] getRouteDailyAnalytics failed: $e');
      // Return a mock response instead of throwing to prevent crashes
      return http.Response('{"success": false, "error": "Service timeout"}', 408);
    }
  }
  
  // Peak traffic pattern analysis
  Future<http.Response> getWeeklyPeakPatterns() {
    return http.get(_au('/api/admin/analytics/weekly/peak-patterns'));
  }

  // =============================
  // ADMIN MANAGEMENT ENDPOINTS  
  // =============================
  
  // Backfill historical data
  Future<http.Response> backfillHistoricalData() {
    return http.post(_au('/api/admin/analytics/weekly/backfill'));
  }
  
  // Process analytics for specific week (updated method)
  Future<http.Response> processWeeklyAnalyticsAdmin() {
    return http.post(_au('/api/admin/analytics/weekly/process'));
  }

  // =============================
  // MIGRATION MANAGEMENT ENDPOINTS
  // =============================
  
  // Run fast CSV migration from Supabase to QuestDB
  Future<http.Response> executeFastCSVMigration() {
    return http.post(_au('/api/admin/migration/csvfast/run'));
  }

  // =============================
  // TRAFFIC MANAGEMENT ENDPOINTS
  // =============================
  
  // Trigger manual traffic analytics collection
  Future<http.Response> runTrafficCollection() {
    return http.post(_au('/api/admin/traffic/run'));
  }
  
  // Traffic analytics service status
  Future<http.Response> getTrafficAnalyticsStatus() async {
    final uri = _au('/api/admin/traffic/status');
    debugPrint('[AnalyticsService] 🚛 Calling getTrafficAnalyticsStatus: $uri');
    try {
      final response = await http.get(uri).timeout(Duration(seconds: 10));
      debugPrint('[AnalyticsService] ✅ getTrafficAnalyticsStatus response: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        debugPrint('[AnalyticsService] Traffic status body: ${response.body}');
      }
      return response;
    } catch (e) {
      debugPrint('[AnalyticsService] ❌ getTrafficAnalyticsStatus failed: $e');
      rethrow;
    }
  }

  // =============================
  // ADVANCED ANALYTICS ENDPOINTS
  // =============================
  
  // Execute custom analytics queries
  Future<http.Response> executeCustomAnalyticsQuery(Map<String, dynamic> query) {
    return http.post(
      _au('/api/admin/analytics/weekly/query'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(query),
    );
  }

  // =============================
  // REAL-TIME MONITORING ENDPOINTS
  // =============================
  
  // Service metrics (use instead of health)
  Future<http.Response> getHealthStatus() async {
    final uri = _au('/api/admin/metrics');
    debugPrint('[AnalyticsService] ❤️  Calling getHealthStatus (metrics): $uri');
    try {
      final response = await http.get(uri).timeout(Duration(seconds: 10));
      debugPrint('[AnalyticsService] ✅ getHealthStatus response: ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('[AnalyticsService] ❌ getHealthStatus failed: $e');
      rethrow;
    }
  }
  
  // System metrics (memory, uptime, etc.)
  Future<http.Response> getSystemMetrics() async {
    final uri = _au('/api/admin/metrics');
    debugPrint('[AnalyticsService] 💻 Calling getSystemMetrics: $uri');
    try {
      final response = await http.get(uri).timeout(Duration(seconds: 10));
      debugPrint('[AnalyticsService] ✅ getSystemMetrics response: ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('[AnalyticsService] ❌ getSystemMetrics failed: $e');
      rethrow;
    }
  }

  // Check if a route has analytics data with multiple fallback strategies
  Future<bool> hasRouteData(String routeId) async {
    try {
      debugPrint('[AnalyticsService] 🔍 Checking if route $routeId has data...');
      
      // Try with very short timeout first
      final response = await getRouteSummary(routeId, days: 7).timeout(Duration(seconds: 2));
      final hasData = response.statusCode == 200;
      debugPrint('[AnalyticsService] Route $routeId has data: $hasData (${response.statusCode})');
      return hasData;
    } catch (e) {
      debugPrint('[AnalyticsService] Route $routeId data check failed: $e');
      
      // If it's a timeout, the service is slow but might have data
      if (e.toString().contains('TimeoutException')) {
        debugPrint('[AnalyticsService] Service is slow but may have data - allowing attempt');
        return true; // Allow the attempt even if slow
      }
      
      // Fallback: Try traffic status to see if service is responsive
      try {
        debugPrint('[AnalyticsService] 🔄 Trying traffic status as fallback...');
        final trafficStatus = await getTrafficAnalyticsStatus().timeout(Duration(seconds: 2));
        if (trafficStatus.statusCode == 200) {
          debugPrint('[AnalyticsService] Service is responsive, assuming route has no data');
          return false; // Service works but route has no data
        }
      } catch (fallbackError) {
        debugPrint('[AnalyticsService] Service appears to be down: $fallbackError');
      }
      
      return false;
    }
  }

  // Performance monitoring for service diagnostics
  Future<Map<String, dynamic>> getServicePerformanceMetrics() async {
    final metrics = <String, dynamic>{};
    final stopwatch = Stopwatch()..start();
    
    try {
      // Test basic connectivity
      stopwatch.reset();
      final healthResponse = await getTrafficAnalyticsStatus().timeout(Duration(seconds: 3));
      metrics['health_response_time'] = stopwatch.elapsedMilliseconds;
      metrics['health_status'] = healthResponse.statusCode;
      
      // Test route data availability
      stopwatch.reset();
      final routeResponse = await getRouteSummary('1', days: 7).timeout(Duration(seconds: 5));
      metrics['route_response_time'] = stopwatch.elapsedMilliseconds;
      metrics['route_status'] = routeResponse.statusCode;
      
      // Test system metrics
      stopwatch.reset();
      final metricsResponse = await getSystemMetrics().timeout(Duration(seconds: 3));
      metrics['metrics_response_time'] = stopwatch.elapsedMilliseconds;
      metrics['metrics_status'] = metricsResponse.statusCode;
      
      metrics['overall_status'] = 'healthy';
      if (metrics['route_response_time'] > 3000) {
        metrics['overall_status'] = 'slow';
      }
      if (metrics['health_status'] != 200) {
        metrics['overall_status'] = 'unhealthy';
      }
      
    } catch (e) {
      metrics['overall_status'] = 'error';
      metrics['error'] = e.toString();
    }
    
    return metrics;
  }
}

 
