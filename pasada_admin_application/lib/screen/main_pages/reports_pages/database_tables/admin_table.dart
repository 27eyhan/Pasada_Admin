import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';

class AdminTableScreen extends StatefulWidget {
  const AdminTableScreen({Key? key}) : super(key: key);

  @override
  _AdminTableScreenState createState() => _AdminTableScreenState();
}

class _AdminTableScreenState extends State<AdminTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> adminData = [];
  bool isLoading = true;
  Timer? _refreshTimer;
  int? _selectedRowIndex; // State variable to track selected row index
  String? _pendingAction; // State variable for pending edit/delete action

  @override
  void initState() {
    super.initState();
    fetchAdminData();
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchAdminData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchAdminData() async {
    setState(() {
      _selectedRowIndex = null;
      _pendingAction = null; // Also reset pending action on refresh
      isLoading = true;
    });
    try {
      final data = await supabase.from('adminTable').select('*');
      print("Fetched data: $data");
      final List listData = data as List;
      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          adminData = listData.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching admin data: $e');
      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // --- Action Handlers (Placeholders) ---
  void _handleAddAdmin() {
    print("Add Admin action triggered");
    _showInfoSnackBar('Add Admin functionality not yet implemented.');
  }

  void _handleEditAdmin(Map<String, dynamic> selectedAdminData) {
    print("Edit Admin action triggered for: ${selectedAdminData['admin_id']}");
    _showInfoSnackBar('Edit Admin functionality not yet implemented.');
  }

  void _handleDeleteAdmin(Map<String, dynamic> selectedAdminData) {
    print("Delete Admin action triggered for: ${selectedAdminData['admin_id']}");
    _showInfoSnackBar('Delete Admin functionality not yet implemented.');
    // Possibly call fetchAdminData() again after deletion
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
          Center(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : adminData.isEmpty
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
                              DataColumn(label: Text('Admin ID')),
                              DataColumn(label: Text('First Name')),
                              DataColumn(label: Text('Last Name')),
                              DataColumn(label: Text('Mobile Number')),
                              DataColumn(label: Text('Admin Username')),
                              DataColumn(label: Text('Password')),
                              DataColumn(label: Text('Created At')),
                            ],
                            rows: adminData.asMap().entries.map((entry) { // Use asMap().entries to get index
                              final int index = entry.key;
                              final Map<String, dynamic> admin = entry.value;
                              // Determine if row selection should be active
                              final bool allowSelection = _pendingAction != null;

                              return DataRow(
                                // Only show selection highlight if allowed AND this row is selected
                                selected: allowSelection && (_selectedRowIndex == index),
                                // Only allow selection change if allowed
                                onSelectChanged: allowSelection 
                                  ? (bool? selected) {
                                    setState(() {
                                      if (selected ?? false) {
                                        _selectedRowIndex = index;
                                      } else {
                                        // Deselect if clicked again
                                        if (_selectedRowIndex == index) {
                                          _selectedRowIndex = null;
                                        }
                                      }
                                    });
                                  } 
                                  : null, // Pass null to disable selection when no action is pending
                                cells: [
                                  DataCell(Text(admin['admin_id'].toString())),
                                  DataCell(Text(admin['first_name'].toString())),
                                  DataCell(Text(admin['last_name'].toString())),
                                  DataCell(Text(admin['admin_mobile_number'].toString())),
                                  DataCell(Text(admin['admin_username']?.toString() ?? 'N/A')),
                                  DataCell(Text(admin['admin_password'].toString())), // Careful displaying passwords
                                  DataCell(Text(admin['created_at'].toString())),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
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
          Positioned(
            top: 26.0,
            right: 26.0, // Position to the right
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Palette.blackColor, width: 1.0),
                  borderRadius: BorderRadius.circular(30.0),
                  color: Palette.whiteColor, // Match background or style as needed
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.edit, color: Palette.blackColor),
                  tooltip: 'Actions',
                  color: Palette.whiteColor, // Background color
                  elevation: 8.0, // Add elevation for shadow effect
                  shape: RoundedRectangleBorder( // Shape with rounded corners and border
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Palette.greyColor, width: 1.0), // Add black border
                  ),
                  offset: const Offset(0, kToolbarHeight * 0.8), // Position below the button
                  onSelected: (String value) {
                    switch (value) {
                      case 'add':
                        _handleAddAdmin(); // Add still happens directly
                        break;
                      case 'edit':
                      case 'delete':
                        // Set pending action instead of direct call
                        setState(() {
                          _pendingAction = value;
                        });
                        // Optional: Show snackbar immediately if no row is selected
                        // if (_selectedRowIndex == null) {
                        //   _showInfoSnackBar('Please select a row to $_pendingAction.');
                        // }
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'add',
                      child: Text('Add Admin'),
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
          // Confirmation Buttons (New)
          Positioned(
            bottom: 16.0,
            left: 0, // Align to left edge
            right: 0, // Align to right edge
            child: Center( // Center the row horizontally
              child: Visibility(
                visible: _pendingAction != null, // Show only when an action is pending
                child: Container(
                   padding: const EdgeInsets.all(8.0),
                   decoration: BoxDecoration(
                      color: Palette.whiteColor, // Semi-transparent background
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [ BoxShadow(color: Colors.grey.withValues(alpha: 128), spreadRadius: 2, blurRadius: 5) ],
                   ),
                   child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cancel Button
                      TextButton(
                        child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          setState(() {
                            _pendingAction = null;
                            _selectedRowIndex = null; // Deselect row on cancel
                          });
                        },
                      ),
                      const SizedBox(width: 8.0),
                      // Continue Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRowSelected ? Colors.green : Colors.grey, // Dynamic color
                          foregroundColor: Palette.whiteColor,
                          disabledBackgroundColor: Colors.grey[400], // Grey when disabled
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        // Disable onPressed if no row is selected
                        onPressed: isRowSelected 
                            ? () {
                                // Execute pending action
                                final selectedData = adminData[_selectedRowIndex!];
                                if (_pendingAction == 'edit') {
                                  _handleEditAdmin(selectedData);
                                } else if (_pendingAction == 'delete') {
                                  _handleDeleteAdmin(selectedData);
                                }
                                // Reset state after action
                                setState(() {
                                  _pendingAction = null;
                                  _selectedRowIndex = null;
                                });
                              }
                            : null,
                        // Capitalize action word in button text
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
