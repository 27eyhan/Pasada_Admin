import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';

class PassengerArchTableScreen extends StatefulWidget {
  const PassengerArchTableScreen({super.key});

  @override
  _PassengerArchTableScreenState createState() => _PassengerArchTableScreenState();
}

class _PassengerArchTableScreenState extends State<PassengerArchTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> archiveData = [];
  bool isLoading = true;
  Timer? _refreshTimer; // Timer variable for refreshing the state
  int? _selectedRowIndex; // State variable to track selected row index
  String? _pendingAction; // State variable for pending restore/delete action

  @override
  void initState() {
    super.initState();
    fetchArchiveData();
    // Set up a periodic timer that refreshes every 30 seconds.
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchArchiveData();
    });
  }

  @override
  void dispose() {
    // Cancel the timer to prevent memory leaks.
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchArchiveData() async {
     // Reset selection state on fetch
    setState(() {
      _selectedRowIndex = null;
      _pendingAction = null; // Also reset pending action on refresh
      isLoading = true;
    });
    try {
      // Select all columns from the 'passengerArchives' table.
      // ********** Make sure 'passengerArchives' table exists in Supabase **********
      final data = await supabase.from('passengerArchives').select('*');
      // Debug: verify data retrieval
      final List listData = data as List;
      if (mounted) { // Check if the widget is still mounted
        setState(() {
          archiveData = listData.cast<Map<String, dynamic>>();
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
   void _handleRestorePassenger(Map<String, dynamic> selectedArchiveData) {
    // Adjust key if needed
    _showInfoSnackBar('Restore Passenger functionality not yet implemented.');
    // Possibly call fetchArchiveData() again after restoration
  }

  void _handleDeletePassengerPermanent(Map<String, dynamic> selectedArchiveData) {
    // Adjust key if needed
    _showInfoSnackBar('Permanent Delete Passenger functionality not yet implemented.');
    // Possibly call fetchArchiveData() again after deletion
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
          // Main content: loading indicator, "No data found.", or the DataTable.
          Center( // Center the table content
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : archiveData.isEmpty
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
                              // ********** Adjust columns based on your passengerArchives table **********
                              DataColumn(label: Text('Archive ID')),
                              DataColumn(label: Text('Passenger ID')),
                              DataColumn(label: Text('First Name')),
                              DataColumn(label: Text('Last Name')),
                              DataColumn(label: Text('Contact Number')),
                              DataColumn(label: Text('Passenger Email')),
                              DataColumn(label: Text('Archived At')),
                            ],
                            rows: archiveData.asMap().entries.map((entry) { // Use asMap().entries
                              final int index = entry.key;
                              final Map<String, dynamic> archive = entry.value;
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
                                   // ********** Adjust keys based on your passengerArchives table **********
                                  DataCell(Text(archive['archive_id']?.toString() ?? 'N/A')),
                                  DataCell(Text(archive['passenger_id']?.toString() ?? 'N/A')),
                                  DataCell(Text(archive['first_name']?.toString() ?? 'N/A')),
                                  DataCell(Text(archive['last_name']?.toString() ?? 'N/A')),
                                  DataCell(Text(archive['contact_number']?.toString() ?? 'N/A')),
                                  DataCell(Text(archive['passenger_email']?.toString() ?? 'N/A')),
                                  DataCell(Text(archive['archived_at']?.toString() ?? 'N/A')),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
          // Positioned back button in the top-left corner.
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
                  icon: const Icon(Icons.more_vert, color: Palette.blackColor), // Icon for archive actions
                  tooltip: 'Actions',
                  color: Palette.whiteColor,
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Palette.greyColor, width: 1.0),
                  ),
                  offset: const Offset(0, kToolbarHeight * 0.8),
                  onSelected: (String value) {
                    setState(() {
                      _pendingAction = value;
                    });
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'restore',
                      child: Text('Restore Selected'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete_permanent',
                      textStyle: TextStyle(color: Colors.red),
                      child: Text('Delete Permanently'),
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
                          setState(() {
                            _pendingAction = null;
                            _selectedRowIndex = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                           backgroundColor: isRowSelected ? (_pendingAction == 'delete_permanent' ? Colors.red : Colors.green) : Colors.grey,
                          foregroundColor: Palette.whiteColor,
                          disabledBackgroundColor: Colors.grey[400],
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: isRowSelected
                            ? () {
                                final selectedData = archiveData[_selectedRowIndex!];
                                if (_pendingAction == 'restore') {
                                  _handleRestorePassenger(selectedData);
                                } else if (_pendingAction == 'delete_permanent') {
                                  _handleDeletePassengerPermanent(selectedData);
                                }
                                setState(() {
                                  _pendingAction = null;
                                  _selectedRowIndex = null;
                                });
                              }
                            : null,
                        child: Text('Continue ${_pendingAction == 'restore' ? 'Restore' : (_pendingAction == 'delete_permanent' ? 'Permanent Delete' : _pendingAction ?? '')}'),
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
