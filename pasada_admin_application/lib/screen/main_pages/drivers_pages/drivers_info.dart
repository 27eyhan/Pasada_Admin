import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'drivers_actlogs.dart';

class DriverInfo extends StatefulWidget {
  final Map<String, dynamic> driver;
  final bool initialEditMode;
  
  const DriverInfo({
    Key? key, 
    required this.driver,
    this.initialEditMode = false,
  }) : super(key: key);

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
    _fullNameController = TextEditingController(text: widget.driver['full_name'] ?? '');
    _driverNumberController = TextEditingController(text: widget.driver['driver_number'] ?? '');
    _vehicleIdController = TextEditingController(text: widget.driver['vehicle_id']?.toString() ?? '');
    _driverLicenseController = TextEditingController(text: widget.driver['driver_license_number'] ?? '');
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
        _vehicleIdController.text == widget.driver['vehicle_id']?.toString() &&
        _driverLicenseController.text == widget.driver['driver_license_number']) {
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
        'driver_license_number': _driverLicenseController.text,
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
        print('_saveChanges: Explicitly logged activity for status $currentStatus');
      } else {
        print('_saveChanges: No status available to log activity');
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
  Future<bool> _checkForDuplicateData(String field, String value, String currentDriverId) async {
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
    final DateTime firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final int daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final DateTime lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, daysInMonth);
    
    // Initialize all days to 0 (inactive) first
    for (int i = 0; i < daysInMonth; i++) {
      final DateTime date = DateTime(firstDayOfMonth.year, firstDayOfMonth.month, i + 1);
      _heatMapData[date] = 0;
    }
    
    print('Fetching driver activity logs for driver ${widget.driver['driver_id']} from $firstDayOfMonth to $lastDayOfMonth');
    
    // Fetch driver activity logs for the current month
    _activityLogs.fetchDriverActivityLogs(firstDayOfMonth, lastDayOfMonth).then((activityLogs) {
      bool hasActivityData = false;
      
      if (activityLogs.isNotEmpty) {
        print('Found ${activityLogs.length} activity logs for the current month');
        // Process activity logs
        for (var log in activityLogs) {
          try {
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
              hasActivityData = true;
              print('Added activity level $activityLevel for date $logDate (session duration: ${sessionDuration/3600} hours)');
            } else {
              // If no session duration, just mark as active
              _heatMapData[logDate] = 1;
              hasActivityData = true;
              print('Added activity level 1 for date $logDate (no session duration)');
            }
          } catch (e) {
            print('Error processing activity log: $e');
            // Continue with other logs instead of failing completely
            continue;
          }
        }
      } else {
        print('No activity logs found for the current month');
      }
      
      // Only use last_online as fallback if we couldn't find ANY activity data
      if (!hasActivityData && widget.driver['last_online'] != null) {
        try {
          print('No activity data found, using last_online as fallback');
          final DateTime lastOnline = DateTime.parse(widget.driver['last_online'].toString());
          if (lastOnline.month == _currentMonth.month && lastOnline.year == _currentMonth.year) {
            _heatMapData[DateTime(lastOnline.year, lastOnline.month, lastOnline.day)] = 1;
            print('Added last_online data for ${lastOnline.toString()} with level 1');
          }
        } catch (e) {
          print('Error parsing last_online date: $e');
        }
      }
      
      setState(() {});
    }).catchError((error) {
      print('Error fetching activity logs: $error');
      
      // Only use last_online if we couldn't fetch activity logs at all
      if (widget.driver['last_online'] != null) {
        try {
          print('Using last_online as fallback due to error fetching logs');
          final DateTime lastOnline = DateTime.parse(widget.driver['last_online'].toString());
          if (lastOnline.month == _currentMonth.month && lastOnline.year == _currentMonth.year) {
            _heatMapData[DateTime(lastOnline.year, lastOnline.month, lastOnline.day)] = 1; // Changed from 4 to 1 for consistency
            print('Added last_online data for ${lastOnline.toString()} with level 1');
          }
        } catch (e) {
          print('Error parsing last_online date: $e');
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
      await supabase
          .from('driverTable')
          .update({'driving_status': newStatus, 'last_online': now.toIso8601String()})
          .eq('driver_id', widget.driver['driver_id']);
      
      // Log this activity
      await _activityLogs.logDriverActivity(newStatus, now);
      
      // Refresh UI
      setState(() {});
      
    } catch (e) {
      print('Error updating driver status: ${e.toString()}');
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
    final double screenWidth = MediaQuery.of(context).size.width * 0.45; // Increased width ratio
    final double dialogWidth = screenWidth;
    // Make dialog wider than it is tall
    final double dialogHeight = screenWidth * 0.7; // Reduced height ratio
    final driver = widget.driver;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Palette.greenColor, width: 2),
      ),
      elevation: 8.0,
      backgroundColor: Palette.whiteColor,
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Enhanced header with icon and better spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Palette.greenColor, size: 28),
                    SizedBox(width: 12.0),
                    Text(
                      "Driver Information",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Palette.greenColor,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: Palette.blackColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Divider(color: Palette.greenColor.withAlpha(50), thickness: 1.5),
            const SizedBox(height: 12.0),
            
            // Main content with two columns
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN - Driver Information (switched from right)
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Driver ID with badge-like styling
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Palette.greenColor.withAlpha(40),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Palette.greenColor.withAlpha(100)),
                            ),
                            child: Text(
                              "Driver ID: ${driver['driver_id']?.toString() ?? 'N/A'}",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Palette.greenColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          
                          // Editable fields with better styling
                          _buildEditableField(
                            label: "Name:",
                            value: driver['full_name'] ?? '',
                            controller: _fullNameController,
                          ),
                          const SizedBox(height: 12.0),
                          _buildEditableField(
                            label: "License No.:",
                            value: driver['driver_license_number'] ?? 'N/A',
                            controller: _driverLicenseController,
                          ),
                          const SizedBox(height: 12.0),
                          Row(
                            children: [
                              Container(
                                width: 100,
                                child: Text(
                                  "Driver Number:",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Palette.blackColor,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _isEditMode
                                  ? TextFormField(
                                    controller: _driverNumberController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey[400]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Palette.greenColor, width: 2),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey[400]!),
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      color: Palette.blackColor,
                                    ),
                                  )
                                  : Text(
                                    driver['driver_number'] ?? 'N/A',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      color: Palette.blackColor,
                                    ),
                                  ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),
                          _buildEditableField(
                            label: "Vehicle ID:",
                            value: driver['vehicle_id']?.toString() ?? 'N/A',
                            controller: _vehicleIdController,
                          ),
                          const SizedBox(height: 12.0),
                          
                          // Status indicator with color coding
                          Row(
                            children: [
                              Container(
                                width: 100,
                                child: Text(
                                  "Status:",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Palette.blackColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(driver['driving_status']),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "${_capitalizeFirstLetter(driver['driving_status'] ?? 'N/A')}",
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
                          
                          // Last online with icon
                          Row(
                            children: [
                              Container(
                                width: 100,
                                child: Text(
                                  "Last Online:",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Palette.blackColor,
                                  ),
                                ),
                              ),
                              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 6),
                              Text(
                                _formatLastOnline(driver['last_online']),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  color: Palette.blackColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 20), // Spacing between columns
                  
                  // RIGHT COLUMN - Driver Activity (switched from left)
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Calendar section
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(color: Palette.greenColor.withAlpha(30)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withAlpha(20),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Calendar header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.calendar_today, color: Palette.greenColor, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Driver Activity",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Palette.greenColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
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
                                        setState(() {});
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
                        ),
                        const SizedBox(height: 8.0),
                        // Legend with more compact layout
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _buildLegendItem(Palette.greyColor, "Inactive"),
                            _buildLegendItem(Palette.greenColor.withAlpha(100), "< 1 hour"),
                            _buildLegendItem(Palette.greenColor.withAlpha(150), "1-2 hours"),
                            _buildLegendItem(Palette.greenColor.withAlpha(200), "2-4 hours"),
                            _buildLegendItem(Palette.greenColor, "4+ hours"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16.0),
            
            // Enhanced buttons with consistent styling
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Contact Driver button (or Cancel in edit mode)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEditMode ? Colors.red.shade400 : Palette.whiteColor,
                    foregroundColor: Palette.blackColor,
                    elevation: 4.0,
                    shadowColor: Colors.grey.shade300,
                    side: BorderSide(color: _isEditMode ? Colors.red.shade400 : Colors.grey.shade400, width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  ),
                  onPressed: () {
                    if (_isEditMode) {
                      // Reset the text controllers to original values
                      _fullNameController.text = widget.driver['full_name'] ?? '';
                      _driverNumberController.text = widget.driver['driver_number'] ?? '';
                      _vehicleIdController.text = widget.driver['vehicle_id']?.toString() ?? '';
                      _driverLicenseController.text = widget.driver['driver_license_number'] ?? '';
                      
                      // Exit edit mode
                      setState(() {
                        _isEditMode = false;
                      });
                      
                      // If dialog was opened directly in edit mode, close it
                      if (widget.initialEditMode) {
                        Navigator.of(context).pop();
                      }
                    } else {
                      // Contact driver logic here
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isEditMode ? Icons.cancel : Icons.phone, 
                        size: 20, 
                        color: _isEditMode ? Colors.white : Palette.blackColor
                      ),
                      SizedBox(width: 8),
                      Text(
                        _isEditMode ? "Cancel" : "Contact Driver",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _isEditMode ? Colors.white : Palette.blackColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEditMode ? Palette.greenColor : Palette.whiteColor,
                    foregroundColor: Palette.blackColor,
                    elevation: 4.0,
                    shadowColor: Colors.grey.shade300,
                    side: BorderSide(color: _isEditMode ? Palette.greenColor : Colors.grey.shade400, width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  ),
                  onPressed: _toggleEditMode,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isEditMode ? Icons.save : Icons.edit, 
                        size: 20, 
                        color: _isEditMode ? Colors.white : Palette.blackColor
                      ),
                      SizedBox(width: 8),
                      Text(
                        _isEditMode ? "Save Changes" : "Manage Driver",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _isEditMode ? Colors.white : Palette.blackColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build legend items
  Widget _buildLegendItem(Color color, String label) {
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
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  // Helper method to get status color
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    switch(status.toLowerCase()) {
      case 'online':
      case 'active':
        return Palette.greenColor;
      case 'driving':
        return Palette.greenColor;
      case 'idling':
        return Palette.orangeColor;
      case 'offline':
        return Palette.redColor;
      default:
        return Palette.greyColor;
    }
  }

  // Helper method to build editable fields with improved styling
  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
  }) {
    return _isEditMode
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 100,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Palette.blackColor,
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Palette.greenColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Palette.blackColor,
                  ),
                ),
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Palette.blackColor,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Palette.blackColor,
            ),
                ),
              ),
            ],
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
  
  // Helper method to capitalize first letter
  String _capitalizeFirstLetter(String text) {
    if (text == null || text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  
  // Method to get month name from month number
}
