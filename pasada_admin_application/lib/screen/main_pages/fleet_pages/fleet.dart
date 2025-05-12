// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fleet_data.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/vehicle_tables/add_vehicle_dialog.dart';

class Fleet extends StatefulWidget {
  @override
  _FleetState createState() => _FleetState();
}

class _FleetState extends State<Fleet> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> vehicleData = [];
  bool isLoading = true;
  int totalVehicles = 0;
  int _onlineVehicles = 0;
  int _idlingVehicles = 0;
  int _drivingVehicles = 0;
  int _offlineVehicles = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    fetchVehicleData();
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchVehicleData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchVehicleData() async {
    try {
      final response = await supabase
          .from('vehicleTable')
          .select('*, driverTable!inner(driver_id, driving_status)');

      final List listData = response as List;

      int onlineCount = 0;
      int idlingCount = 0;
      int drivingCount = 0;
      int offlineCount = 0;
      int totalCount = listData.length;
      for (var item in listData) {
        final vehicle = item as Map<String, dynamic>;
        final driverData = vehicle['driverTable'];

        String? status = 'Offline';
        if (driverData != null && driverData is List && driverData.isNotEmpty) {
          final driverMap = driverData.first as Map<String, dynamic>?;
          if (driverMap != null) {
            status = driverMap['driving_status'] as String?;
          }
        }

        switch (status) {
          case 'Online':
            onlineCount++; 
            break;
          case 'Driving':
            drivingCount++; 
            break;
          case 'Idling':
            idlingCount++;
            break;
          default:
            break;
        }
      }

      offlineCount = totalCount - onlineCount - idlingCount - drivingCount;

      if (mounted) {
        setState(() {
          vehicleData = listData.cast<Map<String, dynamic>>(); 
          _onlineVehicles = onlineCount;
          _idlingVehicles = idlingCount;
          _drivingVehicles = drivingCount;
          _offlineVehicles = offlineCount;
          totalVehicles = totalCount; 
          isLoading = false;
        });
      }
    } on PostgrestException {
      if (mounted) {
        setState(() {
          isLoading = false;
          _onlineVehicles = 0;
          _idlingVehicles = 0;
          _drivingVehicles = 0;
          _offlineVehicles = 0;
          totalVehicles = 0;
          vehicleData = [];
        });
      }
    } catch (e) {

      if (mounted) {
        setState(() {
          isLoading = false;
          _onlineVehicles = 0;
          _idlingVehicles = 0;
          _drivingVehicles = 0;
          _offlineVehicles = 0;
          totalVehicles = 0;
          vehicleData = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.whiteColor,
      appBar: AppBarSearch(),
      drawer: MyDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddVehicleDialog(
              supabase: supabase,
              onVehicleActionComplete: fetchVehicleData, // Refresh the vehicle list when a new vehicle is added
            ),
          );
        },
        backgroundColor: Palette.greenColor,
        child: Icon(Icons.directions_car_outlined, color: Palette.whiteColor),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
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
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute space evenly
                        children: [
                          _buildVehicleStatus("Online", _onlineVehicles, Palette.greenColor),
                          _buildVerticalDivider(),
                          _buildVehicleStatus("Idling", _idlingVehicles, Palette.orangeColor),
                          _buildVerticalDivider(),
                          _buildVehicleStatus("Driving", _drivingVehicles, Palette.greenColor.withAlpha(200)),
                          _buildVerticalDivider(),
                          _buildVehicleStatus("Offline", _offlineVehicles, Palette.redColor),
                          _buildVerticalDivider(),
                          _buildVehicleStatus("Total", totalVehicles, Palette.blackColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32.0),
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
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 32.0,
                            mainAxisSpacing: 32.0,
                            childAspectRatio: 2,
                          ),
                          itemCount: vehicleData.length,
                          itemBuilder: (context, index) {
                            final vehicle = vehicleData[index];
                            return GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return FleetData(
                                      vehicle: vehicle,
                                      supabase: supabase,
                                      onVehicleActionComplete: fetchVehicleData,
                                    );
                                  },
                                );
                              },
                              child: Container(
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
                                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Palette.blackColor,
                                      child: Icon(
                                        Icons.directions_bus,
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
                                            "Plate: ${vehicle['plate_number'] ?? 'N/A'}",
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold,
                                              color: Palette.blackColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            "Vehicle ID: ${vehicle['vehicle_id'] ?? 'N/A'}",
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 14.0,
                                              color: Palette.blackColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            "Capacity: ${vehicle['passenger_capacity'] ?? 'N/A'}",
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 14.0,
                                              color: Palette.blackColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            "Route ID: ${vehicle['route_id'] ?? 'N/A'}",
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 14.0,
                                              color: Palette.blackColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            "Location: ${vehicle['vehicle_location'] ?? 'N/A'}",
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 14.0,
                                              color: Palette.blackColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVehicleStatus(String title, int count, Color countColor) {
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
                color: countColor,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Palette.blackColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 80.0,
      width: 1.0,
      color: Palette.blackColor.withValues(alpha: 128),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
    );
  }
}
