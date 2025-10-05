import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/models/notification_history.dart';
import 'package:pasada_admin_application/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

Future<void> showNotificationDetailsDialog(
  BuildContext context,
  NotificationHistoryItem notification,
) async {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  final isDark = themeProvider.isDarkMode;
  final media = MediaQuery.of(context);
  final isMobile = media.size.width < 600;

  await showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : media.size.width * 0.2,
          vertical: isMobile ? 24 : 48,
        ),
        backgroundColor: isDark ? Palette.darkCard : Palette.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 720,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: isDark ? Palette.darkBorder : Palette.lightBorder),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _getTypeColor(notification.type).withValues(alpha: 0.1),
                      child: Icon(
                        _getTypeIcon(notification.type),
                        color: _getTypeColor(notification.type),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        notification.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: isDark ? Palette.darkText : Palette.lightText,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status and type chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(_getTypeDisplayName(notification.type)),
                            avatar: Icon(_getTypeIcon(notification.type), size: 16),
                          ),
                          Chip(
                            label: Text(notification.status.name),
                          ),
                          Chip(
                            label: Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(notification.timestamp)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Body
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: isDark ? Palette.darkText : Palette.lightText,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // IDs
                      if ((notification.driverId ?? '').isNotEmpty || (notification.routeId ?? '').isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((notification.driverId ?? '').isNotEmpty)
                              _DetailRow(label: 'Driver ID', value: notification.driverId!, isDark: isDark),
                            if ((notification.routeId ?? '').isNotEmpty)
                              _DetailRow(label: 'Route ID', value: notification.routeId!, isDark: isDark),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                if ((notification.driverId ?? '').isNotEmpty)
                                  ActionChip(
                                    label: Text('Copy Driver ID'),
                                    onPressed: () => _copyToClipboard(context, notification.driverId!),
                                  ),
                                if ((notification.routeId ?? '').isNotEmpty)
                                  ActionChip(
                                    label: Text('Copy Route ID'),
                                    onPressed: () => _copyToClipboard(context, notification.routeId!),
                                  ),
                              ],
                            ),
                          ],
                        ),

                      // Additional data
                      if (notification.data != null && notification.data!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Additional Data',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            color: isDark ? Palette.darkText : Palette.lightText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Palette.darkSurface : Palette.lightSurface,
                            border: Border.all(color: isDark ? Palette.darkBorder : Palette.lightBorder),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: notification.data!.entries.map((e) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        e.key,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SelectableText(
                                        _stringify(e.value),
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: isDark ? Palette.darkText : Palette.lightText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _copyToClipboard(context, notification.data.toString()),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy Additional Data'),
                          ),
                        )
                      ],
                    ],
                  ),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(12),
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => _copyToClipboard(context, notification.title),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Title'),
                    ),
                    TextButton.icon(
                      onPressed: () => _copyToClipboard(context, notification.body),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Body'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Palette.greenColor),
                        foregroundColor: const WidgetStatePropertyAll(Colors.white),
                      ),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _copyToClipboard(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final Color bg = isDark ? Colors.green.withValues(alpha: 0.2) : Colors.green.shade100;
  final Color fg = isDark ? Colors.green.shade200 : Colors.green.shade900;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Copied to clipboard', style: TextStyle(color: fg)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(12),
    ),
  );
}

String _getTypeDisplayName(NotificationType type) {
  switch (type) {
    case NotificationType.quotaReached:
      return 'Quota';
    case NotificationType.capacityOvercrowded:
      return 'Capacity';
    case NotificationType.routeChanged:
      return 'Route';
    case NotificationType.heavyRainAlert:
      return 'Weather';
    case NotificationType.systemAlert:
      return 'System';
  }
}

IconData _getTypeIcon(NotificationType type) {
  switch (type) {
    case NotificationType.quotaReached:
      return Icons.emoji_events;
    case NotificationType.capacityOvercrowded:
      return Icons.warning;
    case NotificationType.routeChanged:
      return Icons.route;
    case NotificationType.heavyRainAlert:
      return Icons.cloud;
    case NotificationType.systemAlert:
      return Icons.info;
  }
}

Color _getTypeColor(NotificationType type) {
  switch (type) {
    case NotificationType.quotaReached:
      return Colors.green;
    case NotificationType.capacityOvercrowded:
      return Colors.orange;
    case NotificationType.routeChanged:
      return Colors.blue;
    case NotificationType.heavyRainAlert:
      return Colors.purple;
    case NotificationType.systemAlert:
      return Colors.grey;
  }
}

String _stringify(dynamic value) {
  try {
    if (value == null) return 'null';
    if (value is String) return value;
    return value.toString();
  } catch (_) {
    return '';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                color: isDark ? Palette.darkText : Palette.lightText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


