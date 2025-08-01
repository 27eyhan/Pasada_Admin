import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';

class AdminTableScreen extends StatefulWidget {
  const AdminTableScreen({super.key});

  @override
  _AdminTableScreenState createState() => _AdminTableScreenState();
}

class _AdminTableScreenState extends State<AdminTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> adminData = [];
  bool isLoading = true;
  Timer? _refreshTimer;
  // int? _selectedRowIndex; // State variable to track selected row index
  // String? _pendingAction; // Reintroduce state variable for pending edit action
// Counter for selection warning

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
      // _selectedRowIndex = null;
      // _pendingAction = null; // Reset pending action on refresh
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
    // final bool isRowSelected = _selectedRowIndex != null;

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
                        scrollDirection: Axis.vertical,
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
                            columnSpacing: 90.0, // Reduce column spacing
                            horizontalMargin: 12.0, // Reduce horizontal margin
                            headingRowHeight: 50.0, // Set heading row height
                            dataRowMinHeight: 40.0, // Set minimum row height
                            dataRowMaxHeight: 60.0, // Set maximum row height
                            showCheckboxColumn: false, // Remove checkbox column
                            columns: const [
                              DataColumn(
                                  label: Text('Admin ID',
                                      style: TextStyle(
                                          fontSize: 14.0,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Name',
                                      style: TextStyle(
                                          fontSize: 14.0,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Mobile',
                                      style: TextStyle(
                                          fontSize: 14.0,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Username',
                                      style: TextStyle(
                                          fontSize: 14.0,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Created At',
                                      style: TextStyle(
                                          fontSize: 14.0,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold))),
                            ],
                            rows: adminData.asMap().entries.map((entry) {
                              final Map<String, dynamic> admin = entry.value;
                              // Determine if row selection should be active
                              // final bool allowSelection = _pendingAction == 'edit';

                              return DataRow(
                                // Highlight selected row only when selection is allowed
                                // selected: allowSelection && (_selectedRowIndex == index),
                                // Enable selection change only when allowed
                                // onSelectChanged: allowSelection
                                //  ? (bool? selected) {
                                //    setState(() {
                                //      if (selected ?? false) {
                                //        // No need for warning logic with radio buttons
                                //        _selectedRowIndex = index;
                                //      } else {
                                //        // Deselect if clicked again
                                //        if (_selectedRowIndex == index) {
                                //          _selectedRowIndex = null;
                                //        }
                                //      }
                                //    });
                                //  }
                                //  : null, // Disable selection if not in edit mode
                                cells: [
                                  DataCell(
                                    // Row(
                                    //  children: [
                                    //    if (allowSelection)
                                    //      Radio<int>(
                                    //        value: index,
                                    //        groupValue: _selectedRowIndex,
                                    //        onChanged: (int? value) {
                                    //          setState(() {
                                    //            _selectedRowIndex = value;
                                    //          });
                                    //        },
                                    //      ),
                                    //    SizedBox(width: 8),
                                    Text(admin['admin_id'].toString(),
                                        style: TextStyle(fontSize: 14.0)),
                                    //  ],
                                    // )
                                  ),
                                  DataCell(Text(
                                      '${admin['first_name'] ?? ''} ${admin['last_name'] ?? ''}',
                                      style: TextStyle(fontSize: 14.0))),
                                  DataCell(Text(
                                      admin['admin_mobile_number']
                                              ?.toString() ??
                                          'N/A',
                                      style: TextStyle(fontSize: 14.0))),
                                  DataCell(Text(
                                      admin['admin_username']?.toString() ??
                                          'N/A',
                                      style: TextStyle(fontSize: 14.0))),
                                  DataCell(Text(
                                      admin['created_at']?.toString() ?? 'N/A',
                                      style: TextStyle(fontSize: 14.0))),
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
                    // _pendingAction = null;
                    // _selectedRowIndex = null;
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
          /* Commenting out PopupMenuButton since only online admin can edit itself
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
// Reset warning counter
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
          */
          /* Commenting out confirmation buttons
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
                           _startRefreshTimer(); // Restart timer on cancel
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
                      // Continue Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRowSelected ? Palette.greenColor : Colors.grey,
                          foregroundColor: Palette.whiteColor,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          elevation: 3,
                          shadowColor: isRowSelected ? Palette.greenColor.withAlpha(128) : Colors.grey.withAlpha(128),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        // Enable only if a row is selected
                        onPressed: isRowSelected 
                            ? () {
                                final selectedData = adminData[_selectedRowIndex!];
                                setState(() {
                                  _pendingAction = null;
                                  _selectedRowIndex = null;
                                });
                                
                                // Call the edit handler
                                _handleEditAdmin(selectedData); 
                              }
                            : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Continue Edit', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ), 
            ), 
          ),
          */
        ],
      ),
    );
  }
}
