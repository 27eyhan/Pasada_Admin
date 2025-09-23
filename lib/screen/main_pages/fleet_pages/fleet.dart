import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/filter_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fleet_data.dart';
import 'analytics/fleet_analytics_graph.dart';
import 'analytics/booking_frequency_graph.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/vehicle_tables/add_vehicle_dialog.dart';
import 'package:provider/provider.dart';

class Fleet extends StatefulWidget {
  const Fleet({super.key});

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

        bool statusMatch = selectedStatuses.isEmpty ||
            selectedStatuses.contains(vehicleStatus);

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
          .select('*, driverTable!left(driver_id, driving_status, full_name)');

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
          case 'online':
            onlineCount++;
            break;
          case 'driving':
            drivingCount++;
            break;
          case 'idling':
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
          vehicleData.sort((a, b) {
            var aId = a['vehicle_id'];
            var bId = b['vehicle_id'];
            if (aId == null) return 1;
            if (bId == null) return -1;
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final double screenWidth = MediaQuery.of(context)
        .size
        .width
        .clamp(600.0, double.infinity)
        .toDouble();
    final double horizontalPadding = screenWidth * 0.05;
    
    return Scaffold(
      backgroundColor: isDark ? Palette.darkSurface : Palette.lightSurface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          const double minBodyWidth = 900;
          final double effectiveWidth = constraints.maxWidth < minBodyWidth
              ? minBodyWidth
              : constraints.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: minBodyWidth),
              child: SizedBox(
                width: effectiveWidth,
                child: Row(
                  children: [
                    SizedBox(
                      width: 280,
                      child: MyDrawer(),
                    ),
                    // Main content area
                    Expanded(
                      child: Column(
                        children: [
                          // App bar in the main content area
                          AppBarSearch(onFilterPressed: _showFilterDialog),
                          // Main content
                          Expanded(
                            child: isLoading
                                ? Center(child: CircularProgressIndicator())
                                : SingleChildScrollView(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 24.0,
                                        horizontal: horizontalPadding,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isDark
                                          ? Palette.darkSurface
                                          : Palette.lightSurface,
                                      child: Icon(
                                        Icons.directions_bus,
                                        color: isDark
                                            ? Palette.darkText
                                            : Palette.lightText,
                                      ),
                                    ),
                                    const SizedBox(width: 12.0),
                                    Text(
                                      "Fleet",
                                      style: TextStyle(
                                        fontSize: 28.0,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Palette.darkText
                                            : Palette.lightText,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                                const SizedBox(height: 24.0),
                                // Booking frequency graph
                                BookingFrequencyGraph(days: 14),
                                const SizedBox(height: 24.0),
                                // Traffic graph
                                FleetAnalyticsGraph(routeId: selectedRouteId),
                                const SizedBox(height: 24.0),
                                // Status metrics container with separators
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? Palette.darkCard : Palette.lightCard,
                                    borderRadius: BorderRadius.circular(12.0),
                                    border: Border.all(
                                      color: isDark ? Palette.darkBorder : Palette.lightBorder,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.black.withValues(alpha: 0.08)
                                            : Colors.grey.withValues(alpha: 0.08),
                                        spreadRadius: 1,
                                        blurRadius: 10,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(20.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildCompactMetric(
                                          'All Vehicles',
                                          totalVehicles,
                                          isDark ? Palette.darkText : Palette.lightText,
                                        ),
                                      ),
                                      _buildVerticalSeparator(isDark),
                                      Expanded(
                                        child: _buildCompactMetric(
                                          'Online',
                                          _onlineVehicles,
                                          isDark ? Palette.darkText : Palette.lightText,
                                        ),
                                      ),
                                      _buildVerticalSeparator(isDark),
                                      Expanded(
                                        child: _buildCompactMetric(
                                          'Idling',
                                          _idlingVehicles,
                                          isDark ? Palette.darkText : Palette.lightText,
                                        ),
                                      ),
                                      _buildVerticalSeparator(isDark),
                                      Expanded(
                                        child: _buildCompactMetric(
                                          'Driving',
                                          _drivingVehicles,
                                          isDark ? Palette.darkText : Palette.lightText,
                                        ),
                                      ),
                                      _buildVerticalSeparator(isDark),
                                      Expanded(
                                        child: _buildCompactMetric(
                                          'Offline',
                                          _offlineVehicles,
                                          isDark ? Palette.darkText : Palette.lightText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24.0),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? Palette.darkCard : Palette.lightCard,
                                      border: Border.all(
                                        color: isDark ? Palette.darkBorder : Palette.lightBorder,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.grid_view,
                                            size: 18,
                                            color: isGridView
                                                ? (isDark ? Palette.darkText : Palette.lightText)
                                                : (isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
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
                                            size: 18,
                                            color: !isGridView
                                                ? (isDark ? Palette.darkText : Palette.lightText)
                                                : (isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
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
                                ),
                                const SizedBox(height: 16.0),
                                isGridView ? _buildGridView() : _buildListView(),

                                const SizedBox(height: 8.0),
                              ],
                            ),
                          ),
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
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddVehicleDialog(
              supabase: supabase,
              onVehicleActionComplete:
                  fetchVehicleData,
            ),
          );
        },
        backgroundColor: Palette.lightPrimary,
        child: Icon(Icons.directions_car_outlined, color: Colors.white),
      ),
    );
  }

  // Grid view implementation
  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth >= 900) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 600) {
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
    switch (status.toLowerCase()) {
      case 'online':
        return Palette.lightSuccess;
      case 'driving':
        return Palette.lightSuccess;
      case 'idling':
        return Palette.lightWarning;
      default:
        return Palette.lightError;
    }
  }

  

  // Vehicle card for grid view
  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final status = _getVehicleStatus(vehicle);
    _isVehicleActive(status);
    final statusColor = _getStatusColor(status);
    // Note: icon is used in list view; grid card shows a minimal status chip

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
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Palette.darkCard : Palette.lightCard,
            border: Border.all(
                color: isDark 
                    ? Palette.darkBorder.withValues(alpha: 77)
                    : Palette.lightBorder.withValues(alpha: 77), 
                width: 1.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Stack(
            children: [
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plate number as large title
                  Text(
                    "${vehicle['plate_number'] ?? 'N/A'}",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Palette.darkText : Palette.lightText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6.0),
                  // vehicle_id
                  Text(
                    "Fleet ID:${vehicle['vehicle_id'] ?? 'N/A'}",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.0,
                      color: isDark
                          ? Palette.darkTextSecondary
                          : Palette.lightTextSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  // route_id
                  Text(
                    "Route: ${vehicle['route_id'] ?? 'N/A'}",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.0,
                      color: isDark ? Palette.darkText : Palette.lightText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  // passenger_capacity
                  Text(
                    "Seats: ${vehicle['passenger_capacity'] ?? 'N/A'}",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.0,
                      color: isDark ? Palette.darkText : Palette.lightText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    _capitalizeFirstLetter(status),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                    overflow: TextOverflow.ellipsis,
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final status = _getVehicleStatus(vehicle);
    _isVehicleActive(status);
    final statusColor = _getStatusColor(status);
    // Icon mapping available via _getStatusIcon(status) if needed for future UI

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
            color: isDark ? Palette.darkCard : Palette.lightCard,
            border: Border.all(
                color: isDark 
                    ? Palette.darkBorder.withValues(alpha: 77)
                    : Palette.lightBorder.withValues(alpha: 77), 
                width: 1.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 18.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with status indicator
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF38CE7C), Color(0xFFDDCC34)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.transparent,
                      child: Icon(Icons.directions_bus,
                          color: isDark ? Palette.darkText : Palette.lightText,
                          size: 20),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16.0),
              // Text block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${vehicle['plate_number'] ?? 'N/A'}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Palette.darkText : Palette.lightText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      "Fleet ID:${vehicle['vehicle_id'] ?? 'N/A'}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.0,
                        color: isDark
                            ? Palette.darkTextSecondary
                            : Palette.lightTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      "${vehicle['passenger_capacity'] ?? 'N/A'} seats, Route ${vehicle['route_id'] ?? 'N/A'}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.0,
                        color: isDark ? Palette.darkText : Palette.lightText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              // Status at the end
              Text(
                _capitalizeFirstLetter(status),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  

  

  // Helper method to capitalize first letter
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Compact metric item: uppercase label above value (Resend-like)
  Widget _buildCompactMetric(String label, int value, Color valueColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.0,
            letterSpacing: 0.6,
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          value.toString(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22.0,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // Vertical separator for status metrics
  Widget _buildVerticalSeparator(bool isDark) {
    return Container(
      height: 40.0,
      width: 1.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: isDark ? Palette.darkDivider : Palette.lightDivider,
        borderRadius: BorderRadius.circular(0.5),
      ),
    );
  }
}
