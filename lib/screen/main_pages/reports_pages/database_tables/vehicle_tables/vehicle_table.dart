import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:pasada_admin_application/widgets/responsive_layout.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/filter_dialog.dart';
// Import dialogs
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/vehicle_tables/add_vehicle_dialog.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/vehicle_tables/edit_vehicle_dialog.dart';

class VehicleTableScreen extends StatefulWidget {
  const VehicleTableScreen({super.key});

  @override
  _VehicleTableScreenState createState() => _VehicleTableScreenState();
}

class _VehicleTableScreenState extends State<VehicleTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> vehicleData = [];
  List<Map<String, dynamic>> filteredVehicleData = [];
  bool isLoading = true;
  Timer? _refreshTimer; // Timer variable for refreshing the state
  int? _selectedRowIndex; // State variable to track selected row index
  String? _pendingAction; // State variable for pending edit/delete action
  
  // Filter state
  Set<String> selectedStatuses = {};
  String? selectedRouteId;

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
  
  void _showFilterDialog() async {
    _refreshTimer?.cancel(); // Pause timer during filtering
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return FilterDialog(
          selectedStatuses: selectedStatuses,
          selectedRouteId: selectedRouteId,
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedStatuses = result['selectedStatuses'] as Set<String>;
        selectedRouteId = result['selectedRouteId'] as String?;
        _applyFilters();
      });
    }
    
    _startRefreshTimer(); // Resume timer
  }
  
  void _applyFilters() {
    setState(() {
      if (selectedStatuses.isEmpty && selectedRouteId == null) {
        // No filters applied, show all data
        filteredVehicleData = List.from(vehicleData);
      } else {
        filteredVehicleData = vehicleData.where((vehicle) {
          // Get vehicle status from driverTable relationship
          String? vehicleStatus = 'Offline';
          
          // Filter by status - using the vehicle's status
          // For a vehicle table, we would need to determine the status differently
          // This would depend on how status is stored in the actual data
          // For now, we'll assume status is determined in a similar way to fleet.dart
          bool statusMatch = selectedStatuses.isEmpty;
          
          if (!statusMatch && vehicle['driverTable'] != null) {
            // If there is status data from a driver relationship
            final driverData = vehicle['driverTable'];
            if (driverData != null && driverData is List && driverData.isNotEmpty) {
              final driverMap = driverData.first as Map<String, dynamic>?;
              if (driverMap != null) {
                vehicleStatus = driverMap['driving_status'] as String?;
                statusMatch = selectedStatuses.contains(vehicleStatus);
              }
            }
          }
          
          // Filter by route ID
          bool routeMatch = selectedRouteId == null || 
              vehicle['route_id']?.toString() == selectedRouteId;

          return (selectedStatuses.isEmpty || statusMatch) && routeMatch;
        }).toList();
      }
      
      // Apply default sorting by Vehicle ID numerically
      filteredVehicleData.sort((a, b) {
        var aId = a['vehicle_id'];
        var bId = b['vehicle_id'];
        // Handle null values
        if (aId == null) return 1;
        if (bId == null) return -1;
        // Try numeric sort if possible
        int? aNum = int.tryParse(aId.toString());
        int? bNum = int.tryParse(bId.toString());
        if (aNum != null && bNum != null) {
          return aNum.compareTo(bNum);
        }
        // Fall back to string comparison
        return aId.toString().compareTo(bId.toString());
      });
    });
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
      final data = await supabase.from('vehicleTable').select('*, driverTable(driver_id, driving_status)');
      // Debug: verify data retrieval
      final List listData = data as List;
      if (mounted) { // Check if the widget is still mounted
        setState(() {
          vehicleData = listData.cast<Map<String, dynamic>>();
          isLoading = false;
          
          // Apply any existing filters
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) { // Check if the widget is still mounted
        setState(() {
          isLoading = false;
          vehicleData = [];
          filteredVehicleData = [];
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
    final plateNumber = selectedVehicleData['plate_number']?.toString() ?? 'N/A';
    final routeId = selectedVehicleData['route_id']?.toString() ?? 'N/A';
    final capacity = selectedVehicleData['passenger_capacity']?.toString() ?? 'N/A';
    
    _refreshTimer?.cancel();

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Palette.whiteColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.red, width: 2),
            ),
            icon: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
            title: Text(
              'Delete Vehicle Confirmation', 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            contentPadding: const EdgeInsets.all(24.0),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You are about to delete the following vehicle:'),
                SizedBox(height: 16),
                _buildInfoRow('Vehicle ID:', vehicleId.toString()),
                _buildInfoRow('Plate Number:', plateNumber),
                _buildInfoRow('Route ID:', routeId),
                _buildInfoRow('Capacity:', capacity),
                SizedBox(height: 16),
                Text(
                  'This action cannot be undone. All associated data will be permanently deleted.',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            actions: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Delete Vehicle', style: TextStyle(fontWeight: FontWeight.w600)),
                onPressed: () async {
                  Navigator.of(context).pop(); // Close the dialog first
                  try {
                    // Show loading indicator
                    _showInfoSnackBar('Deleting vehicle...');
                    
                    // Perform the delete operation
                    await supabase
                        .from('vehicleTable')
                        .delete()
                        .match({'vehicle_id': vehicleId});

                    _showInfoSnackBar('Vehicle $plateNumber deleted successfully.');
                    fetchVehicleData(); // Refresh data after deletion

                  } catch (e) {
                    _showInfoSnackBar('Error deleting vehicle: ${e.toString()}');
                  }
                },
              ),
            ],
          );
        },
      );
    } finally {
      _startRefreshTimer(); // Restart timer when dialog closes
    }
  }
  
  // Helper method to build info rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
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
    final Map<String, dynamic>? selectedData = isRowSelected && _selectedRowIndex! < filteredVehicleData.length 
        ? filteredVehicleData[_selectedRowIndex!] 
        : null;

    return Scaffold(
      backgroundColor: Palette.whiteColor,
      appBar: AppBarSearch(onFilterPressed: _showFilterDialog),
      drawer: MyDrawer(),
      body: Stack(
        children: [
          // Main content: loading indicator, "No data found." message, or the DataTable.
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : vehicleData.isEmpty
                  ? const Center(child: Text("No data found."))
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          margin: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Palette.whiteColor,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: Palette.blackColor.withValues(alpha: 128),
                              width: 1,
                            ),
                          ),
                          child: DataTable(
                            columnSpacing: ResponsiveHelper.isMobile(context) ? 15.0 : 60.0,
                            horizontalMargin: ResponsiveHelper.isMobile(context) ? 6.0 : 8.0,
                            headingRowHeight: ResponsiveHelper.isMobile(context) ? 35.0 : 40.0,
                            dataRowMinHeight: ResponsiveHelper.isMobile(context) ? 30.0 : 35.0,
                            dataRowMaxHeight: ResponsiveHelper.isMobile(context) ? 40.0 : 45.0,
                            showCheckboxColumn: false,
                            columns: [
                              DataColumn(label: ResponsiveText('Vehicle ID', 
                                mobileFontSize: 12.0, 
                                tabletFontSize: 13.0, 
                                desktopFontSize: 14.0, 
                                fontWeight: FontWeight.bold)),
                              DataColumn(label: ResponsiveText('Plate Number', 
                                mobileFontSize: 12.0, 
                                tabletFontSize: 13.0, 
                                desktopFontSize: 14.0, 
                                fontWeight: FontWeight.bold)),
                              DataColumn(label: ResponsiveText('Route ID', 
                                mobileFontSize: 12.0, 
                                tabletFontSize: 13.0, 
                                desktopFontSize: 14.0, 
                                fontWeight: FontWeight.bold)),
                              DataColumn(label: ResponsiveText('Capacity', 
                                mobileFontSize: 12.0, 
                                tabletFontSize: 13.0, 
                                desktopFontSize: 14.0, 
                                fontWeight: FontWeight.bold)),
                              DataColumn(label: ResponsiveText('Location', 
                                mobileFontSize: 12.0, 
                                tabletFontSize: 13.0, 
                                desktopFontSize: 14.0, 
                                fontWeight: FontWeight.bold)),
                              DataColumn(label: ResponsiveText('Created At', 
                                mobileFontSize: 12.0, 
                                tabletFontSize: 13.0, 
                                desktopFontSize: 14.0, 
                                fontWeight: FontWeight.bold)),
                            ],
                            rows: filteredVehicleData.asMap().entries.map((entry) { // Use filteredVehicleData
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
                                  DataCell(
                                    Row(
                                      children: [
                                        if (allowSelection)
                                          Radio<int>(
                                            value: index,
                                            groupValue: _selectedRowIndex,
                                            onChanged: (int? value) {
                                              setState(() {
                                                _selectedRowIndex = value;
                                              });
                                            },
                                          ),
                                        SizedBox(width: 8),
                                        ResponsiveText(vehicle['vehicle_id'].toString(), 
                                          mobileFontSize: 11.0, 
                                          tabletFontSize: 12.0, 
                                          desktopFontSize: 14.0),
                                      ],
                                    )
                                  ),
                                  DataCell(ResponsiveText(vehicle['plate_number']?.toString() ?? 'N/A', 
                                    mobileFontSize: 11.0, 
                                    tabletFontSize: 12.0, 
                                    desktopFontSize: 14.0)),
                                  DataCell(ResponsiveText(vehicle['route_id']?.toString() ?? 'N/A', 
                                    mobileFontSize: 11.0, 
                                    tabletFontSize: 12.0, 
                                    desktopFontSize: 14.0)),
                                  DataCell(ResponsiveText(vehicle['passenger_capacity']?.toString() ?? 'N/A', 
                                    mobileFontSize: 11.0, 
                                    tabletFontSize: 12.0, 
                                    desktopFontSize: 14.0)),
                                  DataCell(ResponsiveText(vehicle['vehicle_location']?.toString() ?? 'N/A', 
                                    mobileFontSize: 11.0, 
                                    tabletFontSize: 12.0, 
                                    desktopFontSize: 14.0)),
                                  DataCell(ResponsiveText(vehicle['created_at'].toString(), 
                                    mobileFontSize: 11.0, 
                                    tabletFontSize: 12.0, 
                                    desktopFontSize: 14.0)),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
          // Floating back button at top-left.
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
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            side: BorderSide(color: Colors.grey[400]!),
                          ),
                        ),
                        onPressed: () {
                          _refreshTimer?.cancel(); 
                          _startRefreshTimer(); // Restart timer
                          setState(() {
                            _pendingAction = null;
                            _selectedRowIndex = null;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cancel, size: 18),
                            SizedBox(width: 8),
                            Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15.0),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRowSelected ? (_pendingAction == 'edit' ? Palette.greenColor : (_pendingAction == 'delete' ? Colors.red : Colors.green)) : Colors.grey,
                          foregroundColor: Palette.whiteColor,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          elevation: 3,
                          shadowColor: isRowSelected ? (_pendingAction == 'edit' ? Palette.greenColor.withAlpha(128) : (_pendingAction == 'delete' ? Colors.red.withAlpha(128) : Colors.green.withAlpha(128))) : Colors.grey.withAlpha(128),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        onPressed: isRowSelected && selectedData != null
                            ? () {
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_pendingAction == 'edit' ? Icons.edit : (_pendingAction == 'delete' ? Icons.delete : Icons.check), size: 18),
                            SizedBox(width: 8),
                            Text('Continue ${_pendingAction == 'edit' ? 'Edit' : (_pendingAction == 'delete' ? 'Delete' : _pendingAction ?? '')}', 
                                 style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
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
