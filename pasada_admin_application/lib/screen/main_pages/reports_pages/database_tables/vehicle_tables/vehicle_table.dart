import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
// Import dialogs
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/vehicle_tables/add_vehicle_dialog.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/vehicle_tables/edit_vehicle_dialog.dart';

class VehicleTableScreen extends StatefulWidget {
  const VehicleTableScreen({Key? key}) : super(key: key);

  @override
  _VehicleTableScreenState createState() => _VehicleTableScreenState();
}

class _VehicleTableScreenState extends State<VehicleTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> vehicleData = [];
  bool isLoading = true;
  Timer? _refreshTimer; // Timer variable for refreshing the state
  int? _selectedRowIndex; // State variable to track selected row index
  String? _pendingAction; // State variable for pending edit/delete action

  @override
  void initState() {
    super.initState();
    fetchVehicleData();
    // Set up a periodic timer that refreshes every 30 seconds.
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchVehicleData();
    });
    // Debug
  }

  @override
  void dispose() {
    // Cancel the timer to prevent memory leaks.
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchVehicleData() async {
     // Reset selection state on fetch
    setState(() {
      _selectedRowIndex = null;
      _pendingAction = null; // Also reset pending action on refresh
      isLoading = true;
    });
    try {
      // Retrieve all columns from 'vehicleTable'
      final data = await supabase.from('vehicleTable').select('*');
      // Debug: verify data retrieval
      final List listData = data as List;
      if (mounted) { // Check if the widget is still mounted
        setState(() {
          vehicleData = listData.cast<Map<String, dynamic>>();
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
    // Restart timer after fetch completes or fails
    // _startRefreshTimer(); 
    // print("Vehicle Timer potentially restarted after fetch"); // Debug
  }

  // --- Action Handlers (Placeholders) ---
  void _handleAddVehicle() async {
    _refreshTimer?.cancel();

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AddVehicleDialog(
            supabase: supabase,
            onVehicleActionComplete: fetchVehicleData,
          );
        },
      );
    } finally {
      _startRefreshTimer(); // Restart timer when dialog closes
    }
  }

  void _handleEditVehicle(Map<String, dynamic> selectedVehicleData) async {
    _refreshTimer?.cancel();

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return EditVehicleDialog(
            supabase: supabase,
            onVehicleActionComplete: fetchVehicleData,
            vehicleData: selectedVehicleData,
          );
        },
      );
    } finally {
      _startRefreshTimer(); // Restart timer when dialog closes
    }
  }

  void _handleDeleteVehicle(Map<String, dynamic> selectedVehicleData) async {
    final vehicleId = selectedVehicleData['vehicle_id'];
    final plateNumber = selectedVehicleData['plate_number']?.toString() ?? 'ID: $vehicleId';
    _refreshTimer?.cancel();

    bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Palette.whiteColor,
          title: const Text('Confirm Deletion'),
          contentPadding: const EdgeInsets.all(24.0),
          content: Text('Are you sure you want to delete vehicle $plateNumber?'),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    _startRefreshTimer(); // Restart timer regardless of outcome

    if (confirmed == true) {
      try {
        await supabase
            .from('vehicleTable')
            .delete()
            .match({'vehicle_id': vehicleId});

        _showInfoSnackBar('Vehicle $plateNumber deleted successfully.');
        fetchVehicleData(); // Refresh data after deletion

      } catch (e) {
        _showInfoSnackBar('Error deleting vehicle: ${e.toString()}');
      }
    } else {
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

  // Function to start the periodic refresh timer (Helper)
  void _startRefreshTimer() {
    _refreshTimer?.cancel(); // Cancel any existing timer
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
       if (mounted) { // Check if mounted before fetching
          fetchVehicleData();
       }
    });
     // Debug
  }

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
          // Main content: loading indicator, "No data found." message, or the DataTable.
          Center( // Center the table content
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : vehicleData.isEmpty
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
                              DataColumn(label: Text('Vehicle ID')),
                              DataColumn(label: Text('Plate Number')),
                              DataColumn(label: Text('Route ID')),
                              DataColumn(label: Text('Passenger Capacity')),
                              DataColumn(label: Text('Vehicle Location')),
                              DataColumn(label: Text('Created At')),
                            ],
                            rows: vehicleData.asMap().entries.map((entry) { // Use asMap().entries
                                final int index = entry.key;
                                final Map<String, dynamic> vehicle = entry.value;
                                final bool allowSelection = _pendingAction != null;

                              return DataRow(
                                selected: allowSelection && (_selectedRowIndex == index),
                                onSelectChanged: allowSelection
                                  ? (bool? selected) {
                                    setState(() {
                                      if (selected ?? false) {
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
                                  DataCell(Text(vehicle['vehicle_id'].toString())),
                                  DataCell(Text(vehicle['plate_number']?.toString() ?? 'N/A')),
                                  DataCell(Text(vehicle['route_id']?.toString() ?? 'N/A')),
                                  DataCell(Text(vehicle['passenger_capacity']?.toString() ?? 'N/A')),
                                  DataCell(Text(vehicle['vehicle_location']?.toString() ?? 'N/A')),
                                  DataCell(Text(vehicle['created_at'].toString())),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
          // Positioned back button at top-left.
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
                    // Stop timer only for actions that show a dialog or require selection
                    _refreshTimer?.cancel();
                    // Debug

                    switch (value) {
                      case 'add':
                        _handleAddVehicle();
                        break;
                      case 'edit':
                      case 'delete':
                        setState(() {
                          _pendingAction = value;
                        });
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'add',
                      child: Text('Add Vehicle'),
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
                          _refreshTimer?.cancel(); 
                          _startRefreshTimer(); // Restart timer
                          setState(() {
                            _pendingAction = null;
                            _selectedRowIndex = null;
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
                                final selectedData = vehicleData[_selectedRowIndex!];
                                // Timer already cancelled by PopupMenuButton onSelected

                                // Store pending action locally
                                String? actionToPerform = _pendingAction;

                                // Reset state immediately
                                setState(() {
                                  _pendingAction = null;
                                  _selectedRowIndex = null;
                                });

                                // Execute action (handlers will restart timer)
                                if (actionToPerform == 'edit') {
                                  _handleEditVehicle(selectedData);
                                } else if (actionToPerform == 'delete') {
                                  _handleDeleteVehicle(selectedData);
                                }
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
