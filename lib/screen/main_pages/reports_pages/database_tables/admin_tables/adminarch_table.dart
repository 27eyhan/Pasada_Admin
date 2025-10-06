import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';

class AdminArchTableScreen extends StatefulWidget {
  const AdminArchTableScreen({super.key});

  @override
  _AdminArchTableScreenState createState() => _AdminArchTableScreenState();
}

class _AdminArchTableScreenState extends State<AdminArchTableScreen> {
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
      // Fetch archived admins from adminTable where is_archived = true
      final data = await supabase.from('adminTable').select('*').eq('is_archived', true);
      // Debug: verify data retrieval
      final List listData = data as List;
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          archiveData = listData.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // --- Action Handlers ---
  void _handleRestoreAdmin(Map<String, dynamic> selectedArchiveData) async {
    try {
      setState(() { isLoading = true; });
      
      // Unarchive: set is_archived = false for this admin
      final adminId = selectedArchiveData['admin_id'];
      await supabase
          .from('adminTable')
          .update({'is_archived': false})
          .match({'admin_id': adminId});
      
      setState(() { isLoading = false; });
      _showInfoSnackBar('Admin restored successfully!');
      fetchArchiveData(); // Refresh the archive data
      
    } catch (e) {
      setState(() { isLoading = false; });
      _showInfoSnackBar('Error restoring admin: ${e.toString()}');
    }
  }

  void _handleDeleteAdminPermanent(Map<String, dynamic> selectedArchiveData) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permanent Delete'),
        content: Text('Are you sure you want to permanently delete this admin? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete Permanently'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        setState(() { isLoading = true; });
        
        final adminId = selectedArchiveData['admin_id'];
        final fullName = '${selectedArchiveData['first_name'] ?? ''} ${selectedArchiveData['last_name'] ?? ''}'.trim();
        
        // Permanently delete the admin
        await supabase.from('adminTable').delete().eq('admin_id', adminId);
        
        setState(() { isLoading = false; });
        _showInfoSnackBar('Admin $fullName permanently deleted!');
        fetchArchiveData(); // Refresh the archive data
        
      } catch (e) {
        setState(() { isLoading = false; });
        _showInfoSnackBar('Error permanently deleting admin: ${e.toString()}');
      }
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
          // Main content: show a progress indicator, "No data found", or the DataTable.
          Center(
            // Center the table content
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
                              DataColumn(label: Text('Archive ID')),
                              DataColumn(label: Text('Admin ID')),
                              DataColumn(label: Text('First Name')),
                              DataColumn(label: Text('Last Name')),
                              DataColumn(label: Text('Admin Mobile Number')),
                              DataColumn(label: Text('Admin Password')),
                              DataColumn(label: Text('Archived At')),
                            ],
                            rows: archiveData.asMap().entries.map((entry) {
                              // Use asMap().entries
                              final int index = entry.key;
                              final Map<String, dynamic> archive = entry.value;
                              final bool allowSelection =
                                  _pendingAction != null;

                              return DataRow(
                                selected: allowSelection &&
                                    (_selectedRowIndex == index),
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
                                      Text(archive['archive_id'].toString())),
                                  DataCell(
                                      Text(archive['admin_id'].toString())),
                                  DataCell(Text(
                                      archive['first_name']?.toString() ??
                                          'N/A')),
                                  DataCell(Text(
                                      archive['last_name']?.toString() ??
                                          'N/A')),
                                  DataCell(Text(archive['admin_mobile_number']
                                          ?.toString() ??
                                      'N/A')),
                                  DataCell(Text(
                                      archive['admin_password']?.toString() ??
                                          'N/A')), // Careful with passwords
                                  DataCell(
                                      Text(archive['archived_at'].toString())),
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
                  icon: const Icon(Icons.more_vert,
                      color: Palette
                          .blackColor), // Using different icon for archives
                  tooltip: 'Actions',
                  color: Palette.whiteColor,
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Palette.greyColor, width: 1.0),
                  ),
                  offset: const Offset(0, kToolbarHeight * 0.8),
                  onSelected: (String value) {
                    // Set pending action based on selection
                    setState(() {
                      _pendingAction = value;
                    });
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'restore',
                      child: Text('Restore Selected'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete_permanent',
                      child: Text('Delete Permanently',
                          style: TextStyle(color: Colors.red)),
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
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withValues(alpha: 128),
                          spreadRadius: 2,
                          blurRadius: 5)
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.red)),
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
                          backgroundColor: isRowSelected
                              ? (_pendingAction == 'delete_permanent'
                                  ? Colors.red
                                  : Colors.green)
                              : Colors.grey,
                          foregroundColor: Palette.whiteColor,
                          disabledBackgroundColor: Colors.grey[400],
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: isRowSelected
                            ? () {
                                final selectedData =
                                    archiveData[_selectedRowIndex!];
                                if (_pendingAction == 'restore') {
                                  _handleRestoreAdmin(selectedData);
                                } else if (_pendingAction ==
                                    'delete_permanent') {
                                  _handleDeleteAdminPermanent(selectedData);
                                }
                                setState(() {
                                  _pendingAction = null;
                                  _selectedRowIndex = null;
                                });
                              }
                            : null,
                        child: Text(
                            'Continue ${_pendingAction == 'restore' ? 'Restore' : (_pendingAction == 'delete_permanent' ? 'Permanent Delete' : _pendingAction ?? '')}'),
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
