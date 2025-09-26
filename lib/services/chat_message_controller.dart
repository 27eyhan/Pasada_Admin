import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pasada_admin_application/services/gemini_ai_service.dart';
import 'package:pasada_admin_application/models/chat_message.dart';

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
  final List<ChatMessage> Function() _getMessages;

  ChatMessageController({
    required GeminiAIService aiService,
    required Function(bool) setTypingState,
    required Function(ChatMessage) addMessage,
    required VoidCallback scrollToBottom,
    required List<ChatMessage> Function() getMessages,
  })  : _aiService = aiService,
        _setTypingState = setTypingState,
        _addMessage = addMessage,
        _scrollToBottom = scrollToBottom,
        _getMessages = getMessages;

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

    if (trimmedText.startsWith('/ask')) {
      await _handleAskCommand(trimmedText);
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
      // Use backend database-based route analysis
      final raw = await _aiService.getDatabaseRouteInsights(routeId: routeId, days: 7);
      final display = _extractManongText(raw);
      _setTypingState(false);
      _addMessage(ChatMessage(
        text: display,
        isUser: false,
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

  // Handle /ask command for grounded Q&A (e.g., /ask What are the busiest hours?)
  Future<void> _handleAskCommand(String text) async {
    final question = text.substring('/ask'.length).trim();
    if (question.isEmpty) {
      _addMessage(ChatMessage(
        text: 'Usage: /ask <your question>\n\nExample: /ask What are the busiest hours for route 1?',
        isUser: false,
      ));
      return;
    }

    _addMessage(ChatMessage(text: text, isUser: true));
    _setTypingState(true);
    try {
      final raw = await _aiService.askGroundedManong(question: question);
      final display = _extractManongText(raw);
      _setTypingState(false);
      _addMessage(ChatMessage(text: display, isUser: false));
      _scrollToBottom();
    } catch (e) {
      _setTypingState(false);
      _addMessage(ChatMessage(text: 'Error processing ask: $e', isUser: false));
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
      // Build short chat history for Manong chat
      final List<Map<String, String>> history = _buildMessageHistoryForApi();
      // Append current user message
      history.add({'role': 'user', 'content': text});

      // Conversational Manong chat via backend (uses last <= 6 turns)
      final raw = await _aiService.chatWithManong(messages: history);
      final String aiResponse = _extractManongChatReply(raw);

      _setTypingState(false);
      _addMessage(ChatMessage(
        text: aiResponse,
        isUser: false,
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

  // Extract concise text from grounded Manong JSON responses
  String _extractManongText(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        // Primary formats
        if (decoded['data'] is Map) {
          final data = decoded['data'] as Map;
          if (data['geminiInsights'] is String) return data['geminiInsights'] as String;
          if (data['manongExplanation'] is String) return data['manongExplanation'] as String;
        }
        // Some endpoints may flatten message
        if (decoded['message'] is String) return decoded['message'] as String;
        if (decoded['error'] is String) return decoded['error'] as String;
      }
    } catch (_) {
      // Not JSON; fall through
    }
    return raw;
  }

  // Extract reply from conversational Manong chat response
  String _extractManongChatReply(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['data'] is Map) {
        final data = decoded['data'] as Map;
        if (data['reply'] is String) return data['reply'] as String;
        if (data['geminiInsights'] is String) return data['geminiInsights'] as String;
        if (data['manongExplanation'] is String) return data['manongExplanation'] as String;
      }
      if (decoded is Map && decoded['message'] is String) return decoded['message'] as String;
      if (decoded is Map && decoded['error'] is String) return decoded['error'] as String;
    } catch (_) {
      // Not JSON; return raw
    }
    return raw;
  }

  // Build short history from _messages for API (role/content only)
  List<Map<String, String>> _buildMessageHistoryForApi() {
    final List<Map<String, String>> items = [];
    final msgs = _getMessages();
    for (final m in msgs) {
      items.add({
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      });
    }
    // Keep only last 6 entries
    if (items.length > 6) {
      return items.sublist(items.length - 6);
    }
    return items;
  }
}
