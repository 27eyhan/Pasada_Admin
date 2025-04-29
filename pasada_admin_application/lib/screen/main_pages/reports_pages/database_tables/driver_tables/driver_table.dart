import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:pasada_admin_application/screen/main_pages/drivers_pages/drivers_info.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/driver_tables/add_driver_dialog.dart';

class DriverTableScreen extends StatefulWidget {
  const DriverTableScreen({Key? key}) : super(key: key);

  @override
  _DriverTableScreenState createState() => _DriverTableScreenState();
}

class _DriverTableScreenState extends State<DriverTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> driverData = [];
  bool isLoading = true;
  Timer? _refreshTimer; // Timer variable for refreshing the state
  int? _selectedRowIndex; // State variable to track selected row index
  String? _pendingAction; // State variable for pending edit/delete action
  int _selectionWarningCounter = 0; // Counter for the selection warning snackbar

  // Function to start the periodic refresh timer
  void _startRefreshTimer() {
    _refreshTimer?.cancel(); // Cancel any existing timer
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
       if (mounted) { // Check if mounted before fetching
          fetchDriverData();
       }
    });
     // Debug
  }

  @override
  void initState() {
    super.initState();
    fetchDriverData();
    _startRefreshTimer(); // Start the timer initially
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchDriverData() async {
    // Reset selection state on fetch
    setState(() {
      _selectedRowIndex = null;
      _pendingAction = null; // Also reset pending action on refresh
      isLoading = true;
    });
    try {
      // Select all columns from 'driverTable'
      final data = await supabase.from('driverTable').select('*');
      // Debug: verify data retrieval
      final List listData = data as List;
       if (mounted) { // Check if the widget is still mounted
        setState(() {
          driverData = listData.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) { // Check if the widget is still mounted
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // --- Action Handlers ---
  void _handleAddDriver() async {
    try {
       await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AddDriverDialog(
            supabase: supabase,
            onDriverAdded: fetchDriverData,
          );
        },
      );
    } finally {
       // Debug
      _startRefreshTimer();
    }
  }

  void _handleEditDriver(Map<String, dynamic> selectedDriverData) async {
    
    try {
        // Await the boolean result from the DriverInfo dialog
        final bool? saveSuccess = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return DriverInfo(
              driver: selectedDriverData,
              initialEditMode: true,
            );
          },
        );
        fetchDriverData();
        
    } finally {
        _startRefreshTimer(); // Restart timer when dialog closes
    }
  }

  void _handleDeleteDriver(Map<String, dynamic> selectedDriverData) async {
    final driverId = selectedDriverData['driver_id'];
    final driverName = "${selectedDriverData['first_name'] ?? ''} ${selectedDriverData['last_name'] ?? ''}".trim();

    try {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Palette.whiteColor,
            title: const Text('Confirm Deletion'),
            contentPadding: const EdgeInsets.all(24.0),
            content: Text('Are you sure you want to delete driver ${driverName.isNotEmpty ? driverName : 'ID: $driverId'}?'),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
              TextButton(
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.of(context).pop(); // Close the dialog first
                  try {
                    // Perform the delete operation
                    await supabase
                        .from('driverTable')
                        .delete()
                        .match({'driver_id': driverId});

                    _showInfoSnackBar('Driver $driverId deleted successfully.');
                    fetchDriverData(); // Refresh data after deletion

                  } catch (e) {
                    _showInfoSnackBar('Error deleting driver: ${e.toString()}');
                  }
                },
              ),
            ],
          );
        },
      );
    } finally {
       // Debug
      _startRefreshTimer(); // Restart timer when dialog closes
    }
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }
  // --------------------------------------

  @override
  Widget build(BuildContext context) {
     // Determine if Continue button should be enabled
    final bool isRowSelected = _selectedRowIndex != null;

    return Scaffold(
      backgroundColor: Palette.whiteColor,
      appBar: AppBarSearch(),
      drawer: MyDrawer(),
      body: Stack(
        children: [
          // Main content: loading indicator or table display.
          Center( // Center the table content
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : driverData.isEmpty
                    ? const Center(child: Text("No data found."))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          margin: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Palette.whiteColor,
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: Palette.blackColor.withValues(alpha: 128),
                              width: 1,
                            ),
                          ),
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Driver ID')),
                              DataColumn(label: Text('First Name')),
                              DataColumn(label: Text('Last Name')),
                              DataColumn(label: Text('Driver Number')),
                              DataColumn(label: Text('Password')),
                              DataColumn(label: Text('Created At')),
                              DataColumn(label: Text('Vehicle ID')),
                              DataColumn(label: Text('Driving Status')),
                              DataColumn(label: Text('Last Online')),
                            ],
                            rows: driverData.asMap().entries.map((entry) { // Use asMap().entries
                              final int index = entry.key;
                              final Map<String, dynamic> driver = entry.value;
                              final bool allowSelection = _pendingAction != null;

                              return DataRow(
                                selected: allowSelection && (_selectedRowIndex == index),
                                onSelectChanged: allowSelection
                                  ? (bool? selected) {
                                    setState(() {
                                      if (selected ?? false) {
                                        // If already a different row selected, show message (limited times)
                                        if (_selectedRowIndex != null && _selectedRowIndex != index) {
                                          if (_selectionWarningCounter < 3) { // Limit to 3 warnings
                                             _showInfoSnackBar('Only one driver can be selected at a time');
                                             _selectionWarningCounter++; // Increment counter
                                          }
                                        }
                                        _selectedRowIndex = index;
                                      } else {
                                        if (_selectedRowIndex == index) {
                                          _selectedRowIndex = null;
                                        }
                                      }
                                    });
                                  }
                                  : null,
                                cells: [
                                  DataCell(Text(driver['driver_id'].toString())),
                                  DataCell(Text(driver['first_name']?.toString() ?? 'N/A')),
                                  DataCell(Text(driver['last_name']?.toString() ?? 'N/A')),
                                  DataCell(Text(driver['driver_number']?.toString() ?? 'N/A')),
                                  DataCell(Text(driver['driver_password']?.toString() ?? 'N/A')), // Careful with passwords
                                  DataCell(Text(driver['created_at'].toString())),
                                  DataCell(Text(driver['vehicle_id']?.toString() ?? 'N/A')),
                                  DataCell(Text(driver['driving_status']?.toString() ?? 'N/A')),
                                  DataCell(Text(driver['last_online']?.toString() ?? 'N/A')),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
          // Positioned back button at top-left
          Positioned(
            top: 26.0,
            left: 26.0,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Palette.blackColor, width: 1.0),
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: IconButton(
                  iconSize: 28.0,
                  icon: const Icon(Icons.arrow_back, color: Palette.blackColor),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
          // Positioned Action Button (Top Right)
          Positioned(
            top: 26.0,
            right: 26.0,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Palette.blackColor, width: 1.0),
                  borderRadius: BorderRadius.circular(30.0),
                  color: Palette.whiteColor,
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.edit, color: Palette.blackColor),
                  tooltip: 'Actions',
                  color: Palette.whiteColor,
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Palette.greyColor, width: 1.0),
                  ),
                  offset: const Offset(0, kToolbarHeight * 0.8),
                  onSelected: (String value) {
                    _refreshTimer?.cancel(); // Cancel timer immediately
                    // Debug
                    switch (value) {
                      case 'add':
                        _handleAddDriver();
                        break;
                      case 'edit':
                      case 'delete':
                        setState(() {
                          _pendingAction = value;
                           _selectionWarningCounter = 0; // Reset counter for new action
                          _selectedRowIndex = null; // Ensure no row is selected initially for the new action
                        });
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'add',
                      child: Text('Add Driver'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit Selected'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete Selected'),
                    ),
                  ],
                ),
              ),
            ),
          ),
           // Confirmation Buttons (Bottom Center)
          Positioned(
            bottom: 16.0,
            left: 0,
            right: 0,
            child: Center(
              child: Visibility(
                visible: _pendingAction != null,
                child: Container(
                   padding: const EdgeInsets.all(8.0),
                   decoration: BoxDecoration(
                      color: Palette.whiteColor,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [ BoxShadow(color: Colors.grey.withValues(alpha: 128), spreadRadius: 2, blurRadius: 5) ],
                   ),
                   child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          // Debug
                          _refreshTimer?.cancel(); // Cancel just in case
                           _startRefreshTimer(); // Restart timer
                          setState(() {
                            _pendingAction = null;
                            _selectedRowIndex = null;
                             _selectionWarningCounter = 0; // Reset counter
                          });
                        },
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRowSelected ? Colors.green : Colors.grey,
                          foregroundColor: Palette.whiteColor,
                          disabledBackgroundColor: Colors.grey[400],
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: isRowSelected
                            ? () {
                                final selectedData = driverData[_selectedRowIndex!];
                                _refreshTimer?.cancel(); // Cancel timer before action
                                // Debug

                                if (_pendingAction == 'edit') {
                                  _handleEditDriver(selectedData);
                                } else if (_pendingAction == 'delete') {
                                  _handleDeleteDriver(selectedData);
                                }
                                setState(() {
                                  _pendingAction = null;
                                  _selectedRowIndex = null;
                                   _selectionWarningCounter = 0; // Reset counter
                                });
                              }
                            : null,
                        child: Text('Continue ${_pendingAction == 'edit' ? 'Edit' : (_pendingAction == 'delete' ? 'Delete' : _pendingAction ?? '')}'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
