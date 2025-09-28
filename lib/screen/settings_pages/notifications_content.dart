import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/settings_pages/settings_utils.dart';
import 'package:pasada_admin_application/services/auth_service.dart';

class NotificationsContent extends StatefulWidget {
  final bool isDark;
  
  const NotificationsContent({super.key, required this.isDark});

  @override
  _NotificationsContentState createState() => _NotificationsContentState();
}

class _NotificationsContentState extends State<NotificationsContent> {
  bool pushNotifications = true;
  bool rideUpdates = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final authService = AuthService();
      await authService.loadSession();
      
      if (mounted) {
        setState(() {
          pushNotifications = authService.pushNotifications;
          rideUpdates = authService.rideUpdates;
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
            ],
          ),
        ),
        
        SizedBox(height: 24),
        
        // Save Button
        ElevatedButton(
          onPressed: () async {
            // Save notification preferences
            try {
              await AuthService().setNotificationSettings(
                pushNotifications: pushNotifications,
                rideUpdates: rideUpdates,
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
