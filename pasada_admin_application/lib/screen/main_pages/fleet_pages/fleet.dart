import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/filter_dialog.dart';
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
  List<Map<String, dynamic>> filteredVehicleData = [];
  bool isLoading = true;
  int totalVehicles = 0;
  int _onlineVehicles = 0;
  int _idlingVehicles = 0;
  int _drivingVehicles = 0;
  int _offlineVehicles = 0;
  Timer? _refreshTimer;
  
  // Filter state
  Set<String> selectedStatuses = {};
  String? selectedRouteId;
  
  // View mode: grid or list
  bool isGridView = true;

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

  void _applyFilters() {
    setState(() {
      if (selectedStatuses.isEmpty && selectedRouteId == null) {
        filteredVehicleData = List.from(vehicleData);
        return;
      }

      filteredVehicleData = vehicleData.where((vehicle) {
        String? vehicleStatus = 'Offline';
        final driverData = vehicle['driverTable'];
        if (driverData != null && driverData is List && driverData.isNotEmpty) {
          final driverMap = driverData.first as Map<String, dynamic>?;
          if (driverMap != null) {
            vehicleStatus = driverMap['driving_status'] as String?;
          }
        }

        bool statusMatch = selectedStatuses.isEmpty || selectedStatuses.contains(vehicleStatus);
        
        bool routeMatch = selectedRouteId == null || 
            vehicle['route_id']?.toString() == selectedRouteId;

        return statusMatch && routeMatch;
      }).toList();
    });
  }

  void _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return FilterDialog(
          selectedStatuses: selectedStatuses,
          selectedRouteId: selectedRouteId,
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedStatuses = result['selectedStatuses'] as Set<String>;
        selectedRouteId = result['selectedRouteId'] as String?;
        _applyFilters();
      });
    }
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
          
          // Sort vehicleData by vehicle_id
          vehicleData.sort((a, b) {
            var aId = a['vehicle_id'];
            var bId = b['vehicle_id'];
            // Handle null values
            if (aId == null) return 1;
            if (bId == null) return -1;
            // Numeric sort
            int? aNum = int.tryParse(aId.toString());
            int? bNum = int.tryParse(bId.toString());
            if (aNum != null && bNum != null) {
              return aNum.compareTo(bNum);
            }
            // Fall back to string comparison
            return aId.toString().compareTo(bId.toString());
          });
          
          _onlineVehicles = onlineCount;
          _idlingVehicles = idlingCount;
          _drivingVehicles = drivingCount;
          _offlineVehicles = offlineCount;
          totalVehicles = totalCount; 
          isLoading = false;
          
          // Apply any existing filters
          _applyFilters();
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
          filteredVehicleData = [];
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
          filteredVehicleData = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.whiteColor,
      appBar: AppBarSearch(onFilterPressed: _showFilterDialog),
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
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 16.0, 16.0),
                child: Column(
                  children: [
                    // Enhanced status summary cards with gradients and icons
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
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildVehicleStatus("Online", _onlineVehicles, Palette.greenColor, Icons.wifi),
                          _buildVerticalDivider(),
                          _buildVehicleStatus("Idling", _idlingVehicles, Palette.orangeColor, Icons.hourglass_bottom),
                          _buildVerticalDivider(),
                          _buildVehicleStatus("Driving", _drivingVehicles, Colors.blue, Icons.directions_car),
                          _buildVerticalDivider(),
                          _buildVehicleStatus("Offline", _offlineVehicles, Palette.redColor, Icons.wifi_off),
                          _buildVerticalDivider(),
                          _buildVehicleStatus("Total", totalVehicles, Palette.blackColor, Icons.directions_bus),
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
                    
                    // Vehicle list with conditional rendering based on view mode
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
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24.0,
            mainAxisSpacing: 24.0,
            childAspectRatio: 2.2,
          ),
          itemCount: filteredVehicleData.length,
          itemBuilder: (context, index) {
            final vehicle = filteredVehicleData[index];
            return _buildVehicleCard(vehicle);
          },
        );
      },
    );
  }
  
  // List view implementation
  Widget _buildListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredVehicleData.length,
      itemBuilder: (context, index) {
        final vehicle = filteredVehicleData[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildVehicleListItem(vehicle),
        );
      },
    );
  }

  // Get vehicle status from driver data
  String _getVehicleStatus(Map<String, dynamic> vehicle) {
    String vehicleStatus = 'Offline';
    final driverData = vehicle['driverTable'];
    if (driverData != null && driverData is List && driverData.isNotEmpty) {
      final driverMap = driverData.first as Map<String, dynamic>?;
      if (driverMap != null) {
        vehicleStatus = driverMap['driving_status'] as String? ?? 'Offline';
      }
    }
    return vehicleStatus;
  }
  
  // Check if vehicle is active based on status
  bool _isVehicleActive(String status) {
    return status == 'Online' || status == 'Driving' || status == 'Idling';
  }
  
  // Get status color based on vehicle status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Online':
        return Palette.greenColor;
      case 'Driving':
        return Colors.blue;
      case 'Idling':
        return Palette.orangeColor;
      default:
        return Palette.redColor;
    }
  }
  
  // Get status icon based on vehicle status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Online':
        return Icons.wifi;
      case 'Driving':
        return Icons.directions_car;
      case 'Idling':
        return Icons.hourglass_bottom;
      default:
        return Icons.wifi_off;
    }
  }
  
  // Vehicle card for grid view
  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final status = _getVehicleStatus(vehicle);
    final isActive = _isVehicleActive(status);
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
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
                        Icons.directions_bus,
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
                          "Plate: ${vehicle['plate_number'] ?? 'N/A'}",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Palette.blackColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8.0),
                        _buildVehicleInfoRow(Icons.tag, "ID: ${vehicle['vehicle_id'] ?? 'N/A'}"),
                        _buildVehicleInfoRow(Icons.group, "Capacity: ${vehicle['passenger_capacity'] ?? 'N/A'}"),
                        _buildVehicleInfoRow(Icons.route, "Route ID: ${vehicle['route_id'] ?? 'N/A'}"),
                        _buildVehicleInfoRow(
                          statusIcon,
                          "Status: $status",
                          textColor: statusColor,
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
  
  // List item for the list view
  Widget _buildVehicleListItem(Map<String, dynamic> vehicle) {
    final status = _getVehicleStatus(vehicle);
    final isActive = _isVehicleActive(status);
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
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
                        Icons.directions_bus,
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
              
              // Vehicle info
              Expanded(
                child: Row(
                  children: [
                    // Plate number and vehicle ID
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${vehicle['plate_number'] ?? 'N/A'}",
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
                            "ID: ${vehicle['vehicle_id'] ?? 'N/A'}",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.0,
                              color: Palette.blackColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Capacity
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildVehicleInfoRow(Icons.group, "${vehicle['passenger_capacity'] ?? 'N/A'} seats"),
                        ],
                      ),
                    ),
                    
                    // Route
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildVehicleInfoRow(Icons.route, "Route ${vehicle['route_id'] ?? 'N/A'}"),
                        ],
                      ),
                    ),
                    
                    // Status
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildVehicleInfoRow(
                            statusIcon,
                            status,
                            textColor: statusColor,
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

  // Helper widget for vehicle info rows with icons
  Widget _buildVehicleInfoRow(IconData icon, String text, {Color? textColor}) {
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

  // Enhanced status display with icons
  Widget _buildVehicleStatus(String title, int count, Color countColor, IconData icon) {
    return Expanded(
      child: SizedBox(
        height: 100.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: countColor, size: 20),
                SizedBox(width: 8),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: countColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                color: Palette.blackColor.withValues(alpha: 179),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to create a vertical divider between status widgets.
  Widget _buildVerticalDivider() {
    return Container(
      height: 70.0,
      width: 1.0,
      color: Palette.blackColor.withValues(alpha: 40),
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
    );
  }
}
