import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/models/chat_message.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRefresh;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onRefresh,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
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
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: Palette.blackColor,
              child: Icon(Icons.smart_toy, color: Palette.whiteColor, size: 16),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(
                    maxWidth: screenWidth * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser ? Palette.greyColor : Palette.greyColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Palette.blackColor : Palette.blackColor,
                    ),
                  ),
                ),

                // Action buttons for AI messages
                if (!message.isUser) ...[
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
          if (message.isUser) ...[
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
