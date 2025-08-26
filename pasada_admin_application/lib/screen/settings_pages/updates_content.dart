import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/settings_pages/settings_utils.dart';

class UpdatesContent extends StatefulWidget {
  final bool isDark;
  
  const UpdatesContent({Key? key, required this.isDark}) : super(key: key);

  @override
  _UpdatesContentState createState() => _UpdatesContentState();
}

class _UpdatesContentState extends State<UpdatesContent> {
  String updateFrequency = 'realtime';
  bool enableAutoRefresh = true;
  int refreshInterval = 30;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Update Frequency
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
                "Update Frequency",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Palette.darkText : Palette.lightText,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 16),
              
              RadioListTile<String>(
                title: Text("Real-time", style: TextStyle(fontFamily: 'Inter')),
                subtitle: Text("Updates as they happen"),
                value: 'realtime',
                groupValue: updateFrequency,
                onChanged: (value) => setState(() => updateFrequency = value!),
                activeColor: Palette.greenColor,
              ),
              
              RadioListTile<String>(
                title: Text("Every 5 minutes", style: TextStyle(fontFamily: 'Inter')),
                subtitle: Text("Updates every 5 minutes"),
                value: '5min',
                groupValue: updateFrequency,
                onChanged: (value) => setState(() => updateFrequency = value!),
                activeColor: Palette.greenColor,
              ),
              
              RadioListTile<String>(
                title: Text("Every 15 minutes", style: TextStyle(fontFamily: 'Inter')),
                subtitle: Text("Updates every 15 minutes"),
                value: '15min',
                groupValue: updateFrequency,
                onChanged: (value) => setState(() => updateFrequency = value!),
                activeColor: Palette.greenColor,
              ),
              
              RadioListTile<String>(
                title: Text("Manual", style: TextStyle(fontFamily: 'Inter')),
                subtitle: Text("Updates only when requested"),
                value: 'manual',
                groupValue: updateFrequency,
                onChanged: (value) => setState(() => updateFrequency = value!),
                activeColor: Palette.greenColor,
              ),
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Auto Refresh Settings
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
              SwitchTile(
                title: "Auto Refresh",
                subtitle: "Automatically refresh data at specified intervals",
                value: enableAutoRefresh,
                onChanged: (value) => setState(() => enableAutoRefresh = value),
                isDark: widget.isDark,
              ),
              
              if (enableAutoRefresh) ...[
                SizedBox(height: 16),
                Text(
                  "Refresh Interval (seconds): $refreshInterval",
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                Slider(
                  value: refreshInterval.toDouble(),
                  min: 10,
                  max: 120,
                  divisions: 11,
                  activeColor: Palette.greenColor,
                  onChanged: (value) => setState(() => refreshInterval = value.round()),
                ),
              ],
            ],
          ),
        ),
        
        SizedBox(height: 24),
        
        // Save Button
        ElevatedButton(
          onPressed: () {
            // Save update preferences
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Update preferences saved!"),
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
