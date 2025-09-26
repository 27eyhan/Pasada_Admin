import 'package:pasada_admin_application/services/analytics_service.dart';
import 'dart:convert';

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

  // Conversational Manong chat via backend (history-aware)
  Future<String> chatWithManong({
    required List<Map<String, String>> messages,
    int days = 7,
  }) async {
    try {
      if (!_analyticsService.isConfigured) {
        return "API not configured. Set API_URL in .env.";
      }
      // Keep only last 6 turns
      final recent = messages.length > 6 ? messages.sublist(messages.length - 6) : messages;
      final resp = await _analyticsService.chatManong(messages: recent, days: days);
      if (resp.statusCode != 200) {
        return 'Sorry, I could not process the chat right now (status ${resp.statusCode}).';
      }
      return resp.body;
    } catch (e) {
      return 'Technical error while chatting with Manong: $e';
    }
  }

  // Generate a short chat title (4-6 words, no punctuation)
  Future<String?> generateChatTitle({required List<Map<String, String>> recentMessages}) async {
    try {
      if (!_analyticsService.isConfigured) return null;
      final List<Map<String, String>> history = [];
      // Constrain to last 4 messages for context
      final recent = recentMessages.length > 4
          ? recentMessages.sublist(recentMessages.length - 4)
          : recentMessages;
      history.addAll(recent);
      // Add system instruction asking for a concise title only
      history.insert(0, {
        'role': 'system',
        'content': 'Given the following short conversation, generate a concise 4-6 word title summarizing the topic. Return ONLY the title text, no punctuation, no quotes.'
      });
      final resp = await _analyticsService.chatManong(messages: history, days: 7);
      if (resp.statusCode != 200) return null;
      final raw = resp.body;
      // Extract reply
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map && decoded['data'] is Map) {
          final data = decoded['data'] as Map;
          String? title = data['reply'] as String?;
          if (title != null) {
            title = title.replaceAll(RegExp(r'[\"\.!?\n]'), ' ').trim();
            // Collapse whitespace and cap length
            title = title.split(RegExp(r'\s+')).take(8).join(' ');
            if (title.isNotEmpty) return title;
          }
        }
      } catch (_) {}
      return null;
    } catch (_) {
      return null;
    }
  }
  // Database-based route analysis via backend
  Future<String> getDatabaseRouteInsights({required int routeId, int days = 7}) async {
    try {
      if (!_analyticsService.isConfigured) {
        return "API not configured. Set API_URL in .env.";
      }
      final resp = await _analyticsService.getDatabaseRouteAnalysis(routeId: routeId, days: days);
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
      if (resp.statusCode != 200) {
        return 'Failed to analyze overview (status ${resp.statusCode}).';
      }
      return resp.body;
    } catch (e) {
      return 'Technical error during overview analysis: $e';
    }
  }
}
