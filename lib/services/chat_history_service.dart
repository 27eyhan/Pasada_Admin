import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/services/auth_service.dart';
import 'dart:convert';

class ChatHistoryService {
  // Singleton pattern
  ChatHistoryService._internal();
  static final ChatHistoryService _instance = ChatHistoryService._internal();
  factory ChatHistoryService() => _instance;

  final SupabaseClient supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  // Fetch all chat histories for the current admin
  Future<List<Map<String, dynamic>>> getChatHistories() async {
    try {
      final response = await supabase
          .from('aiChat_history')
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching chat histories: $e');
      throw Exception('Error fetching chat histories: $e');
    }
  }

  // Save a new chat session
  Future<void> saveChatSession(String title, List<Map<String, dynamic>> userMessages, List<Map<String, dynamic>> aiMessages) async {
    try {
      // Get current admin ID from AuthService
      final int? adminId = _authService.currentAdminID;
      if (adminId == null) {
        throw Exception('No admin ID found. Please log in again.');
      }

      await supabase.from('aiChat_history').insert({
        'admin_id': adminId,
        // Columns are TEXT; store JSON-encoded arrays
        'messages': jsonEncode(userMessages),
        'ai_message': jsonEncode(aiMessages),
        'title': title,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error saving chat session: $e');
    }
  }

  // Delete a chat session
  Future<void> deleteChatSession(dynamic chatId) async {
    try {
      await supabase
          .from('aiChat_history')
          .delete()
          .eq('history_id', chatId);
    } catch (e) {
      throw Exception('Error deleting chat session: $e');
    }
  }

  // Get a specific chat session
  Future<Map<String, dynamic>?> getChatSession(dynamic chatId) async {
    try {
      final response = await supabase
          .from('aiChat_history')
          .select()
          .eq('history_id', chatId)
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Error fetching chat session: $e');
    }
  }
} 