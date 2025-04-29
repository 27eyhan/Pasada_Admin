import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  
  // Text editing controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _driverNumberController;
  late TextEditingController _vehicleIdController;
  
  @override
  void initState() {
    super.initState();
    _isEditMode = widget.initialEditMode;
    _generateHeatMapData();
    _initControllers();
  }
  
  void _initControllers() {
    _firstNameController = TextEditingController(text: widget.driver['first_name'] ?? '');
    _lastNameController = TextEditingController(text: widget.driver['last_name'] ?? '');
    _driverNumberController = TextEditingController(text: widget.driver['driver_number'] ?? '');
    _vehicleIdController = TextEditingController(text: widget.driver['vehicle_id']?.toString() ?? '');
  }
  
  @override
  void dispose() {
    // Dispose controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _driverNumberController.dispose();
    _vehicleIdController.dispose();
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
    if (_firstNameController.text == widget.driver['first_name'] &&
        _lastNameController.text == widget.driver['last_name'] &&
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
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'driver_number': _driverNumberController.text,
        'vehicle_id': _vehicleIdController.text,
      };
      
      // Implement the actual database update
      final supabase = Supabase.instance.client;
      await supabase
          .from('driverTable')
          .update(updatedDriver)
          .eq('driver_id', widget.driver['driver_id']);
      
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Driver information updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
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
  
  Future<List<Map<String, dynamic>>> fetchDriverActivityLogs(DateTime startDate, DateTime endDate) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('driverActivityLog')
          .select('log_id, driver_id, login_timestamp, logout_timestamp, session_duration, status')
          .eq('driver_id', widget.driver['driver_id'])
          .gte('login_timestamp', startDate.toIso8601String())
          .lte('login_timestamp', endDate.toIso8601String())
          .order('login_timestamp');
      
      return response;
    } catch (e) {
      return [];
    }
  }

  // Log driver activity when status changes
  Future<void> logDriverActivity(String status, DateTime timestamp) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Check if there's an ongoing session without a logout
      final ongoingSession = await supabase
          .from('driverActivityLog')
          .select()
          .eq('driver_id', widget.driver['driver_id'])
          .filter('logout_timestamp', 'is', null)
          .maybeSingle();
      
      if (ongoingSession != null) {
        // Calculate session duration in seconds
        final loginTime = DateTime.parse(ongoingSession['login_timestamp']);
        final duration = timestamp.difference(loginTime).inSeconds;
        
        // Update the existing session with logout time and duration
        await supabase
            .from('driverActivityLog')
            .update({
              'logout_timestamp': timestamp.toIso8601String(),
              'session_duration': duration,
            })
            .eq('log_id', ongoingSession['log_id']);
      }
      
      // If status is one of the active statuses, create a new session
      if (status == 'Online' || status == 'Driving' || status == 'Idling') {
        // Insert new activity log with auto-generated UUID (handled by Supabase)
        await supabase
            .from('driverActivityLog')
            .insert({
              'driver_id': widget.driver['driver_id'],
              'login_timestamp': timestamp.toIso8601String(),
              'status': status,
            });
      }
      
      // Refresh heatmap data
      _generateHeatMapData();
      
    } catch (e) {
    }
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
                    _buildEditableField(
                      label: "First Name:",
                      value: driver['first_name'] ?? '',
                      controller: _firstNameController,
                    ),
                    const SizedBox(height: 8.0),
                    _buildEditableField(
                      label: "Last Name:",
                      value: driver['last_name'] ?? '',
                      controller: _lastNameController,
                    ),
                    const SizedBox(height: 8.0),
                    _buildEditableField(
                      label: "Driver Number:",
                      value: driver['driver_number'] ?? 'N/A',
                      controller: _driverNumberController,
                    ),
                    const SizedBox(height: 8.0),
                    _buildEditableField(
                      label: "Vehicle ID:",
                      value: driver['vehicle_id']?.toString() ?? 'N/A',
                      controller: _vehicleIdController,
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
                // Contact Driver button (or Cancel in edit mode)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEditMode ? Palette.orangeColor : Palette.whiteColor,
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
                    if (_isEditMode) {
                      // Reset the text controllers to original values
                      _firstNameController.text = widget.driver['first_name'] ?? '';
                      _lastNameController.text = widget.driver['last_name'] ?? '';
                      _driverNumberController.text = widget.driver['driver_number'] ?? '';
                      _vehicleIdController.text = widget.driver['vehicle_id']?.toString() ?? '';
                      
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
                  child: Text(
                    _isEditMode ? "Cancel" : "Contact Driver",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: _isEditMode ? Colors.white : Palette.blackColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEditMode ? Palette.greenColor : Palette.whiteColor,
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
                  onPressed: _toggleEditMode,
                  child: Text(
                    _isEditMode ? "Save Changes" : "Manage Driver",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: _isEditMode ? Colors.white : Palette.blackColor,
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

  // Helper method to build editable fields
  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
  }) {
    return _isEditMode
        ? Row(
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
                    color: Palette.blackColor,
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey),
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
        : Text(
            "$label $value",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Palette.blackColor,
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
