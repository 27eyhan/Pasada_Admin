import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:pasada_admin_application/screen/main_pages/drivers_pages/drivers_info.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Drivers extends StatefulWidget {
  @override
  _DriversState createState() => _DriversState();
}

class _DriversState extends State<Drivers> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> driverData = [];
  bool isLoading = true;

  // These values now update dynamically once data is fetched.
  int activeDrivers = 0;
  int offlineDrivers = 0;
  int totalDrivers = 0;

  Timer? _refreshTimer;  // Timer variable for refreshing the state

  @override
  void initState() {
    super.initState();
    fetchDriverData();
    // Set up a periodic timer that refreshes every 30 seconds.
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchDriverData();
    });
  }

  @override
  void dispose() {
    // Cancel the timer to prevent memory leaks.
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchDriverData() async {
    try {
      // Get all columns from 'driverTable'
      final data = await supabase.from('driverTable').select('*');
      print("Fetched driver data: $data");

      final List listData = data as List;
      setState(() {
        driverData = listData.cast<Map<String, dynamic>>();
        // Sort the list by driver_number numerically
        driverData.sort((a, b) {
          final numA = int.tryParse(a['driver_number']?.toString() ?? '0') ?? 0;
          final numB = int.tryParse(b['driver_number']?.toString() ?? '0') ?? 0;
          return numA.compareTo(numB);
        });
        totalDrivers = driverData.length;
        // Adjust these conditions based on your actual driving_status values.
        activeDrivers = driverData
            .where((d) => d["driving_status"]?.toLowerCase() == "active")
            .length;
        offlineDrivers = totalDrivers - activeDrivers;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching driver data: $e');
      setState(() {
        isLoading = false;
      });
    }
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
                // Adjust the overall column padding from the start (left side).
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 16.0, 16.0),
                child: Column(
                  children: [
                    // Container showing driver metrics.
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        color: Palette.whiteColor,
                        border: Border.all(color: Palette.blackColor, width: 1.0),
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
                          _buildDriverStatus("Drivers Active", activeDrivers),
                          _buildVerticalDivider(),
                          _buildDriverStatus("Drivers Offline", offlineDrivers),
                          _buildVerticalDivider(),
                          _buildDriverStatus("Total Drivers", totalDrivers),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    // Responsive grid view that maps over the fetched driver data.
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
                          children: List.generate(driverData.length, (index) {
                            final driver = driverData[index];
                            return GestureDetector(
                              onTap: () {
                                // Pass driver details to DriverInfo widget.
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return DriverInfo(driver: driver);
                                  },
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Palette.whiteColor,
                                  border: Border.all(
                                      color: Palette.blackColor, width: 1.0),
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
                                            "${driver['last_name']}, ${driver['first_name']}",
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold,
                                              color: Palette.blackColor,
                                            ),
                                          ),
                                          const SizedBox(height: 8.0),
                                          Text(
                                            "Driver Number: ${driver['driver_number']}",
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Palette.blackColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            "Vehicle ID: ${driver['vehicle_id']}",
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Palette.blackColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            "Status: ${driver['driving_status']}",
                                            style: TextStyle(
                                              fontFamily: 'Inter',
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
                          }),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper widget to build the status display.
  Widget _buildDriverStatus(String title, int count) {
    return Expanded(
      child: SizedBox(
        height: 100.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24.0,
                color: Palette.blackColor,
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

  // Helper to create a vertical divider between status widgets.
  Widget _buildVerticalDivider() {
    return Container(
      height: 100.0,
      width: 1.0,
      color: Palette.blackColor,
    );
  }
}
