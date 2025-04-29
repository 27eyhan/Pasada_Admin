import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/admin_tables/edit_admin_dialog.dart';

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
  String? _pendingAction; // Reintroduce state variable for pending edit action
  int _selectionWarningCounter = 0; // Counter for selection warning

  @override
  void initState() {
    super.initState();
    fetchAdminData();
    // Use helper to start timer initially
    _startRefreshTimer(); 
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchAdminData() async {
    setState(() {
      _selectedRowIndex = null;
      _pendingAction = null; // Reset pending action on refresh
      isLoading = true;
    });
    try {
      final data = await supabase.from('adminTable').select('*');
      final List listData = data as List;
      if (mounted) {
        setState(() {
          adminData = listData.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      _showInfoSnackBar('Error fetching admin data: ${e.toString()}');
    }
  }

  void _handleEditAdmin(Map<String, dynamic> selectedAdminData) async {
    // Timer is already cancelled by the Continue button or PopupMenu

    bool? updateSuccess = false; // Variable to store dialog result
    try {
      // Await the result from showDialog
      updateSuccess = await showDialog<bool>(
        context: context,
        barrierDismissible: false, 
        builder: (BuildContext context) {
          return EditAdminDialog(
            supabase: supabase,
            adminData: selectedAdminData,
          );
        },
      );
    } finally {
      // Restart timer when the dialog is closed regardless of outcome
      _startRefreshTimer(); 
      // Fetch data only if update was successful (dialog returned true)
      if (updateSuccess == true) {
          fetchAdminData();
      }
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel(); 
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
       if (mounted) fetchAdminData();
    });
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
                            rows: adminData.asMap().entries.map((entry) {
                              final int index = entry.key;
                              final Map<String, dynamic> admin = entry.value;
                              // Determine if row selection should be active
                              final bool allowSelection = _pendingAction == 'edit';

                              return DataRow(
                                // Highlight selected row only when selection is allowed
                                selected: allowSelection && (_selectedRowIndex == index),
                                // Enable selection change only when allowed
                                onSelectChanged: allowSelection
                                  ? (bool? selected) {
                                    setState(() {
                                      if (selected ?? false) {
                                        // Show warning only if selecting a DIFFERENT row when one is already selected
                                         if (_selectedRowIndex != null && _selectedRowIndex != index) {
                                            if (_selectionWarningCounter < 3) { // Limit warnings
                                               _showInfoSnackBar('Only one admin can be selected at a time');
                                               _selectionWarningCounter++;
                                            }
                                         }
                                        _selectedRowIndex = index;
                                      } else {
                                        // Deselect if clicked again
                                        if (_selectedRowIndex == index) {
                                          _selectedRowIndex = null;
                                        }
                                      }
                                    });
                                  }
                                  : null, // Disable selection if not in edit mode
                                cells: [
                                  DataCell(Text(admin['admin_id'].toString())),
                                  DataCell(Text(admin['first_name'].toString())),
                                  DataCell(Text(admin['last_name'].toString())),
                                  DataCell(Text(admin['admin_mobile_number'].toString())),
                                  DataCell(Text(admin['admin_username']?.toString() ?? 'N/A')),
                                  DataCell(Text(admin['admin_password'].toString())),
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
                    // Always cancel timer and pending action when going back
                    _refreshTimer?.cancel();
                    _pendingAction = null;
                    _selectedRowIndex = null;
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
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
                // Use PopupMenuButton again for consistency and clear action initiation
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.edit, color: Palette.blackColor),
                  tooltip: 'Edit Admin', // Simplified tooltip
                  color: Palette.whiteColor, 
                  elevation: 8.0, 
                  shape: RoundedRectangleBorder( 
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: Palette.greyColor, width: 1.0),
                  ),
                  offset: const Offset(0, kToolbarHeight * 0.8), 
                  onSelected: (String value) {
                     // Only action is 'edit'
                    if (value == 'edit') {
                       _refreshTimer?.cancel(); // Stop timer to allow selection
                       setState(() {
                          _pendingAction = 'edit';
                          _selectedRowIndex = null; // Clear selection when starting edit mode
                          _selectionWarningCounter = 0; // Reset warning counter
                       });
                       _showInfoSnackBar('Please select an admin row to edit.');
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit Selected'),
                    ),
                     // No Add or Delete options
                  ],
                ),
              ),
            ),
          ),
          // Reintroduce Confirmation Buttons
          Positioned(
            bottom: 16.0,
            left: 0, 
            right: 0, 
            child: Center( 
              child: Visibility(
                visible: _pendingAction == 'edit', // Show only when edit is pending
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
                      // Cancel Button
                      TextButton(
                        child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                           _startRefreshTimer(); // Restart timer on cancel
                          setState(() {
                            _pendingAction = null;
                            _selectedRowIndex = null; 
                          });
                        },
                      ),
                      const SizedBox(width: 8.0),
                      // Continue Button
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
                        // Enable only if a row is selected
                        onPressed: isRowSelected 
                            ? () {
                                final selectedData = adminData[_selectedRowIndex!];
                                // Timer already cancelled by PopupMenuButton onSelected

                                // Reset state *before* calling handler 
                                // (Handler will restart timer in its finally block)
                                setState(() {
                                  _pendingAction = null;
                                  _selectedRowIndex = null;
                                });
                                
                                // Call the edit handler
                                _handleEditAdmin(selectedData); 
                              }
                            : null,
                        child: const Text('Continue Edit'), // Explicit text
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
