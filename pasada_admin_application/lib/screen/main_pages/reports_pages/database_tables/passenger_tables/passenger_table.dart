import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/passenger_tables/passenger_dialog.dart';

class PassengerTableScreen extends StatefulWidget {
  const PassengerTableScreen({Key? key}) : super(key: key);

  @override
  _PassengerTableScreenState createState() => _PassengerTableScreenState();
}

class _PassengerTableScreenState extends State<PassengerTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> passengerData = [];
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
          print("Passenger Timer refresh triggered");
          fetchPassengerData();
       }
    });
     print("Passenger Refresh timer started");
  }

  @override
  void initState() {
    super.initState();
    fetchPassengerData();
    _startRefreshTimer(); // Start the timer
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Cancel timer
    super.dispose();
  }

  Future<void> fetchPassengerData() async {
     // Reset selection state on fetch
    setState(() {
      _selectedRowIndex = null;
      _pendingAction = null; // Also reset pending action on refresh
      isLoading = true;
    });
    try {
      // Select all columns from 'passenger'
      final data = await supabase.from('passenger').select('*');
      print("Fetched passenger data: $data"); // Debug: verify data retrieval
      final List listData = data as List;
      if (mounted) { // Check if the widget is still mounted
        setState(() {
          passengerData = listData.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching passenger data: $e');
      if (mounted) { // Check if the widget is still mounted
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // --- Action Handlers --- 
  void _handleAddPassenger() async {
    print("Add Passenger action triggered");
    // Timer cancelled by onSelected
    try {
      await showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing by tapping outside
        builder: (BuildContext context) {
          return PassengerDialog(
            supabase: supabase,
            onPassengerActionComplete: fetchPassengerData, // Pass refresh callback
            isEditMode: false,
          );
        },
      );
    } finally {
      print("Add passenger action finished, restarting timer");
      _startRefreshTimer(); // Restart timer when dialog closes
    }
  }

  void _handleEditPassenger(Map<String, dynamic> selectedPassengerData) async {
     print("Edit Passenger action triggered for: ${selectedPassengerData['id']}");
     // Timer cancelled by Continue button
    try {
       await showDialog(
         context: context,
         barrierDismissible: false,
         builder: (BuildContext context) {
           return PassengerDialog(
             supabase: supabase,
             onPassengerActionComplete: fetchPassengerData,
             passengerData: selectedPassengerData, // Pass data for editing
             isEditMode: true,
           );
         },
       );
    } finally {
       print("Edit passenger action finished, restarting timer");
       _startRefreshTimer(); // Restart timer
    }
  }

  void _handleDeletePassenger(Map<String, dynamic> selectedPassengerData) async {
    final passengerId = selectedPassengerData['id'];
    final passengerName = selectedPassengerData['display_name']?.toString() ?? 'ID: $passengerId'; // Use display_name
    print("Delete Passenger action triggered for ID: $passengerId");
    // Timer cancelled by Continue button

    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Palette.whiteColor,
          title: const Text('Confirm Deletion'),
          contentPadding: const EdgeInsets.all(24.0),
          content: Text('Are you sure you want to delete passenger $passengerName?'), // Updated content
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(false), // Return false on cancel
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true), // Return true on confirm
            ),
          ],
        );
      },
    );

    // Restart timer regardless of confirmation outcome
    print("Delete confirmation finished, restarting timer");
    _startRefreshTimer();

    if (confirmed == true) {
       print("Deletion confirmed for passenger ID: $passengerId");
       try {
         // Perform the delete operation
         await supabase
             .from('passenger')
             .delete()
             .match({'id': passengerId});

         _showInfoSnackBar('Passenger $passengerId deleted successfully.');
         fetchPassengerData(); // Refresh data after deletion

       } catch (e) {
         print('Error deleting passenger: $e');
         _showInfoSnackBar('Error deleting passenger: ${e.toString()}');
       }
    } else {
       print("Deletion cancelled for passenger ID: $passengerId");
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
          // Main content: displays a loading indicator, "No data found." message, 
          // or the DataTable with passenger data.
          Center( // Center the table content
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : passengerData.isEmpty
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
                              DataColumn(label: Text('Created At')),
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Contact Number')),
                              DataColumn(label: Text('Passenger Email')),
                              DataColumn(label: Text('Passenger Type')),
                              DataColumn(label: Text('Valid ID')),
                              DataColumn(label: Text('Last Login')),
                              DataColumn(label: Text('ID')),
                            ],
                            rows: passengerData.asMap().entries.map((entry) { // Use asMap().entries
                              final int index = entry.key;
                              final Map<String, dynamic> passenger = entry.value;
                              final bool allowSelection = _pendingAction != null;

                              return DataRow(
                                selected: allowSelection && (_selectedRowIndex == index),
                                onSelectChanged: allowSelection
                                  ? (bool? selected) {
                                    setState(() {
                                      if (selected ?? false) {
                                         // Show warning only if selecting a DIFFERENT row when one is already selected
                                         if (_selectedRowIndex != null && _selectedRowIndex != index) {
                                            if (_selectionWarningCounter < 3) { // Limit warnings
                                               _showInfoSnackBar('Only one passenger can be selected at a time');
                                               _selectionWarningCounter++;
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
                                  DataCell(Text(passenger['created_at'].toString())),
                                  DataCell(Text(passenger['display_name']?.toString() ?? 'N/A')),
                                  DataCell(Text(passenger['contact_number']?.toString() ?? 'N/A')),
                                  DataCell(Text(passenger['passenger_email']?.toString() ?? 'N/A')),
                                  DataCell(Text(passenger['passenger_type']?.toString() ?? 'N/A')),
                                  DataCell(Text(passenger['valid_id']?.toString() ?? 'N/A')),
                                  DataCell(Text(passenger['last_login']?.toString() ?? 'N/A')),
                                  DataCell(Text(passenger['id'].toString())),
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
                    _refreshTimer?.cancel(); // Cancel timer
                    print("Passenger Timer cancelled for action: $value");
                    switch (value) {
                      case 'add':
                        _handleAddPassenger(); // Will restart timer in finally
                        break;
                      case 'edit':
                      case 'delete':
                        setState(() {
                          _pendingAction = value;
                          _selectionWarningCounter = 0; // Reset counter
                           _selectedRowIndex = null; // Deselect row on new action
                        });
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'add',
                      child: Text('Add Passenger'),
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
                      boxShadow: [ BoxShadow(color: Colors.grey.withOpacity(0.5), spreadRadius: 2, blurRadius: 5) ],
                   ),
                   child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          print("Passenger Bottom cancel pressed, restarting timer");
                          _refreshTimer?.cancel();
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
                                final selectedData = passengerData[_selectedRowIndex!];
                                _refreshTimer?.cancel(); // Cancel timer before triggering action
                                print("Passenger Timer cancelled for continue button action: $_pendingAction");

                                // Store pending action locally before resetting state
                                String? actionToPerform = _pendingAction;

                                // Reset state immediately for UI responsiveness
                                setState(() {
                                  _pendingAction = null;
                                  _selectedRowIndex = null;
                                   _selectionWarningCounter = 0; // Reset counter
                                });

                                // Execute the action (handlers will restart timer)
                                if (actionToPerform == 'edit') {
                                  _handleEditPassenger(selectedData);
                                } else if (actionToPerform == 'delete') {
                                  _handleDeletePassenger(selectedData);
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
