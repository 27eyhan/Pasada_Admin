import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
// Import dialogs
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/route_tables/add_route_dialog.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/route_tables/edit_route_dialog.dart';

class DriverRouteTableScreen extends StatefulWidget {
  const DriverRouteTableScreen({Key? key}) : super(key: key);

  @override
  _DriverRouteTableScreenState createState() => _DriverRouteTableScreenState();
}

class _DriverRouteTableScreenState extends State<DriverRouteTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> routeData = [];
  bool isLoading = true;
  Timer? _refreshTimer; // Timer variable for refreshing the state
  int? _selectedRowIndex; // State variable to track selected row index
  String? _pendingAction; // State variable for pending edit/delete action

  @override
  void initState() {
    super.initState();
    fetchRouteData();
    // Set up a periodic timer that refreshes every 30 seconds.
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchRouteData();
    });
    // Debug
  }

  @override
  void dispose() {
    // Cancel the timer to prevent memory leaks.
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchRouteData() async {
    // Reset selection state on fetch
    setState(() {
      _selectedRowIndex = null;
      _pendingAction = null; // Also reset pending action on refresh
      isLoading = true; // Set loading true at the beginning
    });
    try {
      // Fetch all columns from 'official_routes'
      final data = await supabase.from('official_routes').select('*');
      // Debug: verify data retrieval
      final List listData = data as List;
       if (mounted) { // Check if the widget is still mounted
        setState(() {
          routeData = listData.cast<Map<String, dynamic>>();
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
    // print("Route Timer potentially restarted after fetch"); // Debug
  }

  // --- Action Handlers (Placeholders) ---
  void _handleAddRoute() async {
    _refreshTimer?.cancel();

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AddRouteDialog(
            supabase: supabase,
            onRouteActionComplete: fetchRouteData,
          );
        },
      );
    } finally {
      _startRefreshTimer(); // Restart timer when dialog closes
    }
  }

  void _handleEditRoute(Map<String, dynamic> selectedRouteData) async {
    _refreshTimer?.cancel();

    try {
     await showDialog(
       context: context,
       barrierDismissible: false,
       builder: (BuildContext context) {
         return EditRouteDialog(
           supabase: supabase,
           onRouteActionComplete: fetchRouteData,
           routeData: selectedRouteData,
         );
       },
     );
   } finally {
     _startRefreshTimer(); // Restart timer when dialog closes
   }
  }

    void _handleDeleteRoute(Map<String, dynamic> selectedRouteData) async {
    final routeId = selectedRouteData['officialroute_id'];
    final routeName = selectedRouteData['route_name']?.toString() ?? 'ID: $routeId'; // Use route name or ID
    final startingPlace = selectedRouteData['origin_name']?.toString() ?? 'N/A';
    final endingPlace = selectedRouteData['destination_name']?.toString() ?? 'N/A';
    
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
              'Delete Route Confirmation', 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            contentPadding: const EdgeInsets.all(24.0),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You are about to delete the following route:'),
                SizedBox(height: 16),
                _buildInfoRow('Route ID:', routeId.toString()),
                _buildInfoRow('Route Name:', routeName),
                _buildInfoRow('Starting Place:', startingPlace),
                _buildInfoRow('Ending Place:', endingPlace),
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
                child: const Text('Delete Route', style: TextStyle(fontWeight: FontWeight.w600)),
                onPressed: () async {
                  Navigator.of(context).pop(); // Close the dialog first
                  try {
                    // Show loading indicator
                    _showInfoSnackBar('Deleting route...');
                    
                    await supabase
                        .from('official_routes')
                        .delete()
                        .match({'officialroute_id': routeId});

                    _showInfoSnackBar('Route $routeName deleted successfully.');
                    fetchRouteData(); // Refresh data after deletion

                  } catch (e) {
                    // Check for foreign key constraint violation (common issue)
                    if (e.toString().contains('violates foreign key constraint')) {
                      _showInfoSnackBar('Error: Cannot delete route. It might be assigned to a vehicle.');
                    } else {
                      _showInfoSnackBar('Error deleting route: ${e.toString()}');
                    }
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
          fetchRouteData();
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
          // Main content:
          Center( // Center the table content
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : routeData.isEmpty
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
                            columnSpacing: 80.0, // Reduce column spacing
                            horizontalMargin: 12.0, // Reduce horizontal margin
                            headingRowHeight: 50.0, // Set heading row height
                            dataRowMinHeight: 40.0, // Set minimum row height
                            dataRowMaxHeight: 60.0, // Set maximum row height
                            showCheckboxColumn: false, // Remove checkbox column
                            columns: const [
                              DataColumn(label: Text('ID', style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Route Name', style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Origin', style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Destination', style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Description', style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Status', style: TextStyle(fontSize: 14.0, fontFamily: 'Inter', fontWeight: FontWeight.bold))),
                            ],
                            rows: routeData.asMap().entries.map((entry) { // Use asMap().entries
                              final int index = entry.key;
                              final Map<String, dynamic> route = entry.value;
                              final bool allowSelection = _pendingAction != null;

                              // Create a description from route data
                              // Get status from the database, default to "Inactive" if not available
                              final String status = route['status']?.toString() ?? "Inactive";
                              // Determine status color based on status value
                              Color statusColor;
                              Color statusTextColor;
                              Color statusBorderColor;
                              if (status.toLowerCase() == "active") {
                                statusColor = Colors.green[100]!;
                                statusTextColor = Colors.green[800]!;
                                statusBorderColor = Colors.green[400]!;
                              } else {
                                statusColor = Colors.red[100]!;
                                statusTextColor = Colors.red[800]!;
                                statusBorderColor = Colors.red[400]!;
                              }

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
                                        Text(route['officialroute_id'].toString(), style: TextStyle(fontSize: 14.0)),
                                      ],
                                    )
                                  ),
                                  DataCell(Text(route['route_name']?.toString() ?? 'N/A', style: TextStyle(fontSize: 14.0))),
                                  DataCell(Text(route['origin_name']?.toString() ?? 'N/A', style: TextStyle(fontSize: 14.0))),
                                  DataCell(Text(route['destination_name']?.toString() ?? 'N/A', style: TextStyle(fontSize: 14.0))),
                                  DataCell(Text(route['description']?.toString() ?? 'N/A', style: TextStyle(fontSize: 14.0))),
                                  DataCell(
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: statusBorderColor),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          color: statusTextColor,
                                          fontWeight: FontWeight.w600
                                        ),
                                      ),
                                    )
                                  ),
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
                        _handleAddRoute();
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
                      child: Text('Add Route'),
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
                          // Debug
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
                        onPressed: isRowSelected
                            ? () {
                                final selectedData = routeData[_selectedRowIndex!];
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
                                  _handleEditRoute(selectedData);
                                } else if (actionToPerform == 'delete') {
                                  _handleDeleteRoute(selectedData);
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
