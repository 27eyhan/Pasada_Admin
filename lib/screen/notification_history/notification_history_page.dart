import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/models/notification_history.dart';
import 'package:pasada_admin_application/services/notification_history_service.dart';
import 'package:pasada_admin_application/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class NotificationHistoryPage extends StatefulWidget {
  final VoidCallback? onNotificationRead;

  const NotificationHistoryPage({
    super.key,
    this.onNotificationRead,
  });

  @override
  State<NotificationHistoryPage> createState() => _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  List<NotificationHistoryItem> _notifications = [];
  bool _isLoading = true;
  String _searchQuery = '';
  NotificationType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await NotificationHistoryService.initialize();
      final notifications = NotificationHistoryService.getAllNotifications();
      
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<NotificationHistoryItem> get _filteredNotifications {
    List<NotificationHistoryItem> filtered = _notifications;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = NotificationHistoryService.searchNotifications(_searchQuery);
    }

    // Apply type filter
    if (_selectedFilter != null) {
      filtered = filtered.where((n) => n.type == _selectedFilter).toList();
    }

    return filtered;
  }

  Future<void> _markAsRead(NotificationHistoryItem notification) async {
    await NotificationHistoryService.markAsRead(notification.id);
    await _loadNotifications();
    widget.onNotificationRead?.call();
  }

  Future<void> _markAllAsRead() async {
    await NotificationHistoryService.markAllAsRead();
    await _loadNotifications();
    widget.onNotificationRead?.call();
  }

  Future<void> _deleteNotification(NotificationHistoryItem notification) async {
    await NotificationHistoryService.deleteNotification(notification.id);
    await _loadNotifications();
  }

  Future<void> _clearAllNotifications() async {
    await NotificationHistoryService.clearAllNotifications();
    await _loadNotifications();
    widget.onNotificationRead?.call();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      height: isMobile ? MediaQuery.of(context).size.height * 0.8 : null,
      decoration: BoxDecoration(
        color: isDark ? Palette.darkSurface : Palette.lightSurface,
        borderRadius: isMobile 
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Palette.darkBorder : Palette.lightBorder,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Palette.darkBorder : Palette.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: Palette.greenColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Palette.darkText : Palette.lightText,
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                if (_notifications.isNotEmpty) ...[
                  IconButton(
                    onPressed: _markAllAsRead,
                    icon: Icon(
                      Icons.mark_email_read,
                      color: isDark ? Palette.darkText : Palette.lightText,
                    ),
                    tooltip: 'Mark all as read',
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Clear All Notifications'),
                          content: Text('Are you sure you want to clear all notifications?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _clearAllNotifications();
                              },
                              child: Text('Clear All'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.clear_all,
                      color: Colors.red,
                    ),
                    tooltip: 'Clear all',
                  ),
                ],
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    isMobile ? Icons.close : Icons.close,
                    color: isDark ? Palette.darkText : Palette.lightText,
                  ),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          
          // Search and Filter
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search notifications...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isDark ? Palette.darkCard : Palette.lightCard,
                  ),
                ),
                const SizedBox(height: 12),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text('All'),
                        selected: _selectedFilter == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...NotificationType.values.map((type) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_getTypeDisplayName(type)),
                            selected: _selectedFilter == type,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = selected ? type : null;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Notifications list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Palette.greenColor))
                : _filteredNotifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications',
                              style: TextStyle(
                                fontSize: 18,
                                color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredNotifications.length,
                        itemBuilder: (context, index) {
                          final notification = _filteredNotifications[index];
                          return _buildNotificationItem(notification, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationHistoryItem notification, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isRead 
            ? (isDark ? Palette.darkCard : Palette.lightCard)
            : (isDark ? Palette.darkCard.withValues(alpha: 0.8) : Palette.lightCard.withValues(alpha: 0.8)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: notification.isRead 
              ? (isDark ? Palette.darkBorder : Palette.lightBorder)
              : Palette.greenColor.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(notification.type).withValues(alpha: 0.1),
          child: Icon(
            _getTypeIcon(notification.type),
            color: _getTypeColor(notification.type),
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
            color: isDark ? Palette.darkText : Palette.lightText,
            fontFamily: 'Inter',
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              style: TextStyle(
                color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                fontFamily: 'Inter',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy • HH:mm').format(notification.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'read',
              child: Row(
                children: [
                  Icon(Icons.mark_email_read, size: 16),
                  const SizedBox(width: 8),
                  Text(notification.isRead ? 'Mark as unread' : 'Mark as read'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'read') {
              _markAsRead(notification);
            } else if (value == 'delete') {
              _deleteNotification(notification);
            }
          },
        ),
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification);
          }
        },
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
}
