import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/settings_pages/settings_utils.dart';
import 'package:pasada_admin_application/services/auth_service.dart';
import 'package:pasada_admin_application/services/notification_service.dart';

class NotificationsContent extends StatefulWidget {
  final bool isDark;
  
  const NotificationsContent({super.key, required this.isDark});

  @override
  _NotificationsContentState createState() => _NotificationsContentState();
}

class _NotificationsContentState extends State<NotificationsContent> {
  bool pushNotifications = true;
  bool rideUpdates = true;
  bool quotaNotifications = true;
  bool capacityNotifications = true;
  bool routeChangeNotifications = true;
  bool weatherNotifications = true;
  bool _isLoading = true;
  bool _permissionsGranted = false;
  bool _requestingPermissions = false;
  Map<String, dynamic> _permissionStatus = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final authService = AuthService();
      await authService.loadSession();
      
      // Load notification service preferences
      final notificationPrefs = NotificationService.getNotificationPreferences();
      
      // Check detailed permission status
      final permissionStatus = await NotificationService.getDetailedPermissionStatus();
      
      if (mounted) {
        setState(() {
          pushNotifications = authService.pushNotifications;
          rideUpdates = authService.rideUpdates;
          quotaNotifications = notificationPrefs['quotaNotifications'] ?? true;
          capacityNotifications = notificationPrefs['capacityNotifications'] ?? true;
          routeChangeNotifications = notificationPrefs['routeChangeNotifications'] ?? true;
          weatherNotifications = notificationPrefs['weatherNotifications'] ?? true;
          _permissionsGranted = permissionStatus['status'] == AuthorizationStatus.authorized;
          _permissionStatus = permissionStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshPermissionStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Force refresh the permission status
      final updatedStatus = await NotificationService.refreshPermissionStatus();
      
      if (mounted) {
        setState(() {
          _permissionsGranted = updatedStatus['status'] == AuthorizationStatus.authorized;
          _permissionStatus = updatedStatus;
          _isLoading = false;
        });
        
        if (updatedStatus['status'] == AuthorizationStatus.authorized) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Notifications are now enabled!"),
              backgroundColor: Palette.greenColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error refreshing status: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _requestingPermissions = true;
    });

    try {
      final granted = await NotificationService.requestPermissions();
      
      if (mounted) {
        // Refresh permission status
        final updatedStatus = await NotificationService.getDetailedPermissionStatus();
        
        setState(() {
          _permissionsGranted = granted;
          _requestingPermissions = false;
          _permissionStatus = updatedStatus;
        });
        
        if (granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Notification permissions granted!"),
              backgroundColor: Palette.greenColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Notification permissions denied. You can enable them in your browser settings."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _requestingPermissions = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error requesting permissions: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Palette.greenColor,
        ),
      );
    }
    return Column(
      children: [
        // Permission Status and Request Button
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark ? Palette.darkSurface : Palette.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark ? Palette.darkBorder : Palette.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _permissionsGranted ? Icons.notifications_active : Icons.notifications_off,
                    color: _permissionsGranted ? Palette.greenColor : Colors.orange,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Notification Permissions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? Palette.darkText : Palette.lightText,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _refreshPermissionStatus,
                    icon: Icon(
                      Icons.refresh,
                      color: widget.isDark ? Palette.darkText : Palette.lightText,
                    ),
                    tooltip: "Refresh permission status",
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                _permissionStatus['description'] ?? 
                (_permissionsGranted 
                  ? "Notifications are enabled. You'll receive alerts for quota, capacity, route changes, and weather updates."
                  : "Enable notifications to receive real-time alerts about driver quotas, vehicle capacity, route changes, and weather conditions."),
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 16),
              if (_permissionStatus['canRequest'] == true)
                ElevatedButton(
                  onPressed: _requestingPermissions ? null : _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.greenColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 0,
                  ),
                  child: _requestingPermissions
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text("Requesting..."),
                        ],
                      )
                    : Text("Enable Notifications"),
                )
              else if (_permissionStatus['status'] == AuthorizationStatus.denied)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange, size: 16),
                          SizedBox(width: 8),
                          Text(
                            "Notifications Blocked",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "To enable notifications:",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4),
                      Text("1. Click the lock icon in your browser's address bar", style: TextStyle(fontSize: 11)),
                      Text("2. Set 'Notifications' to 'Allow'", style: TextStyle(fontSize: 11)),
                      Text("3. Refresh this page", style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Notification Categories
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark ? Palette.darkSurface : Palette.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark ? Palette.darkBorder : Palette.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Notification Channels",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Palette.darkText : Palette.lightText,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 16),
              
              SwitchTile(
                title: "Push Notifications",
                subtitle: "Receive push notifications on device",
                value: pushNotifications,
                onChanged: (value) => setState(() => pushNotifications = value),
                isDark: widget.isDark,
              ),
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Notification Types
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark ? Palette.darkSurface : Palette.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark ? Palette.darkBorder : Palette.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Notification Types",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Palette.darkText : Palette.lightText,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 16),
              
              SwitchTile(
                title: "Ride Updates",
                subtitle: "Real-time updates about rides and bookings",
                value: rideUpdates,
                onChanged: (value) => setState(() => rideUpdates = value),
                isDark: widget.isDark,
              ),
              
              SizedBox(height: 12),
              
              SwitchTile(
                title: "Quota Notifications",
                subtitle: "Alert when drivers meet their quota targets",
                value: quotaNotifications,
                onChanged: (value) => setState(() => quotaNotifications = value),
                isDark: widget.isDark,
              ),
              
              SizedBox(height: 12),
              
              SwitchTile(
                title: "Capacity Alerts",
                subtitle: "Warn when vehicles are overcrowded",
                value: capacityNotifications,
                onChanged: (value) => setState(() => capacityNotifications = value),
                isDark: widget.isDark,
              ),
              
              SizedBox(height: 12),
              
              SwitchTile(
                title: "Route Changes",
                subtitle: "Notify when drivers change their routes",
                value: routeChangeNotifications,
                onChanged: (value) => setState(() => routeChangeNotifications = value),
                isDark: widget.isDark,
              ),
              
              SizedBox(height: 12),
              
              SwitchTile(
                title: "Weather Alerts",
                subtitle: "Heavy rain and weather warnings",
                value: weatherNotifications,
                onChanged: (value) => setState(() => weatherNotifications = value),
                isDark: widget.isDark,
              ),
            ],
          ),
        ),
        
        SizedBox(height: 24),
        
        // Save Button
        ElevatedButton(
          onPressed: () async {
            // Save notification preferences
            try {
              // Save to AuthService
              await AuthService().setNotificationSettings(
                pushNotifications: pushNotifications,
                rideUpdates: rideUpdates,
              );
              
              // Save to NotificationService
              await NotificationService.updateNotificationPreferences(
                quotaNotifications: quotaNotifications,
                capacityNotifications: capacityNotifications,
                routeChangeNotifications: routeChangeNotifications,
                weatherNotifications: weatherNotifications,
              );
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Notification preferences saved!"),
                    backgroundColor: Palette.greenColor,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Failed to save preferences: ${e.toString()}"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Palette.greenColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            elevation: 0,
          ),
          child: Text("Save Preferences"),
        ),
      ],
    );
  }
}
