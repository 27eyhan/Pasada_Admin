import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:pasada_admin_application/services/database_summary_service.dart';

class AiChat extends StatefulWidget {
  @override
  _AiChatState createState() => _AiChatState();
}

class _AiChatState extends State<AiChat> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  late Gemini gemini;
  
  // Database summary service
  final DatabaseSummaryService _databaseService = DatabaseSummaryService();
  
  // Chat history for tracking the conversation
  final List<Content> _chatHistory = [];
  
  // System instruction to guide AI responses
  String systemInstruction = """You are Manong, a helpful AI assistant for Pasada, a modern jeepney transportation system in the Philippines. Our team is composed of Calvin John Crehencia, Adrian De Guzman, Ethan Andrei Humarang and Fyke Simon Tonel, we are called CAFE Tech. Don't use emoji.

You are focused in Fleet Management System, Modern Jeepney Transportation System in the Philippines, Ride-Hailing, and Traffic Advisory in the Malinta to Novaliches route in the Philippines. You're implemented in the admin website of Pasada: An AI-Powered Ride-Hailing and Fleet Management Platform for Modernized Jeepneys Services with Mobile Integration and RealTime Analytics.

You're role is to be an advisor, providing suggestions based on the data inside the website. Limit your answer in 3 sentences and summarize if necessary. Don't answer other topics, only those mentioned above.""";

  @override
  void initState() {
    super.initState();
    // Initialize Gemini with the API key
    final apiKey = dotenv.env['GEMINI_API'] ?? '';
    
    if (apiKey.isEmpty) {
      print('Warning: GEMINI_API key is not set in .env file');
      // Still add the welcome message but inform about missing API key
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _messages.add(ChatMessage(
            text: "Hello! I'm Manong, your AI assistant. However, I need an API key to function properly. Please configure the GEMINI_API in your .env file.",
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
        _chatHistory.add(Content(role: 'system', parts: [Part.text(systemInstruction)]));
      }
      
      // Add the welcome message when the widget initializes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _messages.add(ChatMessage(
            text: "Hello! I'm Manong, your AI assistant. How can I help you today?",
            isUser: false,
          ));
        });
      });
    }
  }
  
  // Method to set system instruction
  void setSystemInstruction(String instruction) {
    setState(() {
      systemInstruction = instruction;
      
      // Reset chat history and add system instruction
      _chatHistory.clear();
      if (systemInstruction.isNotEmpty) {
        _chatHistory.add(Content(role: 'system', parts: [Part.text(systemInstruction)]));
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
        final response = await gemini.text("$enhancedInstruction\n\nUser: $message");
        
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

    @override
    Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final padding = mediaQuery.padding;
    
      return Scaffold(
      backgroundColor: Palette.whiteColor,
      appBar: AppBarSearch(),
      drawer: MyDrawer(),
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 212, vertical: 48),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Palette.greyColor, width: 1.5),
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
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: Palette.whiteColor.withValues(alpha: 128),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Palette.blackColor,
                      child: Icon(Icons.smart_toy, color: Colors.white),
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
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        padding: EdgeInsets.symmetric(horizontal: 16),
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
                        onPressed: () => _handleSubmitted(_messageController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
            child: Container(
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