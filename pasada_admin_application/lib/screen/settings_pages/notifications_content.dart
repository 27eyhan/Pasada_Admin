import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/settings_pages/settings_utils.dart';

class NotificationsContent extends StatefulWidget {
  final bool isDark;
  
  const NotificationsContent({Key? key, required this.isDark}) : super(key: key);

  @override
  _NotificationsContentState createState() => _NotificationsContentState();
}

class _NotificationsContentState extends State<NotificationsContent> {
  bool emailNotifications = true;
  bool pushNotifications = true;
  bool smsNotifications = false;
  bool rideUpdates = true;
  bool systemUpdates = false;
  bool marketingNotifications = false;

  @override
  Widget build(BuildContext context) {
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
                title: "Email Notifications",
                subtitle: "Receive notifications via email",
                value: emailNotifications,
                onChanged: (value) => setState(() => emailNotifications = value),
                isDark: widget.isDark,
              ),
              
              SwitchTile(
                title: "Push Notifications",
                subtitle: "Receive push notifications on device",
                value: pushNotifications,
                onChanged: (value) => setState(() => pushNotifications = value),
                isDark: widget.isDark,
              ),
              
              SwitchTile(
                title: "SMS Notifications",
                subtitle: "Receive notifications via SMS",
                value: smsNotifications,
                onChanged: (value) => setState(() => smsNotifications = value),
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
              
              SwitchTile(
                title: "System Updates",
                subtitle: "Important system maintenance notifications",
                value: systemUpdates,
                onChanged: (value) => setState(() => systemUpdates = value),
                isDark: widget.isDark,
              ),
              
              SwitchTile(
                title: "Marketing",
                subtitle: "Promotional and marketing communications",
                value: marketingNotifications,
                onChanged: (value) => setState(() => marketingNotifications = value),
                isDark: widget.isDark,
              ),
            ],
          ),
        ),
        
        SizedBox(height: 24),
        
        // Save Button
        ElevatedButton(
          onPressed: () {
            // Save notification preferences
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Notification preferences saved!"),
                backgroundColor: Palette.greenColor,
              ),
            );
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
