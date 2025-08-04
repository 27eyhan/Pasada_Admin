import 'package:flutter/material.dart';
import 'package:pasada_admin_application/services/gemini_ai_service.dart';
import 'package:pasada_admin_application/widgets/chat_message_widget.dart';

enum ChatMessageType {
  user,
  ai,
  command,
  error,
}

class ChatMessageResult {
  final ChatMessage message;
  final ChatMessageType type;
  final bool shouldScroll;
  final VoidCallback? onRefresh;

  ChatMessageResult({
    required this.message,
    required this.type,
    this.shouldScroll = true,
    this.onRefresh,
  });
}

class ChatMessageController {
  final GeminiAIService _aiService;
  final Function(bool) _setTypingState;
  final Function(ChatMessage) _addMessage;
  final VoidCallback _scrollToBottom;

  ChatMessageController({
    required GeminiAIService aiService,
    required Function(bool) setTypingState,
    required Function(ChatMessage) addMessage,
    required VoidCallback scrollToBottom,
  })  : _aiService = aiService,
        _setTypingState = setTypingState,
        _addMessage = addMessage,
        _scrollToBottom = scrollToBottom;

  // Handle submitted message
  Future<void> handleSubmittedMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Check for commands first
    if (await _handleCommand(text)) {
      return;
    }

    // Handle regular message
    await _handleRegularMessage(text);
  }

  // Handle command messages (like /routetraffic)
  Future<bool> _handleCommand(String text) async {
    final trimmedText = text.trim();

    if (trimmedText.startsWith('/routetraffic')) {
      await _handleRouteTrafficCommand(trimmedText);
      return true;
    }

    // Add more commands here as needed
    // if (trimmedText.startsWith('/anothercommand')) {
    //   await _handleAnotherCommand(trimmedText);
    //   return true;
    // }

    return false;
  }

  // Handle /routetraffic command
  Future<void> _handleRouteTrafficCommand(String text) async {
    final idStr = text.substring('/routetraffic'.length).trim();
    final routeId = int.tryParse(idStr);

    if (routeId == null) {
      _addMessage(ChatMessage(
        text: 'Usage: /routetraffic <routeId>\n\nExample: /routetraffic 1',
        isUser: false,
      ));
      return;
    }

    // Add user message
    _addMessage(ChatMessage(text: text, isUser: true));
    _setTypingState(true);

    try {
      // Get traffic analysis from AI service
      final aiResponse = await _aiService.getTrafficAnalysis(routeId);

      _setTypingState(false);
      _addMessage(ChatMessage(
        text: aiResponse,
        isUser: false,
        onRefresh: () => _regenerateTrafficResponse(routeId),
      ));

      _scrollToBottom();
    } catch (e) {
      _setTypingState(false);
      _addMessage(ChatMessage(
        text: 'Error processing route traffic command: $e',
        isUser: false,
      ));
    }
  }

  // Handle regular chat messages
  Future<void> _handleRegularMessage(String text) async {
    // Add user message
    _addMessage(ChatMessage(
      text: text,
      isUser: true,
    ));
    _setTypingState(true);

    // Scroll to show user message
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollToBottom();
    });

    try {
      // Get response from AI service
      final aiResponse = await _aiService.getGeminiResponse(text);

      _setTypingState(false);
      _addMessage(ChatMessage(
        text: aiResponse,
        isUser: false,
        onRefresh: () => _regenerateResponse(text),
      ));

      // Scroll to show AI response
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    } catch (e) {
      _setTypingState(false);
      _addMessage(ChatMessage(
        text: 'Error generating response: $e',
        isUser: false,
      ));
    }
  }

  // Regenerate response for regular messages
  Future<void> _regenerateResponse(String originalQuery) async {
    _setTypingState(true);

    try {
      final response = await _aiService.getGeminiResponse(originalQuery);

      _setTypingState(false);

      // Return the new response for the caller to handle
      // (The caller will remove the last message and add the new one)
      _addMessage(ChatMessage(
        text: response,
        isUser: false,
        onRefresh: () => _regenerateResponse(originalQuery),
      ));

      // Scroll to the new message
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    } catch (e) {
      _setTypingState(false);
      print('Error regenerating response: $e');
    }
  }

  // Regenerate traffic analysis response
  Future<void> _regenerateTrafficResponse(int routeId) async {
    _setTypingState(true);

    try {
      final response = await _aiService.getTrafficAnalysis(routeId);

      _setTypingState(false);

      // Return the new response for the caller to handle
      _addMessage(ChatMessage(
        text: response,
        isUser: false,
        onRefresh: () => _regenerateTrafficResponse(routeId),
      ));

      // Scroll to the new message
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    } catch (e) {
      _setTypingState(false);
      print('Error regenerating traffic response: $e');
    }
  }

  // Get available commands help
  String getCommandsHelp() {
    return '''Available commands:
/routetraffic <routeId> - Get traffic analysis for a specific route
Example: /routetraffic 1

More commands coming soon...''';
  }

  // Check if text is a command
  bool isCommand(String text) {
    final trimmedText = text.trim();
    return trimmedText.startsWith('/');
  }

  // Parse command and get command type
  String? getCommandType(String text) {
    final trimmedText = text.trim();
    if (trimmedText.startsWith('/routetraffic')) {
      return 'routetraffic';
    }
    return null;
  }
}
