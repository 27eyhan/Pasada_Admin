import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:pasada_admin_application/widgets/responsive_layout.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/passenger_tables/passenger_dialog.dart';

class PassengerTableScreen extends StatefulWidget {
  const PassengerTableScreen({super.key});

  @override
  _PassengerTableScreenState createState() => _PassengerTableScreenState();
}

class _PassengerTableScreenState extends State<PassengerTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> passengerData = [];
  bool isLoading = true;
  Timer? _refreshTimer; // Timer variable for refreshing the state
  int? _selectedRowIndex; // State variable to track selected row index
  String? _pendingAction; // State variable for pending edit action

  // Function to start the periodic refresh timer
  void _startRefreshTimer() {
    _refreshTimer?.cancel(); // Cancel any existing timer
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
       if (mounted) { // Check if mounted before fetching
          fetchPassengerData();
       }
    });
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
      final List listData = data as List;
      if (mounted) { // Check if the widget is still mounted
        setState(() {
          passengerData = listData.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) { // Check if the widget is still mounted
        setState(() {
          isLoading = false;
        });
      }
      _showInfoSnackBar('Error fetching passenger data: ${e.toString()}');
    }
  }

  // --- Action Handlers --- 
  void _handleEditPassenger(Map<String, dynamic> selectedPassengerData) async {
     // Timer is cancelled by Continue button
    try {
       // Await result from dialog (though currently PassengerDialog doesn't return bool)
       await showDialog(
         context: context,
         barrierDismissible: false,
         builder: (BuildContext context) {
           return PassengerDialog(
             supabase: supabase,
             // Pass fetchPassengerData directly
             onPassengerActionComplete: fetchPassengerData, 
             passengerData: selectedPassengerData, 
             isEditMode: true,
           );
         },
       );
       // We assume success if dialog closes without error, fetch is called by callback
    } catch (e) {
      // Handle potential errors showing the dialog itself
       _showInfoSnackBar('Error opening edit dialog: ${e.toString()}');
    } finally {
       // Ensure timer is restarted regardless of dialog outcome
       _startRefreshTimer(); 
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
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : passengerData.isEmpty
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
                            columnSpacing: ResponsiveHelper.isMobile(context) ? 15.0 : 50.0,
                            horizontalMargin: ResponsiveHelper.isMobile(context) ? 6.0 : 8.0,
                            headingRowHeight: ResponsiveHelper.isMobile(context) ? 35.0 : 40.0,
                            dataRowMinHeight: ResponsiveHelper.isMobile(context) ? 30.0 : 35.0,
                            dataRowMaxHeight: ResponsiveHelper.isMobile(context) ? 40.0 : 45.0,
                            showCheckboxColumn: false,
                            columns: [
                              DataColumn(label: ResponsiveText('Created At', 
                                mobileFontSize: 12.0, 
                                tabletFontSize: 13.0, 
                                desktopFontSize: 14.0, 
                                fontWeight: FontWeight.bold)),
                              DataColumn(label: ResponsiveText('Name', 
                                mobileFontSize: 12.0, 
                                tabletFontSize: 13.0, 
                                desktopFontSize: 14.0, 
                                fontWeight: FontWeight.bold)),
                              DataColumn(label: ResponsiveText('Contact Number', 
                                mobileFontSize: 12.0, 
                                tabletFontSize: 13.0, 
                                desktopFontSize: 14.0, 
                                fontWeight: FontWeight.bold)),
                              DataColumn(label: ResponsiveText('Passenger Email', 
                                mobileFontSize: 12.0, 
                                tabletFontSize: 13.0, 
                                desktopFontSize: 14.0, 
                                fontWeight: FontWeight.bold)),
                              DataColumn(label: ResponsiveText('Passenger Type', 
                                mobileFontSize: 12.0, 
                                tabletFontSize: 13.0, 
                                desktopFontSize: 14.0, 
                                fontWeight: FontWeight.bold)),
                              DataColumn(label: ResponsiveText('Valid ID', 
                                mobileFontSize: 12.0, 
                                tabletFontSize: 13.0, 
                                desktopFontSize: 14.0, 
                                fontWeight: FontWeight.bold)),
                              DataColumn(label: ResponsiveText('Last Login', 
                                mobileFontSize: 12.0, 
                                tabletFontSize: 13.0, 
                                desktopFontSize: 14.0, 
                                fontWeight: FontWeight.bold)),
                              DataColumn(label: ResponsiveText('ID', 
                                mobileFontSize: 12.0, 
                                tabletFontSize: 13.0, 
                                desktopFontSize: 14.0, 
                                fontWeight: FontWeight.bold)),
                            ],
                            rows: passengerData.asMap().entries.map((entry) { // Use asMap().entries
                              final int index = entry.key;
                              final Map<String, dynamic> passenger = entry.value;
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
                                        _selectedRowIndex = index;
                                      } else {
                                        if (_selectedRowIndex == index) {
                                          _selectedRowIndex = null;
                                        }
                                      }
                                    });
                                  }
                                  : null, // Disable selection if not in edit mode
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
                                        ResponsiveText(passenger['created_at'].toString(), 
                                          mobileFontSize: 11.0, 
                                          tabletFontSize: 12.0, 
                                          desktopFontSize: 14.0),
                                      ],
                                    )
                                  ),
                                  DataCell(ResponsiveText(passenger['display_name']?.toString() ?? 'N/A', 
                                    mobileFontSize: 11.0, 
                                    tabletFontSize: 12.0, 
                                    desktopFontSize: 14.0)),
                                  DataCell(ResponsiveText(passenger['contact_number']?.toString() ?? 'N/A', 
                                    mobileFontSize: 11.0, 
                                    tabletFontSize: 12.0, 
                                    desktopFontSize: 14.0)),
                                  DataCell(ResponsiveText(passenger['passenger_email']?.toString() ?? 'N/A', 
                                    mobileFontSize: 11.0, 
                                    tabletFontSize: 12.0, 
                                    desktopFontSize: 14.0)),
                                  DataCell(ResponsiveText(passenger['passenger_type']?.toString() ?? 'N/A', 
                                    mobileFontSize: 11.0, 
                                    tabletFontSize: 12.0, 
                                    desktopFontSize: 14.0)),
                                  DataCell(ResponsiveText(passenger['valid_id']?.toString() ?? 'N/A', 
                                    mobileFontSize: 11.0, 
                                    tabletFontSize: 12.0, 
                                    desktopFontSize: 14.0)),
                                  DataCell(ResponsiveText(passenger['last_login']?.toString() ?? 'N/A', 
                                    mobileFontSize: 11.0, 
                                    tabletFontSize: 12.0, 
                                    desktopFontSize: 14.0)),
                                  DataCell(ResponsiveText(passenger['id'].toString(), 
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
          // Positioned Action Button (Top Right) - Only Edit
          // Positioned(
          //   top: 26.0,
          //   right: 26.0,
          //   child: SafeArea(
          //     child: Container(
          //       decoration: BoxDecoration(
          //         border: Border.all(color: Palette.blackColor, width: 1.0),
          //         borderRadius: BorderRadius.circular(30.0),
          //         color: Palette.whiteColor,
          //       ),
          //       child: PopupMenuButton<String>(
          //         icon: const Icon(Icons.edit, color: Palette.blackColor),
          //         tooltip: 'Edit Passenger', // Updated tooltip
          //         color: Palette.whiteColor,
          //         elevation: 8.0,
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(10.0),
          //           side: BorderSide(color: Palette.greyColor, width: 1.0),
          //         ),
          //         offset: const Offset(0, kToolbarHeight * 0.8),
          //         onSelected: (String value) {
          //           // Only action is 'edit'
          //           if (value == 'edit') {
          //              _refreshTimer?.cancel(); // Stop timer to allow selection
          //              setState(() {
          //                 _pendingAction = 'edit';
          //                 _selectedRowIndex = null; // Clear selection
          //              });
          //              _showInfoSnackBar('Please select a passenger row to edit.');
          //           } // No other actions
          //         },
          //         itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          //           // Only show Edit Selected
          //           const PopupMenuItem<String>(
          //             value: 'edit',
          //             child: Text('Edit Selected'),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
           // Confirmation Buttons (Bottom Center)
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
                        onPressed: isRowSelected
                            ? () {
                                final selectedData = passengerData[_selectedRowIndex!];
                                _refreshTimer?.cancel(); // Cancel timer before triggering action

                                // Reset state immediately 
                                setState(() {
                                  _pendingAction = null;
                                  _selectedRowIndex = null;
                                });

                                // Execute the edit action (handler will restart timer)
                                _handleEditPassenger(selectedData);
                                
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
        ],
      ),
    );
  }
}
