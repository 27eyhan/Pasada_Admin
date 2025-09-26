import 'package:flutter/foundation.dart';
import 'package:pasada_admin_application/services/chat_history_service.dart';
import 'package:pasada_admin_application/services/auth_service.dart';
import 'package:pasada_admin_application/models/chat_message.dart';
import 'package:pasada_admin_application/services/gemini_ai_service.dart';
import 'dart:convert';

class ChatSessionManager {
  final ChatHistoryService _chatService = ChatHistoryService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _savedChats = [];

  // Get saved chats
  List<Map<String, dynamic>> get savedChats => _savedChats;

  // Load admin authentication
  Future<void> loadAuthentication() async {
    await _authService.loadAdminID();
    if (_authService.currentAdminID == null) {
      debugPrint(
          'Warning: No admin ID found. AI Chat history functionality may be limited.');
    } else {
      debugPrint('Admin ID loaded: ${_authService.currentAdminID}');
    }
  }

  // Load chat history from the database
  Future<void> loadChatHistory() async {
    try {
      final chats = await _chatService.getChatHistories();
      _savedChats = chats;
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      rethrow;
    }
  }

  // Save current chat session
  Future<String> saveChatSession(List<ChatMessage> messages) async {
    if (messages.isEmpty) {
      throw Exception('No messages to save');
    }

    try {
      // Build recent history for title generation
      final List<Map<String, String>> recent = messages
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();

      // Generate a concise title via Manong chat endpoint
      String title = '${messages.first.text.split(' ').take(5).join(' ')}...';
      try {
        final ai = GeminiAIService();
        final generated = await ai.generateChatTitle(recentMessages: recent);
        if (generated != null && generated.trim().isNotEmpty) {
          title = generated.trim();
        }
      } catch (_) {}

      // Separate user messages and AI responses (schema columns: messages, ai_message)
      final userMessages = messages
          .where((msg) => msg.isUser)
          .map((msg) => {
                'text': msg.text,
                'timestamp': DateTime.now().toIso8601String(),
              })
          .toList();

      final aiMessages = messages
          .where((msg) => !msg.isUser)
          .map((msg) => {
                'text': msg.text,
                'timestamp': DateTime.now().toIso8601String(),
              })
          .toList();

      // Ensure admin ID is loaded before saving
      if (_authService.currentAdminID == null) {
        await _authService.loadAdminID();
        if (_authService.currentAdminID == null) {
          throw Exception('Cannot save chat: You need to be logged in.');
        }
      }

      // Pass separate arrays to the service
      await _chatService.saveChatSession(title, userMessages, aiMessages);
      await loadChatHistory(); // Reload the chat history

      return 'Chat saved successfully';
    } catch (e) {
      debugPrint('Error saving chat session: $e');
      throw Exception('Error saving chat: ${e.toString()}');
    }
  }

  // Load a specific chat session (accept int or string IDs)
  Future<List<ChatMessage>?> loadChatSession(dynamic chatId) async {
    try {
      final chat = await _chatService.getChatSession(chatId);
      if (chat == null) return null;

      final List<ChatMessage> messages = [];

      // Support both legacy combined arrays and split schema
      final List<Map<String, dynamic>> combined = [];
      // messages may be TEXT (string JSON) or List
      dynamic rawMessages = chat['messages'];
      if (rawMessages is String) {
        try { rawMessages = jsonDecode(rawMessages); } catch (_) {}
      }
      if (rawMessages is List) {
        for (final m in rawMessages) {
          if (m is Map) {
            combined.add({
              'text': m['text'],
              'isUser': true,
              'timestamp': m['timestamp'] ?? '',
            });
          }
        }
      }
      // ai_message may be TEXT (string JSON) or List
      dynamic rawAi = chat['ai_message'];
      if (rawAi is String) {
        try { rawAi = jsonDecode(rawAi); } catch (_) {}
      }
      if (rawAi is List) {
        for (final m in rawAi) {
          if (m is Map) {
            combined.add({
              'text': m['text'],
              'isUser': false,
              'timestamp': m['timestamp'] ?? '',
            });
          }
        }
      }
      // If legacy: some records may store a single 'messages' array of role+text
      if (combined.isEmpty && rawMessages is List) {
        for (final m in rawMessages) {
          if (m is Map && m['role'] != null) {
            combined.add({
              'text': m['text'],
              'isUser': (m['role'] == 'user'),
              'timestamp': m['timestamp'] ?? '',
            });
          }
        }
      }
      // Sort by timestamp if present
      combined.sort((a, b) => (a['timestamp'] ?? '').toString().compareTo((b['timestamp'] ?? '').toString()));
      for (final m in combined) {
        if (m['text'] != null) {
          messages.add(ChatMessage(text: m['text'], isUser: m['isUser'] == true));
        }
      }

      return messages;
    } catch (e) {
      debugPrint('Error loading chat session: $e');
      return null;
    }
  }

  // Delete a chat session and refresh list
  Future<void> deleteChatSession(dynamic chatId) async {
    try {
      await _chatService.deleteChatSession(chatId);
      await loadChatHistory();
    } catch (e) {
      debugPrint('Error deleting chat session: $e');
      rethrow;
    }
  }
}
