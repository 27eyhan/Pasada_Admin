import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:provider/provider.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/services/gemini_ai_service.dart';
import 'package:pasada_admin_application/services/chat_session_manager.dart';
import 'package:pasada_admin_application/services/chat_message_controller.dart';
import 'package:pasada_admin_application/widgets/chat_message_widget.dart';
import 'package:pasada_admin_application/models/chat_message.dart';

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
  List<Map<String, dynamic>> _savedChats = [];

  // Services
  late GeminiAIService _aiService;
  late ChatSessionManager _sessionManager;
  late ChatMessageController _messageController;
  bool _initialPromptHandled = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Handle initial prompt passed via Navigator arguments once
    if (!_initialPromptHandled) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        final String? initialPrompt = args['initialPrompt'] as String?;
        if (initialPrompt != null && initialPrompt.trim().isNotEmpty) {
          _initialPromptHandled = true;
          // Add and send automatically
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _textController.text = initialPrompt;
            _handleSubmitted(initialPrompt);
          });
        }
      }
    }
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
      getMessages: () => _messages,
    );
  }

  // Load initial data and setup
  Future<void> _loadInitialData() async {
    // Load authentication and chat history (no direct Gemini init required)
    await _sessionManager.loadAuthentication();
    await _sessionManager.loadChatHistory();

    // Load saved chats
    await _loadSavedChats();

    // Add welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Hello! I'm Manong, your AI assistant for Pasada. How can I help you today?",
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
      if (messages != null && messages.isNotEmpty) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
        });
        // Close history drawer after loading
        setState(() {
          _isHistoryOpen = false;
        });
        // Scroll to bottom to show the loaded messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat loaded successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No messages found in this chat'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading chat: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deleteChatSession(String chatId) async {
    try {
      await _sessionManager.deleteChatSession(chatId);
      // Reload chat history after deletion
      await _sessionManager.loadChatHistory();
      setState(() {
        _savedChats = _sessionManager.savedChats;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting chat: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Load saved chats from session manager
  Future<void> _loadSavedChats() async {
    try {
      await _sessionManager.loadChatHistory();
      setState(() {
        _savedChats = _sessionManager.savedChats;
      });
    } catch (e) {
      throw Exception('Error loading saved chats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final padding = mediaQuery.padding;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final double screenWidth = MediaQuery.of(context)
        .size
        .width
        .clamp(600.0, double.infinity)
        .toDouble();
    final double horizontalPadding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: isDark ? Palette.darkSurface : Palette.lightSurface,
      body: Row(
        children: [
          // Fixed width sidebar drawer
          SizedBox(
            width: 280, // Fixed width for the sidebar
            child: MyDrawer(),
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                // App bar in the main content area
                AppBarSearch(),
                // Main content, centered like Settings
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 24.0,
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? Palette.darkCard : Palette.lightCard,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: isDark ? Palette.darkBorder : Palette.lightBorder,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.08)
                                      : Colors.grey.withValues(alpha: 0.08),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Chat History Drawer (inline, minimal border)
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  width: _isHistoryOpen ? 260 : 0,
                                  child: _isHistoryOpen
                                      ? Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(
                                                color: isDark
                                                    ? Palette.darkBorder
                                                    : Palette.lightBorder,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color: isDark
                                                          ? Palette.darkBorder
                                                          : Palette.lightBorder,
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Chat History',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.close),
                                                      onPressed: () => setState(() => _isHistoryOpen = false),
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
                                                        DateTime.parse(chat['created_at']).toString(),
                                                        style: TextStyle(fontSize: 12),
                                                      ),
                                                      trailing: IconButton(
                                                        icon: Icon(Icons.delete_outline),
                                                        onPressed: () => _deleteChatSession(chat['history_id']),
                                                      ),
                                                      onTap: () => _loadChatSession(chat['history_id']),
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
                                      // Minimal top bar with actions
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.history),
                                              onPressed: () {
                                                setState(() => _isHistoryOpen = !_isHistoryOpen);
                                                if (_isHistoryOpen) {
                                                  _loadSavedChats();
                                                }
                                              },
                                              tooltip: 'Chat History',
                                            ),
                                            SizedBox(width: 4),
                                            IconButton(
                                              icon: Icon(Icons.save_outlined),
                                              onPressed: _saveChatSession,
                                              tooltip: 'Save Chat',
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Header
                                      Container(
                                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: Palette.blackColor,
                                              child: Icon(Icons.smart_toy, color: Colors.white),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Manong',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Messages
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                (isDark ? Palette.darkSurface : Palette.lightSurface).withValues(alpha: 0.0),
                                                (isDark ? Palette.darkSurface : Palette.lightSurface).withValues(alpha: 0.06),
                                              ],
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(vertical: 8),
                                          child: ListView.builder(
                                            controller: _scrollController,
                                            physics: BouncingScrollPhysics(),
                                            itemCount: _messages.length,
                                            itemBuilder: (context, index) {
                                              return _AnimatedMessage(
                                                key: ValueKey('msg-$index-${_messages[index].hashCode}'),
                                                child: ChatMessageWidget(
                                                  message: _messages[index],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),

                                      AnimatedSwitcher(
                                        duration: Duration(milliseconds: 200),
                                        switchInCurve: Curves.easeOut,
                                        switchOutCurve: Curves.easeIn,
                                        child: _isTyping
                                            ? Padding(
                                                key: ValueKey('typing'),
                                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      width: 14,
                                                      height: 14,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(Palette.lightPrimary),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Manong is typing...',
                                                      style: TextStyle(
                                                        color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : SizedBox.shrink(key: ValueKey('notyping')),
                                      ),

                                      // Input area
                                      Container(
                                        padding: EdgeInsets.only(
                                          bottom: padding.bottom + 8,
                                          top: 8,
                                          left: 8,
                                          right: 8,
                                        ),
                                        decoration: BoxDecoration(color: Colors.transparent),
                                        child: Row(
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(right: 8),
                                              decoration: BoxDecoration(
                                                color: Palette.blackColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: IconButton(
                                                icon: Icon(Icons.add, color: Colors.white),
                                                onPressed: () {},
                                                padding: EdgeInsets.all(8),
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(
                                                padding: EdgeInsets.symmetric(horizontal: 16),
                                                decoration: BoxDecoration(
                                                  color: isDark ? Palette.darkDivider : Palette.lightDivider,
                                                  borderRadius: BorderRadius.circular(24),
                                                ),
                                                child: TextField(
                                                  controller: _textController,
                                                  decoration: InputDecoration(
                                                    hintText: 'Ask me anything...',
                                                    hintStyle: TextStyle(
                                                      color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                                                      fontFamily: 'Inter',
                                                    ),
                                                    border: InputBorder.none,
                                                  ),
                                                  maxLines: null,
                                                  textInputAction: TextInputAction.send,
                                                  onSubmitted: _handleSubmitted,
                                                  cursorColor: Palette.greenColor,
                                                  style: TextStyle(
                                                    color: isDark ? Palette.darkText : Palette.lightText,
                                                    fontFamily: 'Inter',
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Palette.blackColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: IconButton(
                                                icon: Icon(Icons.send, color: Colors.white),
                                                onPressed: () => _handleSubmitted(_textController.text),
                                              ),
                                            ),
                                          ],
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedMessage extends StatelessWidget {
  final Widget child;
  const _AnimatedMessage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 8),
            child: child,
          ),
        );
      },
    );
  }
}
