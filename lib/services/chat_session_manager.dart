import 'package:flutter/foundation.dart';
import 'package:pasada_admin_application/services/chat_history_service.dart';
import 'package:pasada_admin_application/services/auth_service.dart';
import 'package:pasada_admin_application/models/chat_message.dart';

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
      // Generate a title from first message for display purposes
      final title = '${messages.first.text.split(' ').take(5).join(' ')}...';

      // Separate user messages and AI responses
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

  // Load a specific chat session
  Future<List<ChatMessage>?> loadChatSession(String chatId) async {
    try {
      final chat = await _chatService.getChatSession(chatId);
      if (chat == null) return null;

      final List<ChatMessage> messages = [];

      // Create a temporary list to hold all messages with timestamps
      final List<Map<String, dynamic>> tempMessages = [];

      // Load user messages
      if (chat['messages'] is List && (chat['messages'] as List).isNotEmpty) {
        List<dynamic> userMessages = chat['messages'];
        for (var msg in userMessages) {
          tempMessages.add({
            'text': msg['text'],
            'isUser': true,
            'timestamp': msg['timestamp'] ?? '',
          });
        }
      }

      // Load AI messages
      if (chat['ai_message'] is List &&
          (chat['ai_message'] as List).isNotEmpty) {
        List<dynamic> aiMessages = chat['ai_message'];
        for (var msg in aiMessages) {
          tempMessages.add({
            'text': msg['text'],
            'isUser': false,
            'timestamp': msg['timestamp'] ?? '',
          });
        }
      }

      // Sort messages by timestamp
      tempMessages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

      // Add sorted messages to the result
      for (var msg in tempMessages) {
        messages.add(ChatMessage(
          text: msg['text'],
          isUser: msg['isUser'],
        ));
      }

      return messages;
    } catch (e) {
      debugPrint('Error loading chat session: $e');
      return null;
    }
  }

  // Delete a chat session
  Future<void> deleteChatSession(String chatId) async {
    try {
      await _chatService.deleteChatSession(chatId);
      await loadChatHistory(); // Reload the chat history
    } catch (e) {
      debugPrint('Error deleting chat session: $e');
      rethrow;
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => _authService.currentAdminID != null;

  // Get current admin ID
  String? get currentAdminID => _authService.currentAdminID?.toString();
}
