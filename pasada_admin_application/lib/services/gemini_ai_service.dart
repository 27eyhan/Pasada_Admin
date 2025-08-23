import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:pasada_admin_application/services/database_summary_service.dart';
import 'package:pasada_admin_application/services/route_traffic_service.dart';

class GeminiAIService {
  late Gemini _gemini;
  bool _isInitialized = false;
  final DatabaseSummaryService _databaseService = DatabaseSummaryService();
  final RouteTrafficService _routeTrafficService = RouteTrafficService();

  // System instruction to guide AI responses
  String systemInstruction =
      """You are Manong, a helpful AI assistant for Pasada, a modern jeepney transportation system in the Philippines. Our team is composed of Calvin John Crehencia, Adrian De Guzman, Ethan Andrei Humarang and Fyke Simon Tonel, we are called CAFE Tech. Don't use emoji.

You are focused in Fleet Management System, Modern Jeepney Transportation System in the Philippines, Ride-Hailing, and Traffic Advisory in the Malinta to Novaliches route in the Philippines. You're implemented in the admin website of Pasada: An AI-Powered Ride-Hailing and Fleet Management Platform for Modernized Jeepneys Services with Mobile Integration and RealTime Analytics.

You're role is to be an advisor, providing suggestions based on the data inside the website. Limit your answer in 3 sentences and summarize if necessary. Don't answer other topics, only those mentioned above.""";

  // Initialize Gemini AI service
  bool initialize() {
    try {
      final apiKey = dotenv.env['GEMINI_API'] ?? '';
      if (apiKey.isEmpty) {
        print('Warning: GEMINI_API key is not set in .env file');
        return false;
      }

      Gemini.init(apiKey: apiKey);
      _gemini = Gemini.instance;
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing Gemini AI: $e');
      return false;
    }
  }

  // Check if service is properly initialized
  bool get isInitialized => _isInitialized;

  // Get API key status
  bool get hasApiKey => dotenv.env['GEMINI_API']?.isNotEmpty ?? false;

  // Set system instruction
  void setSystemInstruction(String instruction) {
    systemInstruction = instruction;
  }

  // Get general Gemini response
  Future<String> getGeminiResponse(String message) async {
    try {
      if (!hasApiKey) {
        return "I'm sorry, but I can't respond without an API key. Please configure the GEMINI_API in your .env file.";
      }

      if (!_isInitialized) {
        final initialized = initialize();
        if (!initialized) {
          return "Failed to initialize AI service. Please check your API configuration.";
        }
      }

      // Get database context from our service
      String databaseContext = await _databaseService.getFullDatabaseContext();

      // Combine system instruction with database context
      String enhancedInstruction = """$systemInstruction
      
Current System Data:
$databaseContext

Please use this data to provide informed suggestions.
""";

      // Use a simpler approach: text-only input with enhanced instruction
      try {
        final response =
            await _gemini.text("$enhancedInstruction\n\nUser: $message");

        if (response != null && response.output != null) {
          return response.output?.trim() ?? "No response";
        }
      } catch (innerError) {
        print('First attempt failed: $innerError');

        // Fall back to simplest possible request
        try {
          final response = await _gemini.text(message.trim());
          if (response != null && response.output != null) {
            return response.output?.trim() ?? "No response";
          }
        } catch (fallbackError) {
          print('Fallback attempt failed: $fallbackError');
          return "Sorry, I couldn't generate a response at the moment. Technical error: $fallbackError";
        }
      }

      return "Sorry, I couldn't generate a response at the moment.";
    } catch (e) {
      print('Exception: $e');
      return "Technical error occurred: $e";
    }
  }

  // Get traffic analysis with AI interpretation
  Future<String> getTrafficAnalysis(int routeId) async {
    try {
      if (!hasApiKey) {
        return "I'm sorry, but I can't analyze traffic data without an API key. Please configure the GEMINI_API in your .env file.";
      }

      if (!_isInitialized) {
        final initialized = initialize();
        if (!initialized) {
          return "Failed to initialize AI service for traffic analysis. Please check your API configuration.";
        }
      }

      // Get traffic data for AI analysis
      final trafficPrompt =
          await _routeTrafficService.getRouteTrafficForAI(routeId);

      if (trafficPrompt.startsWith('Error:')) {
        return trafficPrompt; // Return error as-is
      }

      // Get database context for additional insights
      String databaseContext = await _databaseService.getFullDatabaseContext();

      // Enhanced system instruction for traffic analysis
      String trafficAnalysisInstruction = """$systemInstruction

You are specifically analyzing route traffic data to provide actionable insights for fleet management.

Current System Data:
$databaseContext

IMPORTANT: You must follow this EXACT output format:

1. First paragraph: Show traffic density categories with ETAs exactly as provided
2. Second paragraph: Provide explanation and suggestions

For traffic analysis, focus on:
- Explaining the current traffic density levels (Light: minimal delays, Normal: expected delays, Heavy: significant delays)
- Providing practical fleet management suggestions based on traffic conditions
- Offering recommendations for drivers and passengers
- Considering impact on jeepney operations and scheduling

Always start your response with the traffic density format provided, then follow with explanations and actionable advice.
""";

      try {
        final response =
            await _gemini.text("$trafficAnalysisInstruction\n\n$trafficPrompt");

        if (response != null && response.output != null) {
          return response.output?.trim() ??
              "Unable to analyze traffic data at this time.";
        }
      } catch (innerError) {
        print('Traffic analysis failed: $innerError');

        // Fallback with simplified prompt
        try {
          final fallbackPrompt =
              "Analyze this traffic data and provide suggestions: $trafficPrompt";
          final response = await _gemini.text(fallbackPrompt);
          if (response != null && response.output != null) {
            return response.output?.trim() ??
                "Unable to analyze traffic data at this time.";
          }
        } catch (fallbackError) {
          print('Traffic analysis fallback failed: $fallbackError');
          return "Sorry, I couldn't analyze the traffic data at the moment. Technical error: $fallbackError";
        }
      }

      return "Sorry, I couldn't analyze the traffic data at the moment.";
    } catch (e) {
      print('Traffic analysis exception: $e');
      return "Technical error occurred while analyzing traffic: $e";
    }
  }

  // Get welcome message based on initialization status
  String getWelcomeMessage() {
    if (!hasApiKey) {
      return "Hello! I'm Manong, your AI assistant. However, I need an API key to function properly. Please configure the GEMINI_API in your .env file.";
    }
    return "Hello! I'm Manong, your AI assistant. How can I help you today?";
  }
}
