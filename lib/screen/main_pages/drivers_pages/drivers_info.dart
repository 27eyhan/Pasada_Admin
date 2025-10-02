import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:pasada_admin_application/widgets/responsive_dialog.dart';
import 'package:provider/provider.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'drivers_actlogs.dart';

class DriverInfo extends StatefulWidget {
  final Map<String, dynamic> driver;
  final bool initialEditMode;

  const DriverInfo({
    super.key,
    required this.driver,
    this.initialEditMode = false,
  });

  @override
  _DriverInfoState createState() => _DriverInfoState();
}

class _DriverInfoState extends State<DriverInfo> {
  late Map<DateTime, int> _heatMapData = {};
  late DateTime _currentMonth = DateTime.now();
  late bool _isEditMode;
  late DriverActivityLogs _activityLogs;

  // Text editing controllers
  late TextEditingController _fullNameController;
  late TextEditingController _driverNumberController;
  late TextEditingController _vehicleIdController;
  late TextEditingController _driverLicenseController;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.initialEditMode;
    _activityLogs = DriverActivityLogs(
      driverId: int.parse(widget.driver['driver_id'].toString()),
      context: context,
    );
    _generateHeatMapData();
    _initControllers();
  }

  void _initControllers() {
    _fullNameController =
        TextEditingController(text: widget.driver['full_name'] ?? '');
    _driverNumberController =
        TextEditingController(text: widget.driver['driver_number'] ?? '');
    _vehicleIdController = TextEditingController(
        text: widget.driver['vehicle_id']?.toString() ?? '');
    _driverLicenseController = TextEditingController(
        text: widget.driver['driver_license_number'] ?? '');
  }

  @override
  void dispose() {
    // Dispose controllers
    _fullNameController.dispose();
    _driverNumberController.dispose();
    _vehicleIdController.dispose();
    _driverLicenseController.dispose();
    super.dispose();
  }

  // Toggle edit mode
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;

      // If exiting edit mode, attempt to save changes
      if (!_isEditMode) {
        _saveChanges();
      }
    });
  }

  // Save changes to database
  void _saveChanges() async {
    // First check if any data has changed
    if (_fullNameController.text == widget.driver['full_name'] &&
        _driverNumberController.text == widget.driver['driver_number'] &&
        _vehicleIdController.text == widget.driver['vehicle_id']?.toString()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No changes were made'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      if (_vehicleIdController.text.isNotEmpty) {
        final duplicateVehicleId = await _checkForDuplicateData(
          'vehicle_id',
          _vehicleIdController.text,
          widget.driver['driver_id'].toString(),
        );

        if (duplicateVehicleId) {
          // Close loading dialog
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vehicle ID is already assigned to another driver'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Create updated driver data
      final updatedDriver = {
        'full_name': _fullNameController.text,
        'driver_number': _driverNumberController.text,
        'vehicle_id': _vehicleIdController.text,
      };

      // Implement the actual database update
      final supabase = Supabase.instance.client;
      await supabase
          .from('driverTable')
          .update(updatedDriver)
          .eq('driver_id', widget.driver['driver_id']);

      // Explicitly force an activity log to be created with current status
      String? currentStatus = widget.driver['driving_status'];
      if (currentStatus != null) {
        await _activityLogs.logDriverActivity(currentStatus, DateTime.now());
        debugPrint(
            '_saveChanges: Explicitly logged activity for status $currentStatus');
      } else {
        debugPrint('_saveChanges: No status available to log activity');
      }

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Driver information updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Force refresh of heatmap data
      _generateHeatMapData();
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating driver: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Check if data already exists for another driver
  Future<bool> _checkForDuplicateData(
      String field, String value, String currentDriverId) async {
    if (value.isEmpty) return false;

    try {
      // Using Supabase
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('driverTable')
          .select('driver_id')
          .eq(field, value)
          .neq('driver_id', currentDriverId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  void _generateHeatMapData() {
    // Clear existing data
    _heatMapData = {};

    // Get the start and end dates for the current month
    final DateTime firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final int daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final DateTime lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, daysInMonth);

    // Initialize all days to 0 (inactive) first
    for (int i = 0; i < daysInMonth; i++) {
      final DateTime date =
          DateTime(firstDayOfMonth.year, firstDayOfMonth.month, i + 1);
      _heatMapData[date] = 0;
    }

    debugPrint(
        'Fetching driver activity logs for driver ${widget.driver['driver_id']} from $firstDayOfMonth to $lastDayOfMonth');

    // Fetch driver activity logs for the current month
    _activityLogs
        .fetchDriverActivityLogs(firstDayOfMonth, lastDayOfMonth)
        .then((activityLogs) {
      bool hasActivityData = false;

      if (activityLogs.isNotEmpty) {
        debugPrint(
            'Found ${activityLogs.length} activity logs for the current month');
        // Process activity logs
        for (var log in activityLogs) {
          try {
            final DateTime loginDate =
                DateTime.parse(log['login_timestamp']).toLocal();
            final DateTime logDate =
                DateTime(loginDate.year, loginDate.month, loginDate.day);

            // Set the activity level based on session duration
            if (log['session_duration'] != null) {
              int sessionDuration = log['session_duration'];
              int activityLevel = 1; // Default to level 1 (active)

              // Assign activity levels based on session duration
              if (sessionDuration > 4 * 60 * 60) {
                // > 4 hours
                activityLevel = 4; // High activity
              } else if (sessionDuration > 2 * 60 * 60) {
                // > 2 hours
                activityLevel = 3; // Medium-high activity
              } else if (sessionDuration > 1 * 60 * 60) {
                // > 1 hour
                activityLevel = 2; // Medium activity
              }

              _heatMapData[logDate] = activityLevel;
              hasActivityData = true;
              debugPrint(
                  'Added activity level $activityLevel for date $logDate (session duration: ${sessionDuration / 3600} hours)');
            } else {
              // If no session duration, just mark as active
              _heatMapData[logDate] = 1;
              hasActivityData = true;
              debugPrint(
                  'Added activity level 1 for date $logDate (no session duration)');
            }
          } catch (e) {
            debugPrint('Error processing activity log: $e');
            // Continue with other logs instead of failing completely
            continue;
          }
        }
      } else {
        debugPrint('No activity logs found for the current month');
      }

      // Only use last_online as fallback if we couldn't find ANY activity data
      if (!hasActivityData && widget.driver['last_online'] != null) {
        try {
          debugPrint('No activity data found, using last_online as fallback');
          final DateTime lastOnline =
              DateTime.parse(widget.driver['last_online'].toString());
          if (lastOnline.month == _currentMonth.month &&
              lastOnline.year == _currentMonth.year) {
            _heatMapData[DateTime(
                lastOnline.year, lastOnline.month, lastOnline.day)] = 1;
            debugPrint(
                'Added last_online data for ${lastOnline.toString()} with level 1');
          }
        } catch (e) {
          debugPrint('Error parsing last_online date: $e');
        }
      }

      setState(() {});
    }).catchError((error) {
      debugPrint('Error fetching activity logs: $error');

      // Only use last_online if we couldn't fetch activity logs at all
      if (widget.driver['last_online'] != null) {
        try {
          debugPrint('Using last_online as fallback due to error fetching logs');
          final DateTime lastOnline =
              DateTime.parse(widget.driver['last_online'].toString());
          if (lastOnline.month == _currentMonth.month &&
              lastOnline.year == _currentMonth.year) {
            _heatMapData[DateTime(
                    lastOnline.year, lastOnline.month, lastOnline.day)] =
                1; // Changed from 4 to 1 for consistency
            debugPrint(
                'Added last_online data for ${lastOnline.toString()} with level 1');
          }
        } catch (e) {
          debugPrint('Error parsing last_online date: $e');
        }
      }
      setState(() {});
    });
  }

  // Add this explicit method to be called when we want to update driver status
  Future<void> updateDriverStatus(String newStatus) async {
    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now();

      // Update driver status in driver table
      await supabase.from('driverTable').update({
        'driving_status': newStatus,
        'last_online': now.toIso8601String()
      }).eq('driver_id', widget.driver['driver_id']);

      // Log this activity
      await _activityLogs.logDriverActivity(newStatus, now);

      // Refresh UI
      setState(() {});
    } catch (e) {
      debugPrint('Error updating driver status: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating driver status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final driver = widget.driver;

    return ResponsiveDialog(
      title: "Driver Information",
      titleIcon: Icons.person,
      child: ResponsiveDialogContent(
        children: [
          // Driver ID badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark 
                  ? Palette.darkPrimary.withValues(alpha: 0.1)
                  : Palette.lightPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark 
                    ? Palette.darkPrimary.withValues(alpha: 0.3)
                    : Palette.lightPrimary.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: Text(
              "Driver ID: ${driver['driver_id']?.toString() ?? 'N/A'}",
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 16),
                fontWeight: FontWeight.w600,
                color: isDark ? Palette.darkPrimary : Palette.lightPrimary,
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 16)),

          // Main content with responsive layout
          ResponsiveHelper.isMobile(context)
              ? _buildMobileLayout(driver, isDark)
              : _buildDesktopLayout(driver, isDark),
        ],
      ),
    );
  }

  // Mobile layout - stacked cards
  Widget _buildMobileLayout(Map<String, dynamic> driver, bool isDark) {
    return Column(
      children: [
        // Driver Information Card
        _isEditMode 
            ? _buildEditableDriverInfo(isDark)
            : _buildResponsiveDetailCard(
                "Driver Information",
                [
                  _buildCompactDetailRow(
                    "Name",
                    driver['full_name'] ?? 'N/A',
                    Icons.person_outline,
                    isDark,
                  ),
                  _buildCompactDetailRow(
                    "License Number",
                    driver['driver_license_number'] ?? 'N/A',
                    Icons.credit_card_outlined,
                    isDark,
                  ),
                  _buildCompactDetailRow(
                    "Driver Number",
                    driver['driver_number'] ?? 'N/A',
                    Icons.phone_outlined,
                    isDark,
                  ),
                  _buildCompactDetailRow(
                    "Vehicle ID",
                    driver['vehicle_id']?.toString() ?? 'N/A',
                    Icons.directions_car_outlined,
                    isDark,
                  ),
                  _buildCompactDetailRow(
                    "Status",
                    _capitalizeFirstLetter(driver['driving_status'] ?? 'N/A'),
                    Icons.local_taxi_outlined,
                    isDark,
                    statusColor: _getStatusColor(driver['driving_status'] ?? 'offline'),
                  ),
                  _buildCompactDetailRow(
                    "Last Online",
                    _formatLastOnline(driver['last_online']),
                    Icons.access_time_outlined,
                    isDark,
                  ),
                ],
                isDark,
              ),
        
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 16)),
        
        // Driver Activity Card
        _buildResponsiveActivityCard(isDark),
        
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 16)),
        
        // Action buttons
        _buildResponsiveActionButtons(isDark),
      ],
    );
  }

  // Desktop layout - side by side cards
  Widget _buildDesktopLayout(Map<String, dynamic> driver, bool isDark) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT COLUMN - Driver Information
            Expanded(
              child: _isEditMode 
                  ? _buildEditableDriverInfo(isDark)
                  : _buildResponsiveDetailCard(
                      "Driver Information",
                      [
                        _buildCompactDetailRow(
                          "Name",
                          driver['full_name'] ?? 'N/A',
                          Icons.person_outline,
                          isDark,
                        ),
                        _buildCompactDetailRow(
                          "License Number",
                          driver['driver_license_number'] ?? 'N/A',
                          Icons.credit_card_outlined,
                          isDark,
                        ),
                        _buildCompactDetailRow(
                          "Driver Number",
                          driver['driver_number'] ?? 'N/A',
                          Icons.phone_outlined,
                          isDark,
                        ),
                        _buildCompactDetailRow(
                          "Vehicle ID",
                          driver['vehicle_id']?.toString() ?? 'N/A',
                          Icons.directions_car_outlined,
                          isDark,
                        ),
                        _buildCompactDetailRow(
                          "Status",
                          _capitalizeFirstLetter(driver['driving_status'] ?? 'N/A'),
                          Icons.local_taxi_outlined,
                          isDark,
                          statusColor: _getStatusColor(driver['driving_status'] ?? 'offline'),
                        ),
                        _buildCompactDetailRow(
                          "Last Online",
                          _formatLastOnline(driver['last_online']),
                          Icons.access_time_outlined,
                          isDark,
                        ),
                      ],
                      isDark,
                    ),
            ),

            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 12)),

            // RIGHT COLUMN - Driver Activity
            Expanded(
              child: _buildResponsiveActivityCard(isDark),
            ),
          ],
        ),
        
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 16)),
        
        // Action buttons
        _buildResponsiveActionButtons(isDark),
      ],
    );
  }

  // Build responsive detail card
  Widget _buildResponsiveDetailCard(String title, List<Widget> children, bool isDark) {
    return Container(
      height: ResponsiveHelper.isMobile(context) ? 300 : 400,
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context)),
        border: Border.all(
          color: isDark 
              ? Palette.darkBorder.withValues(alpha: 77)
              : Palette.lightBorder.withValues(alpha: 77),
          width: 1.0,
        ),
      ),
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveCardPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 12, tablet: 14, desktop: 14),
              fontWeight: FontWeight.w700,
              color: isDark ? Palette.darkText : Palette.lightText,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 6, tablet: 8, desktop: 8)),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build responsive activity card
  Widget _buildResponsiveActivityCard(bool isDark) {
    return Container(
      height: ResponsiveHelper.isMobile(context) ? 300 : 400,
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context)),
        border: Border.all(
          color: isDark 
              ? Palette.darkBorder.withValues(alpha: 77)
              : Palette.lightBorder.withValues(alpha: 77),
          width: 1.0,
        ),
      ),
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveCardPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Driver Activity",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 12, tablet: 14, desktop: 14),
              fontWeight: FontWeight.w700,
              color: isDark ? Palette.darkText : Palette.lightText,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 6, tablet: 8, desktop: 8)),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: HeatMapCalendar(
                  datasets: _heatMapData,
                  colorMode: ColorMode.color,
                  defaultColor: isDark ? Palette.darkSurface : Palette.lightSurface,
                  textColor: isDark ? Palette.darkText : Palette.lightText,
                  colorsets: {
                    1: Palette.greenColor.withAlpha(100),
                    2: Palette.greenColor.withAlpha(150),
                    3: Palette.greenColor.withAlpha(200),
                    4: Palette.greenColor,
                  },
                  onClick: (date) {
                    setState(() {});
                  },
                  monthFontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 12, tablet: 14, desktop: 14),
                  weekFontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 8, tablet: 10, desktop: 10),
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
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 6, tablet: 8, desktop: 8)),
          // Legend
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildLegendItem(isDark ? Palette.darkSurface : Palette.lightSurface, "Inactive"),
                _buildLegendItem(Palette.greenColor.withAlpha(100), "< 1hr"),
                _buildLegendItem(Palette.greenColor.withAlpha(150), "1-2hrs"),
                _buildLegendItem(Palette.greenColor.withAlpha(200), "2-4hrs"),
                _buildLegendItem(Palette.greenColor, "4+hrs"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build responsive action buttons
  Widget _buildResponsiveActionButtons(bool isDark) {
    return ResponsiveDialogActions(
      children: [
        // Save/Manage Driver button (full-width)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00CC58),
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            side: BorderSide(
              color: const Color(0xFF00CC58),
              width: 1.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context)),
            ),
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 14, desktop: 20),
              horizontal: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 20),
            ),
          ),
          onPressed: _toggleEditMode,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_isEditMode ? Icons.save : Icons.edit, size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 16, tablet: 18, desktop: 18)),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 6, tablet: 8, desktop: 8)),
              Text(
                _isEditMode ? "Save Changes" : "Manage Driver",
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 12, tablet: 14, desktop: 14),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }


  // Build compact individual detail row
  Widget _buildCompactDetailRow(
    String label,
    String value,
    IconData icon,
    bool isDark, {
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: statusColor ?? (isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.0,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: statusColor ?? (isDark ? Palette.darkText : Palette.lightText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // Get status color based on driver status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
      case 'active':
        return Palette.lightSuccess;
      case 'driving':
        return Palette.lightSuccess;
      case 'idling':
        return Palette.lightWarning;
      case 'offline':
        return Palette.lightError;
      default:
        return Palette.greyColor;
    }
  }

  // Helper method to capitalize first letter
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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

  // Build editable driver information card
  Widget _buildEditableDriverInfo(bool isDark) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDark 
              ? Palette.darkBorder.withValues(alpha: 77)
              : Palette.lightBorder.withValues(alpha: 77),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Driver Information",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              color: isDark ? Palette.darkText : Palette.lightText,
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                   _buildEditableField(
                     label: "Name:",
                     value: widget.driver['full_name'] ?? '',
                     controller: _fullNameController,
                     isDark: isDark,
                   ),
                   const SizedBox(height: 12.0),
                   // License Number (read-only in edit mode)
                   Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       SizedBox(
                         width: 100,
                         child: Text(
                           "License No.:",
                           style: TextStyle(
                             fontFamily: 'Inter',
                             fontSize: 16,
                             fontWeight: FontWeight.bold,
                             color: isDark ? Palette.darkText : Palette.lightText,
                           ),
                         ),
                       ),
                       Icon(Icons.credit_card_outlined, size: 16, color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
                       SizedBox(width: 6),
                       Text(
                         widget.driver['driver_license_number'] ?? 'N/A',
                         style: TextStyle(
                           fontFamily: 'Inter',
                           fontSize: 15,
                           color: isDark ? Palette.darkText : Palette.lightText,
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 12.0),
                   _buildEditableField(
                     label: "Driver Number:",
                     value: widget.driver['driver_number'] ?? 'N/A',
                     controller: _driverNumberController,
                     isDark: isDark,
                   ),
                   const SizedBox(height: 12.0),
                   _buildEditableField(
                     label: "Vehicle ID:",
                     value: widget.driver['vehicle_id']?.toString() ?? 'N/A',
                     controller: _vehicleIdController,
                     isDark: isDark,
                   ),
                   const SizedBox(height: 12.0),
                  // Status indicator (read-only in edit mode)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          "Status:",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Palette.darkText : Palette.lightText,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.driver['driving_status']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _capitalizeFirstLetter(widget.driver['driving_status'] ?? 'N/A'),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  // Last online (read-only in edit mode)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          "Last Online:",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Palette.darkText : Palette.lightText,
                          ),
                        ),
                      ),
                      Icon(Icons.access_time, size: 16, color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
                      SizedBox(width: 6),
                      Text(
                        _formatLastOnline(widget.driver['last_online']),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          color: isDark ? Palette.darkText : Palette.lightText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build editable fields with improved styling
  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Palette.darkText : Palette.lightText,
            ),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Palette.darkSurface : Palette.lightSurface,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? Palette.darkBorder : Palette.lightBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Palette.greenColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? Palette.darkBorder : Palette.lightBorder),
              ),
            ),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: isDark ? Palette.darkText : Palette.lightText,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build legend items
  Widget _buildLegendItem(Color color, String label) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
