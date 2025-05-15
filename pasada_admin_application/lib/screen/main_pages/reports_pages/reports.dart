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
                    // Container showing summary metrics
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        color: Palette.whiteColor,
                        border: Border.all(color: Palette.greyColor, width: 1.0),
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Palette.blackColor.withValues(alpha: 128),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildSummaryItem("Total Drivers", totalDrivers.toString(), Palette.blackColor),
                          _buildVerticalDivider(),
                          _buildSummaryItem("Total Earnings", "₱${totalEarnings.toStringAsFixed(2)}", Palette.greenColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    // Driver earnings grid
                    LayoutBuilder(
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
                          crossAxisSpacing: 32.0,
                          mainAxisSpacing: 32.0,
                          childAspectRatio: 2,
                          children: driversWithFares.map((driver) {
                            return GestureDetector(
                              onTap: () => _showEarningsBreakdown(driver),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Palette.whiteColor,
                                  border: Border.all(color: Palette.greyColor, width: 1.0),
                                  borderRadius: BorderRadius.circular(10.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Palette.blackColor.withValues(alpha: 128),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Palette.blackColor,
                                      child: Icon(
                                        Icons.person,
                                        color: Palette.whiteColor,
                                        size: 28,
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
                                          ),
                                          const SizedBox(height: 8.0),
                                          Text(
                                            "Driver ID: ${driver['driver_id']}",
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Palette.blackColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            "Status: ${driver['driving_status'] ?? 'N/A'}",
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Palette.blackColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            "Total Earnings: ₱${driver['total_fare'].toStringAsFixed(2)}",
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.bold,
                                              color: Palette.blackColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  // Helper widget to build the summary display
  Widget _buildSummaryItem(String title, String value, Color valueColor) {
    return Expanded(
      child: SizedBox(
        height: 100.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24.0,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Palette.blackColor,
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
      height: 100.0,
      width: 1.0,
      color: Palette.blackColor.withValues(alpha: 128),
    );
  }
}
