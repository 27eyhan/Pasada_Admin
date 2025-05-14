import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';

class DriverArchTableScreen extends StatefulWidget {
  const DriverArchTableScreen({Key? key}) : super(key: key);

  @override
  _DriverArchTableScreenState createState() => _DriverArchTableScreenState();
}

class _DriverArchTableScreenState extends State<DriverArchTableScreen> {
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
    cleanupOldArchives();
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
      // Select all columns from the 'driverArchives' table.
      final data = await supabase.from('driverArchives').select('*');
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

  // Clean up archives older than 30 days
  Future<void> cleanupOldArchives() async {
    try {
      // Calculate the date 30 days ago
      final DateTime thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final String thirtyDaysAgoStr = thirtyDaysAgo.toIso8601String();
      
      // Delete records where archived_at is older than 30 days
      await supabase
          .from('driverArchives')
          .delete()
          .lt('archived_at', thirtyDaysAgoStr);
      
      // Refresh data after cleanup
      if (mounted) {
        fetchArchiveData();
      }
    } catch (e) {
      if (mounted) {
        _showInfoSnackBar('Error cleaning up old archives: ${e.toString()}');
      }
    }
  }

  // --- Action Handlers ---
  void _handleRestoreDriver(Map<String, dynamic> selectedArchiveData) async {
    final archiveId = selectedArchiveData['archive_id'];
    final driverId = selectedArchiveData['driver_id'];
    
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Palette.whiteColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Palette.orangeColor, width: 2),
            ),
            icon: Icon(Icons.restore, color: Palette.orangeColor, size: 48),
            title: Text(
              'Restore Driver', 
              style: TextStyle(fontWeight: FontWeight.bold, color: Palette.orangeColor),
              textAlign: TextAlign.center,
            ),
            content: Text(
              'Are you sure you want to restore this driver? This will move the driver back to the active drivers table.',
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.orangeColor,
                ),
                child: Text('Restore Driver'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );
      
      if (confirm != true) return;
      
      _showInfoSnackBar('Restoring driver...');
      
      // Extract driver data from archive to create record in driver table
      final Map<String, dynamic> driverData = {
        'driver_id': driverId,
        'full_name': selectedArchiveData['full_name'],
        'driver_number': selectedArchiveData['driver_number'],
        'vehicle_id': selectedArchiveData['last_vehicle_used'],
        'driving_status': 'Offline',
        'last_online': DateTime.now().toIso8601String(),
      };
      
      // First insert into driver table
      await supabase.from('driverTable').insert(driverData);
      
      // Then delete from archives
      await supabase.from('driverArchives').delete().eq('archive_id', archiveId);
      
      _showInfoSnackBar('Driver restored successfully!');
      fetchArchiveData();
    } catch (e) {
      _showInfoSnackBar('Error restoring driver: ${e.toString()}');
    }
  }

  void _handleDeleteDriverPermanent(Map<String, dynamic> selectedArchiveData) async {
    final archiveId = selectedArchiveData['archive_id'];
    final driverId = selectedArchiveData['driver_id'];
    
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Palette.whiteColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.red, width: 2),
            ),
            icon: Icon(Icons.delete_forever, color: Colors.red, size: 48),
            title: Text(
              'Permanent Deletion', 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            content: Text(
              'Are you sure you want to permanently delete this archived driver? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade800),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text('Delete Permanently'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );
      
      if (confirm != true) return;
      
      _showInfoSnackBar('Permanently deleting driver...');
      
      // Delete from archives table
      await supabase.from('driverArchives').delete().eq('archive_id', archiveId);
      
      _showInfoSnackBar('Driver permanently deleted.');
      fetchArchiveData();
    } catch (e) {
      _showInfoSnackBar('Error deleting driver: ${e.toString()}');
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
                            showCheckboxColumn: false,
                            columns: const [
                              DataColumn(label: Text('Archive ID')),
                              DataColumn(label: Text('Driver ID')),
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Driver Number')),
                              DataColumn(label: Text('Driver Password')),
                              DataColumn(label: Text('Last Vehicle Used')),
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
                                        Text(archive['archive_id'].toString()),
                                      ],
                                    )
                                  ),
                                  DataCell(Text(archive['driver_id']?.toString() ?? 'N/A')),
                                  DataCell(Text(archive['full_name']?.toString() ?? 'N/A')),
                                  DataCell(Text(archive['driver_number']?.toString() ?? 'N/A')),
                                  DataCell(Text(archive['driver_password']?.toString() ?? 'N/A')),
                                  DataCell(Text(archive['last_vehicle_used']?.toString() ?? 'N/A')),
                                  DataCell(Text(archive['archived_at'].toString())),
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
                      child: Text('Delete Permanently'),
                      textStyle: TextStyle(color: Colors.red),
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
                                  _handleRestoreDriver(selectedData);
                                } else if (_pendingAction == 'delete_permanent') {
                                  _handleDeleteDriverPermanent(selectedData);
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
