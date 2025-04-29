import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';

class RideHistoryTableScreen extends StatefulWidget {
  const RideHistoryTableScreen({Key? key}) : super(key: key);

  @override
  _RideHistoryTableScreenState createState() => _RideHistoryTableScreenState();
}

class _RideHistoryTableScreenState extends State<RideHistoryTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> rideHistoryData = [];
  bool isLoading = true;
  Timer? _refreshTimer; // Timer variable for refreshing the state
  int? _selectedRowIndex; // State variable to track selected row index
  String? _pendingAction; // State variable for pending delete action

  @override
  void initState() {
    super.initState();
    fetchRideHistoryData();
    // Set up a periodic timer that refreshes every 30 seconds.
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchRideHistoryData();
    });
  }

  @override
  void dispose() {
    // Cancel the timer to prevent memory leaks.
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchRideHistoryData() async {
     // Reset selection state on fetch
    setState(() {
      _selectedRowIndex = null;
      _pendingAction = null; // Also reset pending action on refresh
      isLoading = true;
    });
    try {
      // Select all columns from 'rideHistory'
      final data = await supabase.from('rideHistory').select('*');
      // Debug: verify data retrieval
      final List listData = data as List;
      if (mounted) { // Check if the widget is still mounted
        setState(() {
          rideHistoryData = listData.cast<Map<String, dynamic>>();
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

  // --- Action Handlers (Placeholders) ---
  void _handleDeleteRideHistory(Map<String, dynamic> selectedRideData) {
    _showInfoSnackBar('Delete Ride History functionality not yet implemented.');
    // Possibly call fetchRideHistoryData() again after deletion
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
          // Main content: loading indicator, "No data found" message, or the data table.
          Center( // Center the table content
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : rideHistoryData.isEmpty
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
                              DataColumn(label: Text('Ride ID')),
                              DataColumn(label: Text('Vehicle ID')),
                              DataColumn(label: Text('Passenger ID')),
                              DataColumn(label: Text('Route ID')),
                              DataColumn(label: Text('Ride Status')),
                              DataColumn(label: Text('Passenger Type')),
                              DataColumn(label: Text('Pick Up Location')),
                              DataColumn(label: Text('Drop Off Location')),
                              DataColumn(label: Text('Mode Of Payment')),
                              DataColumn(label: Text('Fare')),
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Start Time')),
                              DataColumn(label: Text('End Time')),
                              DataColumn(label: Text('Duration')),
                              DataColumn(label: Text('Distance Travelled')),
                              DataColumn(label: Text('Traffic Conditions')),
                              DataColumn(label: Text('Notes')),
                              DataColumn(label: Text('Created At')),
                            ],
                            rows: rideHistoryData.asMap().entries.map((entry) { // Use asMap().entries
                              final int index = entry.key;
                              final Map<String, dynamic> ride = entry.value;
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
                                  DataCell(Text(ride['ride_id'].toString())),
                                  DataCell(Text(ride['vehicle_id']?.toString() ?? 'N/A')),
                                  DataCell(Text(ride['passenger_id']?.toString() ?? 'N/A')),
                                  DataCell(Text(ride['route_id']?.toString() ?? 'N/A')),
                                  DataCell(Text(ride['ride_status']?.toString() ?? 'N/A')),
                                  DataCell(Text(ride['passenger_type']?.toString() ?? 'N/A')),
                                  DataCell(Text(ride['pick_up_location']?.toString() ?? 'N/A')),
                                  DataCell(Text(ride['drop_off_location']?.toString() ?? 'N/A')),
                                  DataCell(Text(ride['mode_of_payment']?.toString() ?? 'N/A')),
                                  DataCell(Text(ride['fare']?.toString() ?? 'N/A')),
                                  DataCell(Text(ride['date']?.toString() ?? 'N/A')),
                                  DataCell(Text(ride['start_time']?.toString() ?? 'N/A')),
                                  DataCell(Text(ride['end_time']?.toString() ?? 'N/A')),
                                  DataCell(Text(ride['duration']?.toString() ?? 'N/A')),
                                  DataCell(Text(ride['distance_travelled']?.toString() ?? 'N/A')),
                                  DataCell(Text(ride['traffic_conditions']?.toString() ?? 'N/A')),
                                  DataCell(Text(ride['notes']?.toString() ?? 'N/A')),
                                  DataCell(Text(ride['created_at'].toString())),
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
          // Positioned Action Button (Top Right) - Only Delete
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
                  icon: const Icon(Icons.delete_outline, color: Palette.blackColor), // Icon for delete
                  tooltip: 'Actions',
                  color: Palette.whiteColor,
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Palette.greyColor, width: 1.0),
                  ),
                  offset: const Offset(0, kToolbarHeight * 0.8),
                  onSelected: (String value) {
                    if (value == 'delete') {
                       setState(() {
                          _pendingAction = value;
                        });
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete Selected'),
                      textStyle: TextStyle(color: Colors.red), // Make delete stand out
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
                visible: _pendingAction == 'delete', // Only show for delete
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
                          setState(() {
                            _pendingAction = null;
                            _selectedRowIndex = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRowSelected ? Colors.red : Colors.grey, // Red for delete confirmation
                          foregroundColor: Palette.whiteColor,
                          disabledBackgroundColor: Colors.grey[400],
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: isRowSelected
                            ? () {
                                final selectedData = rideHistoryData[_selectedRowIndex!];
                                if (_pendingAction == 'delete') {
                                  _handleDeleteRideHistory(selectedData);
                                }
                                setState(() {
                                  _pendingAction = null;
                                  _selectedRowIndex = null;
                                });
                              }
                            : null,
                        child: const Text('Continue Delete'), // Explicit button text
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
