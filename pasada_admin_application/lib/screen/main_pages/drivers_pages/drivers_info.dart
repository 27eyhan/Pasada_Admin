import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'dart:math';

class DriverInfo extends StatefulWidget {
  final Map<String, dynamic> driver;
  const DriverInfo({Key? key, required this.driver}) : super(key: key);

  @override
  _DriverInfoState createState() => _DriverInfoState();
}

class _DriverInfoState extends State<DriverInfo> {
  late Map<DateTime, int> _heatMapData = {};
  late DateTime _currentMonth = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _generateHeatMapData();
  }
  
  void _generateHeatMapData() {
    // Clear existing data
    _heatMapData = {};
    
    // Get the start and end dates for the current month
    final DateTime firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final int daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final DateTime lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, daysInMonth);
    
    // Initialize all days to 0 (inactive) first
    for (int i = 0; i < daysInMonth; i++) {
      final DateTime date = DateTime(firstDayOfMonth.year, firstDayOfMonth.month, i + 1);
      _heatMapData[date] = 0;
    }
    
    // Fetch driver activity logs for the current month
    fetchDriverActivityLogs(firstDayOfMonth, lastDayOfMonth).then((activityLogs) {
      if (activityLogs.isNotEmpty) {
        // Process activity logs
        for (var log in activityLogs) {
          final DateTime loginDate = DateTime.parse(log['login_timestamp']).toLocal();
          final DateTime logDate = DateTime(loginDate.year, loginDate.month, loginDate.day);
          
          // Set the activity level based on session duration
          if (log['session_duration'] != null) {
            int sessionDuration = log['session_duration'];
            int activityLevel = 1; // Default to level 1 (active)
            
            // Assign activity levels based on session duration
            if (sessionDuration > 4 * 60 * 60) { // > 4 hours
              activityLevel = 4; // High activity
            } else if (sessionDuration > 2 * 60 * 60) { // > 2 hours
              activityLevel = 3; // Medium-high activity
            } else if (sessionDuration > 1 * 60 * 60) { // > 1 hour
              activityLevel = 2; // Medium activity
            }
            
            _heatMapData[logDate] = activityLevel;
          } else {
            // If no session duration, just mark as active
            _heatMapData[logDate] = 1;
          }
        }
        setState(() {});
      } else {
        // Fallback to last_online if no activity logs
        if (widget.driver['last_online'] != null) {
          try {
            final DateTime lastOnline = DateTime.parse(widget.driver['last_online'].toString());
            if (lastOnline.month == _currentMonth.month && lastOnline.year == _currentMonth.year) {
              _heatMapData[DateTime(lastOnline.year, lastOnline.month, lastOnline.day)] = 1;
            }
          } catch (e) {
            // Error parsing date, continue
          }
        }
        setState(() {});
      }
    }).catchError((error) {
      print('Error fetching driver activity logs: $error');
      // Fallback to last_online in case of error
      if (widget.driver['last_online'] != null) {
        try {
          final DateTime lastOnline = DateTime.parse(widget.driver['last_online'].toString());
          if (lastOnline.month == _currentMonth.month && lastOnline.year == _currentMonth.year) {
            _heatMapData[DateTime(lastOnline.year, lastOnline.month, lastOnline.day)] = 4;
          }
        } catch (e) {
          // Error parsing date, continue
        }
      }
      setState(() {});
    });
  }
  
  // Fetch driver activity logs from the database
  Future<List<Map<String, dynamic>>> fetchDriverActivityLogs(DateTime startDate, DateTime endDate) async {
    // TODO: Replace with actual database query
    // Example using a database client (adjust based on your actual database implementation):
    // final db = await DatabaseHelper.instance.database;
    // final List<Map<String, dynamic>> logs = await db.rawQuery('''
    //   SELECT log_id, driver_id, login_timestamp, logout_timestamp, session_duration, status
    //   FROM driverActivityLog 
    //   WHERE driver_id = ? AND login_timestamp BETWEEN ? AND ?
    //   ORDER BY login_timestamp
    // ''', [widget.driver['driver_id'], startDate.toIso8601String(), endDate.toIso8601String()]);
    // return logs;
    
    // For now, return an empty list as placeholder
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width * 0.65;
    final double sideLength = screenWidth * 0.6;
    final driver = widget.driver;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      backgroundColor: Palette.whiteColor,
      child: Container(
        width: sideLength,
        height: sideLength,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Driver Information",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Palette.blackColor,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(
                    Icons.close,
                    size: 24,
                    color: Palette.blackColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Divider(color: Palette.blackColor.withValues(alpha: 128)),
            const SizedBox(height: 16.0),
            // Display driver details (excluding driver_password and created_at).
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Driver ID: ${driver['driver_id']?.toString() ?? 'N/A'}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Palette.blackColor,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      "Name: ${driver['first_name'] ?? ''} ${driver['last_name'] ?? ''}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Palette.blackColor,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      "Driver Number: ${driver['driver_number'] ?? 'N/A'}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Palette.blackColor,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      "Vehicle ID: ${driver['vehicle_id']?.toString() ?? 'N/A'}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Palette.blackColor,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      "Status: ${driver['driving_status'] ?? 'N/A'}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Palette.blackColor,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      "Last Online: ${_formatLastOnline(driver['last_online'])}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Palette.blackColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2.0),
            // Add monthly activity heatmap calendar
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.35,
                    height: MediaQuery.of(context).size.height * 0.38,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Palette.greyColor.withValues(alpha: 51)),
                      boxShadow: [
                        BoxShadow(
                          color: Palette.greyColor.withValues(alpha: 26),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Month header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Driver Activity",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Palette.blackColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Calendar with default navigation
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: HeatMapCalendar(
                              datasets: _heatMapData,
                              colorMode: ColorMode.color,
                              defaultColor: Palette.greyColor,
                              textColor: Palette.blackColor,
                              colorsets: {
                                1: Palette.greenColor.withAlpha(100),
                                2: Palette.greenColor.withAlpha(150),
                                3: Palette.greenColor.withAlpha(200),
                                4: Palette.greenColor,
                              },
                              onClick: (date) {
                                setState(() {
                                });
                              },
                              monthFontSize: 14,
                              weekFontSize: 10,
                              initDate: DateTime(_currentMonth.year, _currentMonth.month),
                              onMonthChange: (date) {
                                setState(() {
                                  _currentMonth = date;
                                  _generateHeatMapData();
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  // Add a legend to explain the colors
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Palette.greyColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Inactive",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Palette.blackColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Palette.greenColor.withAlpha(100),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Less than 1 hour",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Palette.blackColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Palette.greenColor.withAlpha(150),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "1 - 2 hours",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Palette.blackColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Palette.greenColor.withAlpha(200),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "2 - 4 hours",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Palette.blackColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Palette.greenColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "4 hours or more",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Palette.blackColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Buttons row - centered with two buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Contact Driver button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.whiteColor,
                    foregroundColor: Palette.blackColor,
                    elevation: 6.0,
                    shadowColor: Colors.grey,
                    side: BorderSide(color: Colors.grey, width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                  onPressed: () {
                    // Add action to contact the driver here.
                  },
                  child: Text(
                    "Contact Driver",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: Palette.blackColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.whiteColor,
                    foregroundColor: Palette.blackColor,
                    elevation: 6.0,
                    shadowColor: Colors.grey,
                    side: BorderSide(color: Colors.grey, width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                  onPressed: () {
                    // Add action to manage the driver here.
                  },
                  child: Text(
                    "Manage Driver",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: Palette.blackColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Method that adjusts the last online timestamp to a more readable format. 
  String _formatLastOnline(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final DateTime dateTime = DateTime.parse(timestamp.toString());
      String month = dateTime.month.toString().padLeft(2, '0');
      String day = dateTime.day.toString().padLeft(2, '0');
      String year = (dateTime.year % 100).toString().padLeft(2, '0');
      return '$month/$day/$year';
    } catch (e) {
      return 'Invalid Date';
    }
  }
  
  // Method to get month name from month number
}
