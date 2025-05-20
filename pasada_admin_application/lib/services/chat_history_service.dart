import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/services/auth_service.dart';

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
      print('Error fetching chat histories: $e');
      return [];
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
        'messages': userMessages,
        'ai_message': aiMessages,
        'title': title,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving chat session: $e');
      rethrow;
    }
  }

  // Delete a chat session
  Future<void> deleteChatSession(String chatId) async {
    try {
      await supabase
          .from('aiChat_history')
          .delete()
          .eq('history_id', chatId);
    } catch (e) {
      print('Error deleting chat session: $e');
      rethrow;
    }
  }

  // Get a specific chat session
  Future<Map<String, dynamic>?> getChatSession(String chatId) async {
    try {
      final response = await supabase
          .from('aiChat_history')
          .select()
          .eq('history_id', chatId)
          .single();
      
      return response;
    } catch (e) {
      print('Error fetching chat session: $e');
      return null;
    }
  }
} 