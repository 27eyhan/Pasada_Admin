import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/driver_filter_dialog.dart';
import 'package:pasada_admin_application/screen/main_pages/drivers_pages/drivers_info.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/driver_tables/add_driver_dialog.dart';

class Drivers extends StatefulWidget {
  @override
  _DriversState createState() => _DriversState();
}

class _DriversState extends State<Drivers> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> driverData = [];
  List<Map<String, dynamic>> filteredDriverData = [];
  bool isLoading = true;

  int activeDrivers = 0;
  int offlineDrivers = 0;
  int totalDrivers = 0;

  Timer? _refreshTimer;
  
  // Filter state
  Set<String> selectedStatuses = {};
  String? selectedVehicleId;
  String sortOption = 'numeric'; // Default sorting
  
  // View mode: grid or list
  bool isGridView = true;

  @override
  void initState() {
    super.initState();
    fetchDriverData();
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchDriverData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  void _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return DriverFilterDialog(
          selectedStatuses: selectedStatuses,
          selectedVehicleId: selectedVehicleId,
          sortOption: sortOption,
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedStatuses = result['selectedStatuses'] as Set<String>;
        selectedVehicleId = result['selectedVehicleId'] as String?;
        sortOption = result['sortOption'] as String;
        _applyFilters();
      });
    }
  }
  
  void _applyFilters() {
    setState(() {
      if (selectedStatuses.isEmpty && selectedVehicleId == null) {
        // No filters applied, show all data
        filteredDriverData = List.from(driverData);
      } else {
        filteredDriverData = driverData.where((driver) {
          // Filter by status
          bool statusMatch = true;
          if (selectedStatuses.isNotEmpty) {
            final status = driver["driving_status"]?.toString() ?? "Offline";
            
            if (selectedStatuses.contains('Online')) {
              // For Online, match any of these statuses
              bool isActive = status.toLowerCase() == "driving" || 
                              status.toLowerCase() == "online" || 
                              status.toLowerCase() == "idling" || 
                              status.toLowerCase() == "active";
              
              if (selectedStatuses.contains('Offline')) {
                // If both Online and Offline are selected, show all
                statusMatch = true;
              } else {
                // Only Online is selected
                statusMatch = isActive;
              }
            } else if (selectedStatuses.contains('Offline')) {
              // Only Offline is selected
              bool isOffline = status.toLowerCase() == "offline" ||
                               status.toLowerCase() == "";
              statusMatch = isOffline;
            }
          }
          
          // Filter by vehicle ID
          bool vehicleMatch = selectedVehicleId == null || 
              driver['vehicle_id']?.toString() == selectedVehicleId;

          return statusMatch && vehicleMatch;
        }).toList();
      }
      
      // Apply sorting
      if (sortOption == 'alphabetical') {
        filteredDriverData.sort((a, b) {
          final nameA = a['full_name']?.toString() ?? '';
          final nameB = b['full_name']?.toString() ?? '';
          return nameA.compareTo(nameB);
        });
      } else { // numeric sorting is default
        filteredDriverData.sort((a, b) {
          final numA = int.tryParse(a['driver_id']?.toString() ?? '0') ?? 0;
          final numB = int.tryParse(b['driver_id']?.toString() ?? '0') ?? 0;
          return numA.compareTo(numB);
        });
      }
    });
  }

  Future<void> fetchDriverData() async {
    try {
      // Get all columns from 'driverTable'
      final data = await supabase.from('driverTable').select('*');

      final List listData = data as List;
      setState(() {
        driverData = listData.cast<Map<String, dynamic>>();
        // Sort the list by driver_number numerically
        driverData.sort((a, b) {
          final numA = int.tryParse(a['driver_id']?.toString() ?? '0') ?? 0;
          final numB = int.tryParse(b['driver_id']?.toString() ?? '0') ?? 0;
          return numA.compareTo(numB);
        });
        totalDrivers = driverData.length;
        
        // Count active drivers based on multiple status values
        activeDrivers = driverData.where((driver) {
          final status = driver["driving_status"]?.toString().toLowerCase() ?? "";
          return status == "driving" || 
                 status == "online" || 
                 status == "idling" || 
                 status == "active";
        }).length;
        
        offlineDrivers = totalDrivers - activeDrivers;
        isLoading = false;
        
        // Apply any existing filters
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        driverData = [];
        filteredDriverData = [];
      });
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
            builder: (context) => AddDriverDialog(
              supabase: supabase,
              onDriverAdded: () {
                fetchDriverData(); // Refresh the drivers list when a new driver is added
              },
            ),
          );
        },
        backgroundColor: Palette.greenColor,
        child: Icon(Icons.person_add, color: Palette.whiteColor),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                // Adjust the overall column padding from the start (left side).
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
                        children: [
                          _buildDriverStatus(
                            "Drivers Online", 
                            activeDrivers, 
                            Palette.greenColor,
                            Icons.directions_car_filled,
                          ),
                          _buildVerticalDivider(),
                          _buildDriverStatus(
                            "Drivers Offline", 
                            offlineDrivers, 
                            Palette.redColor,
                            Icons.pause_circle_outline,
                          ),
                          _buildVerticalDivider(),
                          _buildDriverStatus(
                            "Total Drivers", 
                            totalDrivers, 
                            Palette.blackColor,
                            Icons.group,
                          ),
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
                    
                    // Driver list with conditional rendering based on view mode
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
          children: List.generate(filteredDriverData.length, (index) {
            final driver = filteredDriverData[index];
            final status = driver["driving_status"]?.toString().toLowerCase() ?? "";
            final isActive = status == "driving" || status == "online" || 
                            status == "idling" || status == "active";
            
            return _buildDriverCard(driver, isActive);
          }),
        );
      },
    );
  }
  
  // List view implementation
  Widget _buildListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredDriverData.length,
      itemBuilder: (context, index) {
        final driver = filteredDriverData[index];
        final status = driver["driving_status"]?.toString().toLowerCase() ?? "";
        final isActive = status == "driving" || status == "online" || 
                        status == "idling" || status == "active";
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildDriverListItem(driver, isActive),
        );
      },
    );
  }
  
  // List item for the list view
  Widget _buildDriverListItem(Map<String, dynamic> driver, bool isActive) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return DriverInfo(driver: driver);
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
                        color: isActive ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: isActive ? Colors.green.withValues(alpha: 20) : Colors.red.withValues(alpha: 20),
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
                    
                    // Contact number
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDriverInfoRow(Icons.phone_android, "${driver['driver_number']}"),
                        ],
                      ),
                    ),
                    
                    // Vehicle
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDriverInfoRow(Icons.directions_car_outlined, "${driver['vehicle_id']}"),
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
                            isActive ? Icons.play_circle_outline : Icons.pause_circle_outline,
                            "Status: ${_capitalizeFirstLetter(driver['driving_status'] ?? 'Offline')}",
                            textColor: isActive ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Quick action buttons
              Row(
                children: [
                  _buildActionButton(Icons.phone, Colors.blue),
                  _buildActionButton(Icons.message, Colors.orange),
                  _buildActionButton(Icons.map_outlined, Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver, bool isActive) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return DriverInfo(driver: driver);
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
                    color: isActive ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isActive ? Colors.green.withValues(alpha: 20) : Colors.red.withValues(alpha: 20),
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
                        _buildDriverInfoRow(Icons.phone_android, "${driver['driver_number']}"),
                        _buildDriverInfoRow(Icons.directions_car_outlined, "Vehicle: ${driver['vehicle_id']}"),
                        _buildDriverInfoRow(
                          isActive ? Icons.play_circle_outline : Icons.pause_circle_outline,
                          "Status: ${_capitalizeFirstLetter(driver['driving_status'] ?? 'Offline')}",
                          textColor: isActive ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Quick action buttons
              Positioned(
                right: 4,
                bottom: 8,
                child: Row(
                  children: [
                    _buildActionButton(Icons.phone, Colors.blue),
                    _buildActionButton(Icons.message, Colors.orange),
                    _buildActionButton(Icons.map_outlined, Colors.green),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for action buttons
  Widget _buildActionButton(IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 20),
            blurRadius: 3,
            spreadRadius: 0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: Colors.white),
        onPressed: () {
          // Action button functionality would go here
        },
        constraints: BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
        splashRadius: 18,
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

  Widget _buildDriverStatus(String title, int count, Color countColor, IconData icon) {
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
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: countColor,
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

  // Helper to create a vertical divider between status widgets.
  Widget _buildVerticalDivider() {
    return Container(
      height: 70.0,
      width: 1.0,
      color: Palette.blackColor.withValues(alpha: 40),
    );
  }
  
  // Helper method to capitalize first letter
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
