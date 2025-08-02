import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:pasada_admin_application/services/database_summary_service.dart';
import 'package:pasada_admin_application/services/chat_history_service.dart';
import 'package:pasada_admin_application/services/auth_service.dart';
import 'package:pasada_admin_application/services/route_traffic_service.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart'; // Add this import for Clipboard

class AiChat extends StatefulWidget {
  const AiChat({super.key});

  @override
  _AiChatState createState() => _AiChatState();
}

class _AiChatState extends State<AiChat> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isHistoryOpen = false; // Track if history drawer is open
  late Gemini gemini;

  // Services
  final DatabaseSummaryService _databaseService = DatabaseSummaryService();
  final ChatHistoryService _chatService = ChatHistoryService();
  final AuthService _authService = AuthService();
  final RouteTrafficService _routeTrafficService = RouteTrafficService();

  // Chat history for tracking the conversation
  final List<Content> _chatHistory = [];
  List<Map<String, dynamic>> _savedChats = [];

  // System instruction to guide AI responses
  String systemInstruction =
      """You are Manong, a helpful AI assistant for Pasada, a modern jeepney transportation system in the Philippines. Our team is composed of Calvin John Crehencia, Adrian De Guzman, Ethan Andrei Humarang and Fyke Simon Tonel, we are called CAFE Tech. Don't use emoji.

You are focused in Fleet Management System, Modern Jeepney Transportation System in the Philippines, Ride-Hailing, and Traffic Advisory in the Malinta to Novaliches route in the Philippines. You're implemented in the admin website of Pasada: An AI-Powered Ride-Hailing and Fleet Management Platform for Modernized Jeepneys Services with Mobile Integration and RealTime Analytics.

You're role is to be an advisor, providing suggestions based on the data inside the website. Limit your answer in 3 sentences and summarize if necessary. Don't answer other topics, only those mentioned above.""";

  @override
  void initState() {
    super.initState();
    _loadAuthentication();
    _loadChatHistory();
    // Initialize Gemini with the API key
    final apiKey = dotenv.env['GEMINI_API'] ?? '';

    if (apiKey.isEmpty) {
      print('Warning: GEMINI_API key is not set in .env file');
      // Still add the welcome message but inform about missing API key
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _messages.add(ChatMessage(
            text:
                "Hello! I'm Manong, your AI assistant. However, I need an API key to function properly. Please configure the GEMINI_API in your .env file.",
            isUser: false,
          ));
        });
      });
    } else {
      // First initialize Gemini, then access instance
      Gemini.init(apiKey: apiKey);
      gemini = Gemini.instance;

      // Initialize chat history with system instruction if provided
      if (systemInstruction.isNotEmpty) {
        _chatHistory.add(
            Content(role: 'system', parts: [Part.text(systemInstruction)]));
      }

      // Add the welcome message when the widget initializes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _messages.add(ChatMessage(
            text:
                "Hello! I'm Manong, your AI assistant. How can I help you today?",
            isUser: false,
          ));
        });
      });
    }
  }

  // Load admin authentication
  Future<void> _loadAuthentication() async {
    await _authService.loadAdminID();
    if (_authService.currentAdminID == null) {
      print(
          'Warning: No admin ID found. AI Chat history functionality may be limited.');
    } else {
      print('Admin ID loaded: ${_authService.currentAdminID}');
    }
  }

  // Load chat history from the database
  Future<void> _loadChatHistory() async {
    try {
      final chats = await _chatService.getChatHistories();
      setState(() {
        _savedChats = chats;
      });
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  // Save current chat session
  Future<void> _saveChatSession() async {
    if (_messages.isEmpty) return;

    try {
      // Generate a title from first message for display purposes
      final title = '${_messages.first.text.split(' ').take(5).join(' ')}...';

      // Separate user messages and AI responses
      final userMessages = _messages
          .where((msg) => msg.isUser)
          .map((msg) => {
                'text': msg.text,
                'timestamp': DateTime.now().toIso8601String(),
              })
          .toList();

      final aiMessages = _messages
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot save chat: You need to be logged in.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Pass separate arrays to the service
      await _chatService.saveChatSession(title, userMessages, aiMessages);
      await _loadChatHistory(); // Reload the chat history

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving chat session: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Load a specific chat session
  Future<void> _loadChatSession(String chatId) async {
    try {
      final chat = await _chatService.getChatSession(chatId);
      if (chat != null) {
        setState(() {
          _messages.clear();

          // Create a temporary list to hold all messages with timestamps
          final List<Map<String, dynamic>> tempMessages = [];

          // Load user messages
          if (chat['messages'] is List &&
              (chat['messages'] as List).isNotEmpty) {
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

          // Add sorted messages to the UI
          for (var msg in tempMessages) {
            _messages.add(ChatMessage(
              text: msg['text'],
              isUser: msg['isUser'],
            ));
          }
        });
      }
    } catch (e) {
      print('Error loading chat session: $e');
    }
  }

  // Delete a chat session
  Future<void> _deleteChatSession(String chatId) async {
    try {
      await _chatService.deleteChatSession(chatId);
      await _loadChatHistory(); // Reload the chat history
    } catch (e) {
      print('Error deleting chat session: $e');
    }
  }

  // Method to set system instruction
  void setSystemInstruction(String instruction) {
    setState(() {
      systemInstruction = instruction;

      // Reset chat history and add system instruction
      _chatHistory.clear();
      if (systemInstruction.isNotEmpty) {
        _chatHistory.add(
            Content(role: 'system', parts: [Part.text(systemInstruction)]));
      }
    });
  }

  Future<String> _getGeminiResponse(String message) async {
    try {
      final apiKey = dotenv.env['GEMINI_API'] ?? '';
      if (apiKey.isEmpty) {
        return "I'm sorry, but I can't respond without an API key. Please configure the GEMINI_API in your .env file.";
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
            await gemini.text("$enhancedInstruction\n\nUser: $message");

        if (response != null && response.output != null) {
          return response.output?.trim() ?? "No response";
        }
      } catch (innerError) {
        print('First attempt failed: $innerError');

        // Fall back to simplest possible request
        try {
          final response = await gemini.text(message.trim());
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

  void _handleSubmitted(String text) {
    _messageController.clear();
    if (text.trim().startsWith('/routetraffic')) {
      final parts = text.substring('/routetraffic'.length).trim().split(',');
      if (parts.length != 2) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: 'Usage: /routetraffic <origin, destination>',
            isUser: false,
          ));
        });
        return;
      }
      final origin = parts[0].trim();
      final destination = parts[1].trim();
      setState(() {
        _messages.add(ChatMessage(text: text, isUser: true));
        _isTyping = true;
      });
      _routeTrafficService
          .getRouteTraffic(origin, destination)
          .then((trafficInfo) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(text: trafficInfo, isUser: false));
        });
      });
      return;
    }
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
      ));
      _isTyping = true;
    });

    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Get response from Gemini API
    _getGeminiResponse(text).then((aiResponse) {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: aiResponse,
          isUser: false,
          onRefresh: () => _regenerateResponse(text),
        ));
      });

      // Scroll to bottom again after response
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Future<void> _regenerateResponse(String originalQuery) async {
    setState(() {
      _isTyping = true;
    });

    try {
      final response = await _getGeminiResponse(originalQuery);
      setState(() {
        // Remove the last message (the one we're regenerating)
        _messages.removeLast();
        // Add the new response
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          onRefresh: () => _regenerateResponse(originalQuery),
        ));
        _isTyping = false;
      });

      // Scroll to the new message
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
      });
      print('Error regenerating response: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final padding = mediaQuery.padding;

    return Scaffold(
      backgroundColor: Palette.whiteColor,
      appBar: AppBarSearch(),
      drawer: MyDrawer(),
      body: SafeArea(
        child: Row(
          children: [
            // Chat History Drawer
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: _isHistoryOpen ? 300 : 0,
              child: _isHistoryOpen
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Palette.greyColor, width: 1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Palette.greyColor),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Chat History',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () =>
                                      setState(() => _isHistoryOpen = false),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _savedChats.length,
                              itemBuilder: (context, index) {
                                final chat = _savedChats[index];
                                return ListTile(
                                  title: Text(
                                    chat['title'] ?? 'Untitled Chat',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    DateTime.parse(chat['created_at'])
                                        .toString(),
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        _deleteChatSession(chat['history_id']),
                                  ),
                                  onTap: () =>
                                      _loadChatSession(chat['history_id']),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),

            // Main Chat Area
            Expanded(
              child: Column(
                children: [
                  // Top bar with history and save buttons
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 212, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.history),
                          onPressed: () =>
                              setState(() => _isHistoryOpen = !_isHistoryOpen),
                          tooltip: 'Chat History',
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.save_outlined),
                          onPressed: _saveChatSession,
                          tooltip: 'Save Chat',
                        ),
                      ],
                    ),
                  ),

                  // Main chat container
                  Expanded(
                    child: Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 212, vertical: 8),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Palette.greyColor, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Palette.blackColor.withValues(alpha: 128),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                        color: Palette.whiteColor,
                      ),
                      child: Column(
                        children: [
                          // AI Assistant header
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            color: Palette.whiteColor.withValues(alpha: 128),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Palette.blackColor,
                                  child: Icon(Icons.smart_toy,
                                      color: Colors.white),
                                ),
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Manong',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Chat messages area
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: ListView.builder(
                                controller: _scrollController,
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  return _messages[index];
                                },
                              ),
                            ),
                          ),

                          // AI typing indicator
                          if (_isTyping)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Manong is typing...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),

                          // Input area
                          Container(
                            padding: EdgeInsets.only(
                              bottom: padding.bottom + 8,
                              top: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Palette.whiteColor,
                            ),
                            child: Row(
                              children: [
                                // Text input field
                                Container(
                                  margin: EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Palette.blackColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.add, color: Colors.white),
                                    onPressed: () {
                                      // Handle plus button action here
                                    },
                                    padding: EdgeInsets.all(8),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Palette.greyColor,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: TextField(
                                      controller: _messageController,
                                      decoration: InputDecoration(
                                        hintText: 'Ask me anything...',
                                        border: InputBorder.none,
                                      ),
                                      maxLines: null,
                                      textInputAction: TextInputAction.send,
                                      onSubmitted: _handleSubmitted,
                                    ),
                                  ),
                                ),

                                // Send button
                                SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Palette.blackColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.send, color: Colors.white),
                                    onPressed: () => _handleSubmitted(
                                        _messageController.text),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final VoidCallback? onRefresh;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.onRefresh,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Palette.blackColor,
              child: Icon(Icons.smart_toy, color: Palette.whiteColor, size: 16),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(
                    maxWidth: screenWidth * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? Palette.greyColor : Palette.greyColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Palette.blackColor : Palette.blackColor,
                    ),
                  ),
                ),

                // Action buttons for AI messages
                if (!isUser) ...[
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.copy_outlined, size: 16),
                        onPressed: () => _copyToClipboard(context),
                        tooltip: 'Copy message',
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      SizedBox(width: 4),
                      if (onRefresh != null)
                        IconButton(
                          icon: Icon(Icons.refresh_outlined, size: 16),
                          onPressed: onRefresh,
                          tooltip: 'Regenerate response',
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Palette.blackColor,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
