import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Add import for PointerDeviceKind
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';

class BookingsTableScreen extends StatefulWidget {
  const BookingsTableScreen({super.key});

  @override
  _BookingsTableScreenState createState() => _BookingsTableScreenState();
}

class _BookingsTableScreenState extends State<BookingsTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> bookingsData = [];
  bool isLoading = true;
  Timer? _refreshTimer; // Timer variable for refreshing the state
  int? _selectedRowIndex; // State variable to track selected row index
  String? _pendingAction; // State variable for pending delete action
  final ScrollController _horizontalScrollController = ScrollController(); // Shared controller for horizontal scrolling

  @override
  void initState() {
    super.initState();
    fetchBookingsData();
    // Set up a periodic timer that refreshes every 30 seconds.
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchBookingsData();
    });
  }

  @override
  void dispose() {
    // Cancel the timer to prevent memory leaks.
    _refreshTimer?.cancel();
    _horizontalScrollController.dispose(); // Dispose the scroll controller
    super.dispose();
  }

  Future<void> fetchBookingsData() async {
     // Reset selection state on fetch
    setState(() {
      _selectedRowIndex = null;
      _pendingAction = null; // Also reset pending action on refresh
      isLoading = true;
    });
    try {
      // Select all columns from 'bookings'
      final data = await supabase.from('bookings').select('*');
      // Debug: verify data retrieval
      final List listData = data as List;
      if (mounted) { // Check if the widget is still mounted
        setState(() {
          bookingsData = listData.cast<Map<String, dynamic>>();
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
  void _handleDeleteBooking(Map<String, dynamic> selectedBookingData) {
    _showInfoSnackBar('Delete Booking functionality not yet implemented.');
    // Possibly call fetchBookingsData() again after deletion
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

  // Helper method to format fare with 2 decimal places
  String formatFare(dynamic fareValue) {
    if (fareValue == null) return 'N/A';
    
    try {
      // Parse the fare value to double and format with 2 decimal places
      double fare = double.parse(fareValue.toString());
      return fare.toStringAsFixed(2);
    } catch (e) {
      // Return the original value if parsing fails
      return fareValue.toString();
    }
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
          // Main content area
          Padding(
            padding: const EdgeInsets.only(top: 60.0, bottom: 60.0),
            child: isLoading 
                ? const Center(child: CircularProgressIndicator())
                : bookingsData.isEmpty
                    ? const Center(child: Text("No data found."))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.mouse,
                              PointerDeviceKind.touch,
                              PointerDeviceKind.stylus,
                              PointerDeviceKind.unknown
                            },
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Palette.whiteColor,
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(
                                color: Palette.blackColor.withValues(alpha: 128),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16.0),
                              child: Column(
                                children: [
                                  // Fixed Header Row
                                  Container(
                                    color: Palette.whiteColor,
                                    child: SingleChildScrollView(
                                      controller: _horizontalScrollController, // Use the shared controller
                                      scrollDirection: Axis.horizontal,
                                      physics: AlwaysScrollableScrollPhysics(),
                                      child: _buildHeaderRow(),
                                    ),
                                  ),
                                  // Divider
                                  Divider(height: 1, thickness: 1, color: Palette.blackColor.withAlpha(120)),
                                  // Scrollable Data Rows
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      physics: AlwaysScrollableScrollPhysics(),
                                      child: SingleChildScrollView(
                                        controller: _horizontalScrollController, // Same shared controller
                                        scrollDirection: Axis.horizontal,
                                        physics: AlwaysScrollableScrollPhysics(),
                                        child: _buildDataRows(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
          
          // Positioned back button in the top-left corner
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
          //         tooltip: 'Actions',
          //         color: Palette.whiteColor,
          //         elevation: 8.0,
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(10.0),
          //           side: BorderSide(color: Palette.greyColor, width: 1.0),
          //         ),
          //         offset: const Offset(0, kToolbarHeight * 0.8),
          //         onSelected: (String value) {
          //           if (value == 'delete') {
          //             setState(() {
          //               _pendingAction = value;
          //             });
          //           }
          //         },
          //         itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          //           const PopupMenuItem<String>(
          //             value: 'delete',
          //             child: Text('Delete Selected'),
          //             textStyle: TextStyle(color: Colors.red),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
          
          // Confirmation Buttons (Bottom Center)
          if (_pendingAction == 'delete')
            Positioned(
              bottom: 16.0,
              left: 0,
              right: 0,
              child: Center(
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
                          backgroundColor: isRowSelected ? Colors.red : Colors.grey,
                          foregroundColor: Palette.whiteColor,
                          disabledBackgroundColor: Colors.grey[400],
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: isRowSelected
                          ? () {
                              final selectedData = bookingsData[_selectedRowIndex!];
                              _handleDeleteBooking(selectedData);
                              setState(() {
                                _pendingAction = null;
                                _selectedRowIndex = null;
                              });
                            }
                          : null,
                        child: const Text('Continue Delete'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Build header row
  Widget _buildHeaderRow() {
    return Container(
      height: 40.0,
      color: Palette.whiteColor,
      child: Row(
        children: [
          _buildHeaderCell('Booking ID', 120.0),
          _buildHeaderCell('Driver ID', 120.0),
          _buildHeaderCell('Route ID', 120.0),
          _buildHeaderCell('Passenger ID', 120.0),
          _buildHeaderCell('Passenger Type', 120.0),
          _buildHeaderCell('Payment Method', 120.0),
          _buildHeaderCell('Payment Status', 120.0),
          _buildHeaderCell('Seat Type', 120.0),
          _buildHeaderCell('Ride Status', 120.0),
          _buildHeaderCell('Fare', 120.0),
          _buildHeaderCell('Pickup Address', 180.0),
          _buildHeaderCell('Dropoff Address', 180.0),
          _buildHeaderCell('Start Time', 180.0),
          _buildHeaderCell('End Time', 180.0),
        ],
      ),
    );
  }

  // Build a header cell
  Widget _buildHeaderCell(String title, double width) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Palette.blackColor,
        ),
      ),
    );
  }

  // Build data rows
  Widget _buildDataRows() {
    return Table(
      columnWidths: {
        0: FixedColumnWidth(120.0),
        1: FixedColumnWidth(120.0),
        2: FixedColumnWidth(120.0),
        3: FixedColumnWidth(120.0),
        4: FixedColumnWidth(120.0),
        5: FixedColumnWidth(120.0),
        6: FixedColumnWidth(120.0),
        7: FixedColumnWidth(120.0),
        8: FixedColumnWidth(120.0),
        9: FixedColumnWidth(120.0),
        10: FixedColumnWidth(180.0),
        11: FixedColumnWidth(180.0),
        12: FixedColumnWidth(180.0),
        13: FixedColumnWidth(180.0),
      },
      border: TableBorder(
        horizontalInside: BorderSide(
          color: Palette.blackColor.withAlpha(120),
          width: 1,
        ),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: bookingsData.asMap().entries.map((entry) {
        final int index = entry.key;
        final Map<String, dynamic> booking = entry.value;
        final bool allowSelection = _pendingAction != null;
        final bool isSelected = allowSelection && (_selectedRowIndex == index);

        return TableRow(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withAlpha(10) : Palette.whiteColor,
          ),
          children: [
            // Booking ID with selection radio
            _buildDataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
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
                  Text(booking['booking_id'].toString()),
                ],
              ),
              onTap: allowSelection ? () {
                setState(() {
                  _selectedRowIndex = index;
                });
              } : null,
            ),
            _buildDataCell(Text(booking['driver_id']?.toString() ?? 'N/A')),
            _buildDataCell(Text(booking['route_id']?.toString() ?? 'N/A')),
            _buildDataCell(Text(booking['passenger_id']?.toString() ?? 'N/A')),
            _buildDataCell(Text(booking['passenger_type']?.toString() ?? 'N/A')),
            _buildDataCell(Text(booking['payment_method']?.toString() ?? 'N/A')),
            _buildDataCell(Text(booking['payment_status']?.toString() ?? 'N/A')),
            _buildDataCell(Text(booking['seat_type']?.toString() ?? 'N/A')),
            _buildDataCell(Text(booking['ride_status']?.toString() ?? 'N/A')),
            _buildDataCell(Text(formatFare(booking['fare']))),
            _buildDataCell(Text(booking['pickup_address']?.toString() ?? 'N/A')),
            _buildDataCell(Text(booking['dropoff_address']?.toString() ?? 'N/A')),
            _buildDataCell(Text(booking['start_time']?.toString() ?? 'N/A')),
            _buildDataCell(Text(booking['end_time']?.toString() ?? 'N/A')),
          ],
        );
      }).toList(),
    );
  }

  // Build a data cell
  Widget _buildDataCell(Widget child, {VoidCallback? onTap}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 45.0,
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          alignment: Alignment.centerLeft,
          child: child is Text 
              ? Text(
                  (child).data ?? '',
                  style: (child).style,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                )
              : child,
        ),
      ),
    );
  }
}
