import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/widgets/responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/services/gemini_ai_service.dart';
import 'package:pasada_admin_application/services/chat_session_manager.dart';
import 'package:pasada_admin_application/services/chat_message_controller.dart';
import 'package:pasada_admin_application/widgets/chat_message_widget.dart';
import 'package:pasada_admin_application/models/chat_message.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class AiChatContent extends StatefulWidget {
  final Function(String, {Map<String, dynamic>? args})? onNavigateToPage;

  const AiChatContent({super.key, this.onNavigateToPage});

  @override
  _AiChatContentState createState() => _AiChatContentState();
}

class _AiChatContentState extends State<AiChatContent> {
  // UI Controllers
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // UI State
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isHistoryOpen = false;
  List<Map<String, dynamic>> _savedChats = [];
  Timer? _loadChatDebounce;
  // Route dropdown state
  bool _loadingRoutes = false;
  List<Map<String, dynamic>> _routes = [];
  String? _selectedRouteId;

  // Services
  late GeminiAIService _aiService;
  late ChatSessionManager _sessionManager;
  late ChatMessageController _messageController;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadInitialData();
    _loadRoutes();
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

  // Load routes for /routetraffic command
  Future<void> _loadRoutes() async {
    try {
      setState(() {
        _loadingRoutes = true;
      });
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('official_routes')
          .select('officialroute_id, route_name')
          .order('officialroute_id');

      final List<Map<String, dynamic>> routes =
          (response as List).cast<Map<String, dynamic>>();

      setState(() {
        _routes = routes;
        _selectedRouteId = routes.isNotEmpty ? routes.first['officialroute_id']?.toString() : null;
        _loadingRoutes = false;
      });
    } catch (_) {
      setState(() {
        _loadingRoutes = false;
      });
    }
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

  void _startNewChat() {
    setState(() {
      _messages.clear();
      _isTyping = false;
    });
    // Re-introduce welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: "Hello! I'm Manong, your AI assistant for Pasada. How can I help you today?",
          isUser: false,
        ));
      });
      _scrollToBottom();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Started a new chat'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
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

  void _debouncedLoadChat(String chatId) {
    _loadChatDebounce?.cancel();
    _loadChatDebounce = Timer(const Duration(milliseconds: 250), () {
      _loadChatSession(chatId);
    });
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

    return Container(
      color: isDark ? Palette.darkSurface : Palette.lightSurface,
      child: ResponsiveLayout(
        minWidth: 900,
        child: ResponsivePadding(
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
                      duration: Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                      width: _isHistoryOpen ? 260 : 0,
                      child: _isHistoryOpen
                          ? AnimatedSlide(
                              duration: Duration(milliseconds: 260),
                              curve: Curves.easeOut,
                              offset: _isHistoryOpen ? Offset(0, 0) : Offset(-0.05, 0),
                              child: AnimatedOpacity(
                                duration: Duration(milliseconds: 220),
                                opacity: _isHistoryOpen ? 1.0 : 0.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? Palette.darkCard : Palette.lightCard,
                                    border: Border(
                                      right: BorderSide(
                                        color: isDark
                                            ? Palette.darkBorder
                                            : Palette.lightBorder,
                                        width: 1,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.black.withValues(alpha: 0.08)
                                            : Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 10,
                                        offset: Offset(1, 0),
                                      ),
                                    ],
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
                                          padding: EdgeInsets.only(top: 8),
                                          itemCount: _savedChats.length,
                                          itemBuilder: (context, index) {
                                            final chat = _savedChats[index];
                                            return TweenAnimationBuilder<double>(
                                              tween: Tween(begin: 0.0, end: 1.0),
                                              duration: Duration(milliseconds: 160 + (index % 6) * 16),
                                              curve: Curves.easeOut,
                                              builder: (context, value, child) {
                                                return Opacity(
                                                  opacity: value,
                                                  child: child,
                                                );
                                              },
                                              child: ListTile(
                                                dense: true,
                                                visualDensity: VisualDensity.compact,
                                                title: Text(
                                                  (chat['title'] ?? 'Untitled Chat').toString(),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  softWrap: false,
                                                ),
                                                subtitle: Text(
                                                  _formatCreatedAt(chat['created_at']),
                                                  style: TextStyle(fontSize: 12),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  softWrap: false,
                                                ),
                                                trailing: IconButton(
                                                  icon: Icon(Icons.delete_outline),
                                                  onPressed: () => _deleteChatSession(chat['history_id'].toString()),
                                                ),
                                                onTap: () => _debouncedLoadChat(chat['history_id'].toString()),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                                // Route traffic command dropdown
                                if (_routes.isNotEmpty || _loadingRoutes)
                                  Container(
                                    constraints: BoxConstraints(maxWidth: 220),
                                    margin: EdgeInsets.only(right: 6),
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? Palette.darkCard : Palette.lightCard,
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(
                                        color: isDark ? Palette.darkBorder : Palette.lightBorder,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedRouteId,
                                        hint: Text(
                                          '/routetraffic',
                                          style: TextStyle(
                                            fontSize: 13.0,
                                            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        isDense: true,
                                        isExpanded: false,
                                        icon: Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 18.0,
                                          color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                                        ),
                                        dropdownColor: isDark ? Palette.darkCard : Palette.lightCard,
                                        itemHeight: 40.0,
                                        menuMaxHeight: 320.0,
                                        selectedItemBuilder: (context) {
                                          return _routes.map((r) {
                                            final String id = r['officialroute_id']?.toString() ?? '';
                                            final String name = r['route_name']?.toString() ?? 'Route $id';
                                            return Align(
                                              alignment: Alignment.centerLeft,
                                              child: SizedBox(
                                                width: 160,
                                                child: Text(
                                                  name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 13.0,
                                                    color: isDark ? Palette.darkText : Palette.lightText,
                                                    fontFamily: 'Inter',
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList();
                                        },
                                        items: _routes.map((r) {
                                          final String id = r['officialroute_id']?.toString() ?? '';
                                          final String name = r['route_name']?.toString() ?? 'Route $id';
                                          return DropdownMenuItem<String>(
                                            value: id,
                                            child: SizedBox(
                                              width: 180,
                                              child: Text(
                                                '$name (ID: $id)',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13.0,
                                                  color: isDark ? Palette.darkText : Palette.lightText,
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val == null || val.isEmpty) return;
                                          setState(() {
                                            _selectedRouteId = val;
                                          });
                                          // Auto send the command to chat
                                          _handleSubmitted('/routetraffic $val');
                                        },
                                      ),
                                    ),
                                  ),
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
                                  icon: Icon(Icons.chat_bubble_outline),
                                  onPressed: _startNewChat,
                                  tooltip: 'New Chat',
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

String _formatCreatedAt(dynamic raw) {
  try {
    if (raw is String) {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        return '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      }
      return raw;
    }
    return raw?.toString() ?? '';
  } catch (_) {
    return raw?.toString() ?? '';
  }
}
