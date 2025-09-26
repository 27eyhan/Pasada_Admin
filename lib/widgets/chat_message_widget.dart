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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Bubble styling per role
    final Color userBg = isDark ? Palette.darkDivider : Palette.lightDivider;
    final Color aiBg = isDark ? Palette.darkCard : Colors.white;
    final Color userText = isDark ? Palette.darkText : Palette.lightText;
    final Color aiText = isDark ? Palette.darkText : Palette.lightText;
    final BorderRadius userRadius = BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(6),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(16),
    );
    final BorderRadius aiRadius = BorderRadius.only(
      topLeft: Radius.circular(6),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(16),
    );

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  constraints: BoxConstraints(
                    maxWidth: screenWidth * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser ? userBg : aiBg,
                    borderRadius: message.isUser ? userRadius : aiRadius,
                    border: Border.all(
                      color: isDark ? Palette.darkBorder : Palette.lightBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.06)
                            : Colors.grey.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? userText : aiText,
                      height: 1.35,
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
