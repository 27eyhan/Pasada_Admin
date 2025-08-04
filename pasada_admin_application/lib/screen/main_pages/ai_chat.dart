import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:pasada_admin_application/services/gemini_ai_service.dart';
import 'package:pasada_admin_application/services/chat_session_manager.dart';
import 'package:pasada_admin_application/services/chat_message_controller.dart';
import 'package:pasada_admin_application/widgets/chat_message_widget.dart';

class AiChat extends StatefulWidget {
  const AiChat({super.key});

  @override
  _AiChatState createState() => _AiChatState();
}

class _AiChatState extends State<AiChat> {
  // UI Controllers
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // UI State
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isHistoryOpen = false;

  // Services
  late GeminiAIService _aiService;
  late ChatSessionManager _sessionManager;
  late ChatMessageController _messageController;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadInitialData();
  }

  // Initialize all services
  void _initializeServices() {
    _aiService = GeminiAIService();
    _sessionManager = ChatSessionManager();
    _messageController = ChatMessageController(
      aiService: _aiService,
      setTypingState: _setTypingState,
      addMessage: _addMessage,
      scrollToBottom: _scrollToBottom,
    );
  }

  // Load initial data and setup
  Future<void> _loadInitialData() async {
    // Initialize AI service and load authentication
    _aiService.initialize();
    await _sessionManager.loadAuthentication();
    await _sessionManager.loadChatHistory();

    // Add welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add(ChatMessage(
          text: _aiService.getWelcomeMessage(),
          isUser: false,
        ));
      });
    });
  }

  // UI State Management
  void _setTypingState(bool isTyping) {
    setState(() {
      _isTyping = isTyping;
    });
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Message handling
  void _handleSubmitted(String text) {
    _textController.clear();
    _messageController.handleSubmittedMessage(text);
  }

  // Chat History Management
  Future<void> _saveChatSession() async {
    if (_messages.isEmpty) return;

    try {
      final result = await _sessionManager.saveChatSession(_messages);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadChatSession(String chatId) async {
    try {
      final messages = await _sessionManager.loadChatSession(chatId);
      if (messages != null) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
        });
      }
    } catch (e) {
      print('Error loading chat session: $e');
    }
  }

  Future<void> _deleteChatSession(String chatId) async {
    try {
      await _sessionManager.deleteChatSession(chatId);
    } catch (e) {
      print('Error deleting chat session: $e');
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
                              itemCount: _sessionManager.savedChats.length,
                              itemBuilder: (context, index) {
                                final chat = _sessionManager.savedChats[index];
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
                                // Plus button
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

                                // Text input field
                                Expanded(
                                  child: Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Palette.greyColor,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: TextField(
                                      controller: _textController,
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
                                    onPressed: () =>
                                        _handleSubmitted(_textController.text),
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
