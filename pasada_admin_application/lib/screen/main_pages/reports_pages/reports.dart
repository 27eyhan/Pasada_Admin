import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/reports_chat.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class Reports extends StatefulWidget {
  @override
  _ReportsState createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> driversWithFares = [];
  Map<int, Map<String, dynamic>> driverEarningsBreakdown = {};
  bool isLoading = true;
  
  // Summary statistics
  int totalDrivers = 0;
  double totalEarnings = 0;
  
  // View mode: grid or list
  bool isGridView = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Fetch drivers data
      final driversResponse = await supabase.from('driverTable').select('driver_id, full_name, driver_number, vehicle_id, driving_status');
      final List driversData = driversResponse as List;
      final drivers = driversData.cast<Map<String, dynamic>>();
      
      // Fetch bookings data with assigned_at field
      final bookingsResponse = await supabase.from('bookings').select('driver_id, fare, assigned_at');
      final List bookingsData = bookingsResponse as List;
      final bookings = bookingsData.cast<Map<String, dynamic>>();
      
      // Calculate total fares for each driver
      final driverFares = <int, double>{};
      final breakdownByDriver = <int, Map<String, dynamic>>{};
      double sumTotal = 0;
      
      // Get current date for weekly and monthly calculations
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      for (var booking in bookings) {
        final driverId = booking['driver_id'];
        if (driverId != null) {
          final fare = double.tryParse(booking['fare']?.toString() ?? '0') ?? 0;
          
          // Update total fare
          driverFares[driverId] = (driverFares[driverId] ?? 0) + fare;
          sumTotal += fare;
          
          // Initialize breakdown map if needed
          if (!breakdownByDriver.containsKey(driverId)) {
            breakdownByDriver[driverId] = {
              'weekly': 0.0,
              'monthly': 0.0,
              'weekly_bookings': [],
              'monthly_bookings': [],
              'all_bookings': [],
            };
          }
          
          // Add booking to all bookings list
          var assignedAt = booking['assigned_at'];
          DateTime? bookingDate;
          
          if (assignedAt != null) {
            try {
              bookingDate = DateTime.parse(assignedAt.toString());
              
              // Store booking details
              final bookingDetail = {
                'fare': fare,
                'date': bookingDate,
                'formatted_date': DateFormat('MMM dd, yyyy').format(bookingDate),
              };
              
              breakdownByDriver[driverId]!['all_bookings'].add(bookingDetail);
              
              // Check if booking is within current week
              if (bookingDate.isAfter(startOfWeek) || 
                  bookingDate.isAtSameMomentAs(startOfWeek)) {
                breakdownByDriver[driverId]!['weekly'] = 
                    (breakdownByDriver[driverId]!['weekly'] as double) + fare;
                breakdownByDriver[driverId]!['weekly_bookings'].add(bookingDetail);
              }
              
              // Check if booking is within current month
              if (bookingDate.isAfter(startOfMonth) || 
                  bookingDate.isAtSameMomentAs(startOfMonth)) {
                breakdownByDriver[driverId]!['monthly'] = 
                    (breakdownByDriver[driverId]!['monthly'] as double) + fare;
                breakdownByDriver[driverId]!['monthly_bookings'].add(bookingDetail);
              }
            } catch (e) {
              print('Error parsing date: $e');
            }
          }
        }
      }
      
      // Combine driver info with their total fares
      final result = drivers.map((driver) {
        final driverId = driver['driver_id'];
        return {
          'driver_id': driverId,
          'full_name': driver['full_name'],
          'driver_number': driver['driver_number'],
          'vehicle_id': driver['vehicle_id'],
          'driving_status': driver['driving_status'],
          'total_fare': driverFares[driverId] ?? 0.0,
          'weekly_earnings': breakdownByDriver[driverId]?['weekly'] ?? 0.0,
          'monthly_earnings': breakdownByDriver[driverId]?['monthly'] ?? 0.0,
        };
      }).toList();
      
      // Sort the drivers by driver_id in numerical order
      result.sort((a, b) {
        final idA = a['driver_id'] is int ? a['driver_id'] : int.tryParse(a['driver_id'].toString()) ?? 0;
        final idB = b['driver_id'] is int ? b['driver_id'] : int.tryParse(b['driver_id'].toString()) ?? 0;
        return idA.compareTo(idB);
      });
      
      setState(() {
        driversWithFares = result;
        driverEarningsBreakdown = breakdownByDriver;
        totalDrivers = result.length;
        totalEarnings = sumTotal;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showEarningsBreakdown(Map<String, dynamic> driver) {
    final driverId = driver['driver_id'];
    final breakdown = driverEarningsBreakdown[driverId];
    
    if (breakdown == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No earnings data available for this driver'))
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EarningsBreakdownDialog(
          driver: driver,
          breakdown: breakdown,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.whiteColor,
      appBar: AppBarSearch(),
      drawer: MyDrawer(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 16.0, 16.0),
                child: Column(
                  children: [
                    // Enhanced summary metrics cards
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.grey.shade100],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Palette.greyColor.withValues(alpha: 77), width: 1.0),
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [
                          BoxShadow(
                            color: Palette.blackColor.withValues(alpha: 20),
                            spreadRadius: 0,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildSummaryItem("Total Drivers", totalDrivers.toString(), Palette.blackColor, Icons.people),
                          _buildVerticalDivider(),
                          _buildSummaryItem("Total Earnings", "₱${totalEarnings.toStringAsFixed(2)}", Palette.greenColor, Icons.account_balance_wallet),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    
                    // View toggle buttons (Grid/List)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.grid_view, 
                                  color: isGridView ? Palette.blackColor : Palette.greyColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isGridView = true;
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.view_list, 
                                  color: !isGridView ? Palette.blackColor : Palette.greyColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isGridView = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16.0),
                    
                    // Driver earnings with conditional rendering based on view mode
                    isGridView ? _buildGridView() : _buildListView(),
                  ],
                ),
              ),
            ),
    );
  }
  
  // Grid view implementation
  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth >= 1200) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 800) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 24.0,
          mainAxisSpacing: 24.0,
          childAspectRatio: 2.2,
          children: driversWithFares.map((driver) {
            return _buildDriverEarningsCard(driver);
          }).toList(),
        );
      },
    );
  }
  
  // List view implementation
  Widget _buildListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: driversWithFares.length,
      itemBuilder: (context, index) {
        final driver = driversWithFares[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildDriverEarningsListItem(driver),
        );
      },
    );
  }
  
  // Driver earnings card for grid view
  Widget _buildDriverEarningsCard(Map<String, dynamic> driver) {
    final status = driver['driving_status'] ?? 'Offline';
    final isActive = status.toLowerCase() == 'online' || 
                     status.toLowerCase() == 'driving' || 
                     status.toLowerCase() == 'idling' || 
                     status.toLowerCase() == 'active';
    final statusColor = isActive ? Colors.green : Colors.red;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => _showEarningsBreakdown(driver),
        borderRadius: BorderRadius.circular(15.0),
        child: Container(
          decoration: BoxDecoration(
            color: Palette.whiteColor,
            border: Border.all(color: Palette.greyColor.withValues(alpha: 77), width: 1.0),
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [
              BoxShadow(
                color: Palette.blackColor.withValues(alpha: 20),
                spreadRadius: 0,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
          child: Stack(
            children: [
              // Status indicator dot
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 20),
                        spreadRadius: 0,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              
              Row(
                children: [
                  // Enhanced avatar with gradient background
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade700, Colors.black],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 15),
                          blurRadius: 3,
                          spreadRadius: 0,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.transparent,
                      child: Icon(
                        Icons.person,
                        color: Palette.whiteColor,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${driver['full_name'] ?? 'Unknown Driver'}",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Palette.blackColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8.0),
                        _buildDriverInfoRow(Icons.badge_outlined, "ID: ${driver['driver_id']}"),
                        _buildDriverInfoRow(
                          isActive ? Icons.play_circle_outline : Icons.pause_circle_outline,
                          "Status: $status",
                          textColor: statusColor,
                        ),
                        _buildDriverInfoRow(
                          Icons.monetization_on, 
                          "Total: ₱${driver['total_fare'].toStringAsFixed(2)}", 
                          textColor: Palette.greenColor
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Driver earnings list item for list view
  Widget _buildDriverEarningsListItem(Map<String, dynamic> driver) {
    final status = driver['driving_status'] ?? 'Offline';
    final isActive = status.toLowerCase() == 'online' || 
                     status.toLowerCase() == 'driving' || 
                     status.toLowerCase() == 'idling' || 
                     status.toLowerCase() == 'active';
    final statusColor = isActive ? Colors.green : Colors.red;
    final statusIcon = isActive ? Icons.play_circle_outline : Icons.pause_circle_outline;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => _showEarningsBreakdown(driver),
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: Palette.whiteColor,
            border: Border.all(color: Palette.greyColor.withValues(alpha: 77), width: 1.0),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Palette.blackColor.withValues(alpha: 20),
                spreadRadius: 0,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              // Avatar with status indicator
              Stack(
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade700, Colors.black],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 15),
                          blurRadius: 3,
                          spreadRadius: 0,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.transparent,
                      child: Icon(
                        Icons.person,
                        color: Palette.whiteColor,
                        size: 24,
                      ),
                    ),
                  ),
                  
                  // Status indicator
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 20),
                            spreadRadius: 0,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 16.0),
              
              // Driver info
              Expanded(
                child: Row(
                  children: [
                    // Name and ID
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${driver['full_name'] ?? 'Unknown Driver'}",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Palette.blackColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            "ID: ${driver['driver_id']}",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.0,
                              color: Palette.blackColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDriverInfoRow(
                            statusIcon,
                            status,
                            textColor: statusColor,
                          ),
                        ],
                      ),
                    ),
                    
                    // Weekly earnings
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDriverInfoRow(
                            Icons.date_range,
                            "₱${driver['weekly_earnings'].toStringAsFixed(2)}",
                            textColor: Palette.greenColor,
                          ),
                          Text(
                            "Weekly",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.0,
                              color: Palette.greyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Total earnings
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDriverInfoRow(
                            Icons.monetization_on,
                            "₱${driver['total_fare'].toStringAsFixed(2)}",
                            textColor: Palette.greenColor,
                          ),
                          Text(
                            "Total",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.0,
                              color: Palette.greyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for driver info rows with icons
  Widget _buildDriverInfoRow(IconData icon, String text, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Palette.blackColor,
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.0,
                color: textColor ?? Palette.blackColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  // Enhanced summary item with icons
  Widget _buildSummaryItem(String title, String value, Color valueColor, IconData icon) {
    return Expanded(
      child: SizedBox(
        height: 100.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: valueColor, size: 20),
                SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                color: Palette.blackColor.withValues(alpha: 179),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper to create a vertical divider
  Widget _buildVerticalDivider() {
    return Container(
      height: 70.0,
      width: 1.0,
      color: Palette.blackColor.withValues(alpha: 40),
    );
  }
}
