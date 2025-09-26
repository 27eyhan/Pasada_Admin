import 'package:pasada_admin_application/services/analytics_service.dart';

class GeminiAIService {
  final AnalyticsService _analyticsService = AnalyticsService();

  // Get welcome message
  String getWelcomeMessage() {
    return "Hello! I'm Manong, your AI assistant. How can I help you today?";
  }

  // Grounded Q&A via backend Manong endpoint
  Future<String> askGroundedManong({
    required String question,
    int? routeId,
    int days = 7,
  }) async {
    try {
      if (!_analyticsService.isConfigured) {
        return "API not configured. Set API_URL in .env.";
      }
      final resp = await _analyticsService.askManong(
        question: question,
        routeId: routeId,
        days: days,
      );
      if (resp.statusCode == 404) {
        return 'Service not found (404). Ensure API_URL points to your backend and that /api/analytics/ai/ask exists.';
      }
      if (resp.statusCode != 200) {
        return 'Sorry, I could not answer that right now (status ${resp.statusCode}).';
      }
      final data = resp.body;
      // Lightweight parse without importing dart:convert here; delegate parsing to UI/controller
      return data;
    } catch (e) {
      return 'Technical error while asking Manong: $e';
    }
  }

  // Database-based route analysis via backend
  Future<String> getDatabaseRouteInsights({required int routeId, int days = 7}) async {
    try {
      if (!_analyticsService.isConfigured) {
        return "API not configured. Set API_URL in .env.";
      }
      final resp = await _analyticsService.getDatabaseRouteAnalysis(routeId: routeId, days: days);
      if (resp.statusCode == 404) {
        return 'Route analysis endpoint not found (404). Check API_URL and /api/analytics/database-analysis/route/:routeId.';
      }
      if (resp.statusCode != 200) {
        return 'Failed to analyze route (status ${resp.statusCode}).';
      }
      return resp.body;
    } catch (e) {
      return 'Technical error during route analysis: $e';
    }
  }

  // Database-based system overview via backend
  Future<String> getDatabaseOverviewInsights({int days = 7}) async {
    try {
      if (!_analyticsService.isConfigured) {
        return "API not configured. Set API_URL in .env.";
      }
      final resp = await _analyticsService.getDatabaseOverviewAnalysis(days: days);
      if (resp.statusCode == 404) {
        return 'Overview analysis endpoint not found (404). Check API_URL and /api/analytics/database-analysis/overview.';
      }
      if (resp.statusCode != 200) {
        return 'Failed to analyze overview (status ${resp.statusCode}).';
      }
      return resp.body;
    } catch (e) {
      return 'Technical error during overview analysis: $e';
    }
  }
}
