import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:pasada_admin_application/widgets/responsive_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fleet_data.dart';
import 'analytics/fleet_analytics_graph.dart';
import 'analytics/booking_frequency_graph.dart';
import 'package:provider/provider.dart';

class FleetContent extends StatefulWidget {
  final Function(String, {Map<String, dynamic>? args})? onNavigateToPage;

  const FleetContent({super.key, this.onNavigateToPage});

  @override
  _FleetContentState createState() => _FleetContentState();
}

class _FleetContentState extends State<FleetContent> {
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
    
    return Container(
      color: isDark ? Palette.darkSurface : Palette.lightSurface,
      child: ResponsiveLayout(
        minWidth: 900,
        child: Column(
          children: [
            // Main content
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: ResponsivePadding(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: ResponsiveHelper.getResponsiveAvatarRadius(context),
                                  backgroundColor: isDark
                                      ? Palette.darkSurface
                                      : Palette.lightSurface,
                                  child: Icon(
                                    Icons.directions_bus,
                                    color: isDark
                                        ? Palette.darkText
                                        : Palette.lightText,
                                    size: ResponsiveHelper.getResponsiveIconSize(context),
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                ResponsiveText(
                                  "Fleet",
                                  mobileFontSize: 24.0,
                                  tabletFontSize: 26.0,
                                  desktopFontSize: 28.0,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Palette.darkText : Palette.lightText,
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
    );
  }

  // Grid view implementation
  Widget _buildGridView() {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    
    // Get screen dimensions to calculate zoom-aware aspect ratios
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate dynamic aspect ratio based on screen size and zoom level
    double dynamicAspectRatio;
    if (isMobile) {
      dynamicAspectRatio = 2.0; // More vertical space for mobile
    } else if (isTablet) {
      // For tablets, adjust based on actual screen width
      if (screenWidth < 900) {
        dynamicAspectRatio = 1.3;
      } else if (screenWidth < 1200) {
        dynamicAspectRatio = 1.4;
      } else {
        dynamicAspectRatio = 1.5;
      }
    } else {
      // For desktop, adjust based on screen width to handle zoom levels
      if (screenWidth < 1200) {
        dynamicAspectRatio = 1.4; // 125% zoom range
      } else if (screenWidth < 1400) {
        dynamicAspectRatio = 1.5; // 133% zoom range
      } else if (screenWidth < 1600) {
        dynamicAspectRatio = 1.6; // 150% zoom range
      } else if (screenWidth < 1800) {
        dynamicAspectRatio = 1.7; // 175% zoom range
      } else {
        dynamicAspectRatio = 1.8; // Normal desktop
      }
    }
    
    return ResponsiveGrid(
      mobileColumns: 2,
      tabletColumns: 2,
      desktopColumns: 3,
      largeDesktopColumns: 4,
      crossAxisSpacing: isMobile ? 12.0 : 24.0,
      mainAxisSpacing: isMobile ? 12.0 : 24.0,
      childAspectRatio: dynamicAspectRatio,
      children: filteredVehicleData.map((vehicle) => _buildVehicleCard(vehicle)).toList(),
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
    final isMobile = ResponsiveHelper.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final status = _getVehicleStatus(vehicle);
    _isVehicleActive(status);
    final statusColor = _getStatusColor(status);

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
          padding: EdgeInsets.all(_getResponsivePadding(screenWidth, isMobile)),
          child: Stack(
            children: [
              if (!isMobile)
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
                  // Vehicle icon and plate number row
                  Row(
                    children: [
                      // Vehicle icon
                      Container(
                        padding: EdgeInsets.all(_getResponsiveSpacing(screenWidth, isMobile) * 0.5),
                        decoration: BoxDecoration(
                          color: isDark ? Palette.darkSurface : Palette.lightSurface,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: isDark ? Palette.darkBorder : Palette.lightBorder,
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          Icons.directions_bus,
                          size: _getResponsiveFontSize(screenWidth, isMobile, 'title') * 0.8,
                          color: isDark ? Palette.darkText : Palette.lightText,
                        ),
                      ),
                      SizedBox(width: _getResponsiveSpacing(screenWidth, isMobile)),
                      // Plate number as large title
                      Expanded(
                        child: Text(
                          "${vehicle['plate_number'] ?? 'N/A'}",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: _getResponsiveFontSize(screenWidth, isMobile, 'title'),
                            fontWeight: FontWeight.w700,
                            color: isDark ? Palette.darkText : Palette.lightText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _getResponsiveSpacing(screenWidth, isMobile, isVertical: true)),
                  // vehicle_id
                  Text(
                    "Fleet ID:${vehicle['vehicle_id'] ?? 'N/A'}",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: _getResponsiveFontSize(screenWidth, isMobile, 'info'),
                      color: isDark
                          ? Palette.darkTextSecondary
                          : Palette.lightTextSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: _getResponsiveSpacing(screenWidth, isMobile, isVertical: true) * 0.7),
                  // route_id
                  Text(
                    "Route: ${vehicle['route_id'] ?? 'N/A'}",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: _getResponsiveFontSize(screenWidth, isMobile, 'info'),
                      color: isDark ? Palette.darkText : Palette.lightText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: _getResponsiveSpacing(screenWidth, isMobile, isVertical: true) * 0.7),
                  // passenger_capacity
                  Text(
                    "Seats: ${vehicle['passenger_capacity'] ?? 'N/A'}",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: _getResponsiveFontSize(screenWidth, isMobile, 'info'),
                      color: isDark ? Palette.darkText : Palette.lightText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: _getResponsiveSpacing(screenWidth, isMobile, isVertical: true)),
                  Text(
                    _capitalizeFirstLetter(status),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: _getResponsiveFontSize(screenWidth, isMobile, 'status'),
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
              // Vehicle icon with status indicator
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
                          color: Colors.white,
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

  // Helper method to calculate responsive padding based on screen width and zoom level
  double _getResponsivePadding(double screenWidth, bool isMobile) {
    if (isMobile) {
      return 8.0;
    }
    
    // Adjust padding based on screen width to handle zoom levels
    if (screenWidth < 1200) {
      // 125% zoom range - reduce padding
      return 10.0;
    } else if (screenWidth < 1400) {
      // 133% zoom range - slightly more padding
      return 12.0;
    } else if (screenWidth < 1600) {
      // 150% zoom range - moderate padding
      return 14.0;
    } else if (screenWidth < 1800) {
      // 175% zoom range - more padding
      return 16.0;
    } else {
      // Normal desktop - standard padding
      return 12.0;
    }
  }

  // Helper method to calculate responsive font sizes based on screen width and zoom level
  double _getResponsiveFontSize(double screenWidth, bool isMobile, String type) {
    if (isMobile) {
      switch (type) {
        case 'title': return 14.0;
        case 'info': return 8.0;
        case 'status': return 9.0;
        default: return 10.0;
      }
    }
    
    // Adjust font sizes based on screen width to handle zoom levels
    if (screenWidth < 1200) {
      // 125% zoom range - smaller fonts
      switch (type) {
        case 'title': return 14.0;
        case 'info': return 9.0;
        case 'status': return 10.0;
        default: return 10.0;
      }
    } else if (screenWidth < 1400) {
      // 133% zoom range - slightly larger fonts
      switch (type) {
        case 'title': return 15.0;
        case 'info': return 9.5;
        case 'status': return 10.5;
        default: return 10.5;
      }
    } else if (screenWidth < 1600) {
      // 150% zoom range - moderate fonts
      switch (type) {
        case 'title': return 16.0;
        case 'info': return 10.0;
        case 'status': return 11.0;
        default: return 11.0;
      }
    } else if (screenWidth < 1800) {
      // 175% zoom range - larger fonts
      switch (type) {
        case 'title': return 17.0;
        case 'info': return 10.5;
        case 'status': return 11.5;
        default: return 11.5;
      }
    } else {
      // Normal desktop - standard fonts
      switch (type) {
        case 'title': return 18.0;
        case 'info': return 12.0;
        case 'status': return 13.0;
        default: return 12.0;
      }
    }
  }

  // Helper method to calculate responsive spacing
  double _getResponsiveSpacing(double screenWidth, bool isMobile, {bool isVertical = false}) {
    if (isMobile) return isVertical ? 4.0 : 8.0;
    
    if (screenWidth < 1200) return isVertical ? 3.0 : 6.0;
    else if (screenWidth < 1400) return isVertical ? 4.0 : 7.0;
    else if (screenWidth < 1600) return isVertical ? 5.0 : 8.0;
    else if (screenWidth < 1800) return isVertical ? 6.0 : 9.0;
    else return isVertical ? 6.0 : 8.0;
  }
}