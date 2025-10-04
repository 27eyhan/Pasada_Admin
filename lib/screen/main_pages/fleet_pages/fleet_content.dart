import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:pasada_admin_application/widgets/responsive_layout.dart';
import 'package:pasada_admin_application/widgets/responsive_search_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fleet_data.dart';
import 'analytics/fleet_analytics_graph.dart';
import 'analytics/booking_frequency_graph.dart';
import 'package:provider/provider.dart';
import 'route_details_dialog.dart';

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
  // Grouped route summaries derived from filtered vehicles
  List<Map<String, dynamic>> filteredRouteSummaries = [];
  // All routes from official_routes with names and meta
  List<Map<String, dynamic>> allRoutes = [];
  Map<String, Map<String, dynamic>> routeIdToDetails = {};
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

  // Search state
  String searchQuery = '';

  // View mode: grid or list
  bool isGridView = true;
  // Toggle between Vehicles and Routes view
  bool showRoutes = false;

  @override
  void initState() {
    super.initState();
    fetchRoutes();
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
      filteredVehicleData = vehicleData.where((vehicle) {
        // Search filter
        bool searchMatch = true;
        if (searchQuery.isNotEmpty) {
          final plateNumber = vehicle['plate_number']?.toString().toLowerCase() ?? '';
          final vehicleId = vehicle['vehicle_id']?.toString().toLowerCase() ?? '';
          final routeId = vehicle['route_id']?.toString().toLowerCase() ?? '';
          final capacity = vehicle['passenger_capacity']?.toString().toLowerCase() ?? '';
          
          final query = searchQuery.toLowerCase();
          searchMatch = plateNumber.contains(query) ||
              vehicleId.contains(query) ||
              routeId.contains(query) ||
              capacity.contains(query);
        }

        // Status filter
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

        // Route filter
        bool routeMatch = selectedRouteId == null ||
            vehicle['route_id']?.toString() == selectedRouteId;

        return searchMatch && statusMatch && routeMatch;
      }).toList();

      // Derive route summaries for ALL routes using full vehicle dataset
      final Map<String, Map<String, dynamic>> routeIdToSummary = {};
      // Ensure all routes are present even if zero vehicles
      for (final route in allRoutes) {
        final String rid = route['officialroute_id']?.toString() ?? '';
        if (rid.isEmpty) continue;
        routeIdToSummary[rid] = {
          'route_id': rid,
          'route_name': route['route_name']?.toString() ?? 'Route $rid',
          'origin_name': route['origin_name']?.toString(),
          'destination_name': route['destination_name']?.toString(),
          'total': 0,
          'online': 0,
          'driving': 0,
          'idling': 0,
          'offline': 0,
          'vehicles': <Map<String, dynamic>>[],
        };
      }
      // Accumulate vehicles into their routes
      for (final vehicle in vehicleData) {
        final String routeId = (vehicle['route_id']?.toString() ?? '');
        if (routeId.isEmpty) continue;
        final String status = _getVehicleStatus(vehicle).toLowerCase();
        final summary = routeIdToSummary.putIfAbsent(routeId, () => {
          'route_id': routeId,
          'route_name': routeIdToDetails[routeId]?['route_name']?.toString() ?? 'Route $routeId',
          'origin_name': routeIdToDetails[routeId]?['origin_name']?.toString(),
          'destination_name': routeIdToDetails[routeId]?['destination_name']?.toString(),
          'total': 0,
          'online': 0,
          'driving': 0,
          'idling': 0,
          'offline': 0,
          'vehicles': <Map<String, dynamic>>[],
        });
        summary['total'] = (summary['total'] as int) + 1;
        if (status == 'online') summary['online'] = (summary['online'] as int) + 1;
        else if (status == 'driving') summary['driving'] = (summary['driving'] as int) + 1;
        else if (status == 'idling') summary['idling'] = (summary['idling'] as int) + 1;
        else summary['offline'] = (summary['offline'] as int) + 1;
        (summary['vehicles'] as List<Map<String, dynamic>>).add(vehicle);
      }

      filteredRouteSummaries = routeIdToSummary.values.toList()
        ..sort((a, b) {
          final aId = a['route_id']?.toString() ?? '';
          final bId = b['route_id']?.toString() ?? '';
          final int? aNum = int.tryParse(aId);
          final int? bNum = int.tryParse(bId);
          if (aNum != null && bNum != null) return aNum.compareTo(bNum);
          return aId.compareTo(bId);
        });
    });
  }

  Future<void> fetchRoutes() async {
    try {
      final data = await supabase
          .from('official_routes')
          .select('officialroute_id, route_name, origin_name, destination_name');
      final List listData = data as List;
      allRoutes = listData.cast<Map<String, dynamic>>();
      routeIdToDetails = {
        for (final r in allRoutes)
          (r['officialroute_id']?.toString() ?? ''): r
      };
      if (mounted) {
        setState(() {
          // Recompute route summaries in case vehicles were already loaded
          _applyFilters();
        });
      }
    } catch (e) {
      // silently ignore; routes will be empty
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
                            // Search bar
                            ResponsiveSearchBar(
                              hintText: 'Search vehicles by plate number, ID, route, or capacity...',
                              onSearchChanged: (query) {
                                setState(() {
                                  searchQuery = query;
                                  _applyFilters();
                                });
                              },
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
                            Row(
                                  children: [
                                // Left-aligned toggle button to switch Vehicles <-> Routes
                                OutlinedButton.icon(
                                        icon: Icon(
                                    showRoutes ? Icons.directions_bus : Icons.alt_route,
                                    size: 16,
                                          color: isDark ? Palette.darkText : Palette.lightText,
                                        ),
                                  label: Text(
                                    showRoutes ? 'Show Vehicles' : 'Show Routes',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Palette.darkText : Palette.lightText,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: isDark ? Palette.darkBorder : Palette.lightBorder),
                                    backgroundColor: isDark ? Palette.darkCard : Palette.lightCard,
                                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                  ),
                                        onPressed: () {
                                          setState(() {
                                            showRoutes = !showRoutes;
                                          });
                                        },
                                      ),
                                const Spacer(),
                                // Right-aligned grid/list view controls
                                    Container(
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
                              ],
                            ),
                            const SizedBox(height: 16.0),
                            if (showRoutes)
                              (isGridView ? _buildRouteGridView() : _buildRouteListView())
                            else
                              (isGridView ? _buildGridView() : _buildListView()),
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

  // Routes grid view implementation
  Widget _buildRouteGridView() {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;

    double dynamicAspectRatio;
    if (isMobile) {
      // Slightly taller for mobile to accommodate compact content
      dynamicAspectRatio = 2.0;
    } else if (isTablet) {
      if (screenWidth < 900) {
        dynamicAspectRatio = 1.25;
      } else if (screenWidth < 1200) {
        dynamicAspectRatio = 1.35;
      } else {
        dynamicAspectRatio = 1.45;
      }
    } else {
      if (screenWidth < 1200) {
        dynamicAspectRatio = 1.35;
      } else if (screenWidth < 1400) {
        dynamicAspectRatio = 1.45;
      } else if (screenWidth < 1600) {
        dynamicAspectRatio = 1.55;
      } else if (screenWidth < 1800) {
        dynamicAspectRatio = 1.65;
      } else {
        dynamicAspectRatio = 1.75;
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
      children: filteredRouteSummaries.map((route) => _buildRouteCard(route)).toList(),
    );
  }

  // Routes list view implementation
  Widget _buildRouteListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredRouteSummaries.length,
      itemBuilder: (context, index) {
        final route = filteredRouteSummaries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildRouteListItem(route),
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

  // Route card for grid view - mirrors vehicle card layout
  Widget _buildRouteCard(Map<String, dynamic> routeSummary) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isMobile = ResponsiveHelper.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final String routeId = routeSummary['route_id']?.toString() ?? 'N/A';
    final String routeName = routeSummary['route_name']?.toString() ?? 'Route $routeId';
    final int total = (routeSummary['total'] as int? ?? 0);
    final int online = (routeSummary['online'] as int? ?? 0);
    final int driving = (routeSummary['driving'] as int? ?? 0);
    final int idling = (routeSummary['idling'] as int? ?? 0);
    final int offline = (routeSummary['offline'] as int? ?? 0);

    // Determine dominant status color (reserved for future use)

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => RouteDetailsDialog(
            routeId: routeId,
            supabase: supabase,
            onManageRoute: () {
              Navigator.of(ctx).pop();
            },
          ),
        );
      },
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                  Icons.alt_route,
                  size: _getResponsiveFontSize(screenWidth, isMobile, 'title') * 0.8,
                  color: isDark ? Palette.darkText : Palette.lightText,
                ),
              ),
              SizedBox(width: _getResponsiveSpacing(screenWidth, isMobile)),
              Expanded(
                child: Text(
                  routeName,
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
          Text(
            'Route ID: $routeId',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: _getResponsiveFontSize(screenWidth, isMobile, 'info'),
              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: _getResponsiveSpacing(screenWidth, isMobile, isVertical: true) * 0.7),
          Text(
            'Vehicles: $total',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: _getResponsiveFontSize(screenWidth, isMobile, 'info'),
              color: isDark ? Palette.darkText : Palette.lightText,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: _getResponsiveSpacing(screenWidth, isMobile, isVertical: true) * 0.7),
          // Status row: mobile shows colored icons only (no backgrounds),
          // larger screens show chip-like counters
          isMobile
              ? Wrap(
                  spacing: _getResponsiveSpacing(screenWidth, isMobile),
                  runSpacing: _getResponsiveSpacing(screenWidth, isMobile, isVertical: true),
                  children: [
                    _buildStatusIconCountMobile(
                      icon: Icons.wifi_tethering,
                      color: Palette.lightSuccess,
                      count: online,
                      isDark: isDark,
                      tooltip: 'Online',
                      screenWidth: screenWidth,
                    ),
                    _buildStatusIconCountMobile(
                      icon: Icons.directions_bus,
                      color: Palette.lightSuccess,
                      count: driving,
                      isDark: isDark,
                      tooltip: 'Driving',
                      screenWidth: screenWidth,
                    ),
                    _buildStatusIconCountMobile(
                      icon: Icons.pause_circle_filled,
                      color: Palette.lightWarning,
                      count: idling,
                      isDark: isDark,
                      tooltip: 'Idling',
                      screenWidth: screenWidth,
                    ),
                    _buildStatusIconCountMobile(
                      icon: Icons.power_settings_new,
                      color: Palette.lightError,
                      count: offline,
                      isDark: isDark,
                      tooltip: 'Offline',
                      screenWidth: screenWidth,
                    ),
                  ],
                )
              : Wrap(
                  spacing: _getResponsiveSpacing(screenWidth, isMobile),
                  runSpacing: _getResponsiveSpacing(screenWidth, isMobile, isVertical: true),
                  children: [
                    _buildStatusIconCount(
                      icon: Icons.wifi_tethering,
                      color: Palette.lightSuccess,
                      count: online,
                      isDark: isDark,
                      tooltip: 'Online',
                    ),
                    _buildStatusIconCount(
                      icon: Icons.directions_bus,
                      color: Palette.lightSuccess,
                      count: driving,
                      isDark: isDark,
                      tooltip: 'Driving',
                    ),
                    _buildStatusIconCount(
                      icon: Icons.pause_circle_filled,
                      color: Palette.lightWarning,
                      count: idling,
                      isDark: isDark,
                      tooltip: 'Idling',
                    ),
                    _buildStatusIconCount(
                      icon: Icons.power_settings_new,
                      color: Palette.lightError,
                      count: offline,
                      isDark: isDark,
                      tooltip: 'Offline',
                    ),
                  ],
                ),
        ],
      ),
      ),
    );
  }

  // Mobile-friendly status: icon + count text, no backgrounds; icons colored
  Widget _buildStatusIconCountMobile({
    required IconData icon,
    required Color color,
    required int count,
    required bool isDark,
    String? tooltip,
    required double screenWidth,
  }) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: _getResponsiveFontSize(screenWidth, true, 'info') + 2, color: color),
        const SizedBox(width: 6.0),
        Text(
          count.toString(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: _getResponsiveFontSize(screenWidth, true, 'info'),
            fontWeight: FontWeight.w700,
            color: isDark ? Palette.darkText : Palette.lightText,
          ),
        ),
      ],
    );

    return tooltip != null ? Tooltip(message: tooltip, child: content) : content;
  }

  Widget _buildRouteListItem(Map<String, dynamic> routeSummary) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final String routeId = routeSummary['route_id']?.toString() ?? 'N/A';
    final String routeName = routeSummary['route_name']?.toString() ?? 'Route $routeId';
    final int total = (routeSummary['total'] as int? ?? 0);
    final int online = (routeSummary['online'] as int? ?? 0);
    final int driving = (routeSummary['driving'] as int? ?? 0);
    final int idling = (routeSummary['idling'] as int? ?? 0);
    final int offline = (routeSummary['offline'] as int? ?? 0);

    return Container(
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
          CircleAvatar(
            radius: 22,
            backgroundColor: (isDark ? Palette.darkSurface : Palette.lightSurface),
            child: Icon(Icons.alt_route, color: isDark ? Palette.darkText : Palette.lightText, size: 20),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routeName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Palette.darkText : Palette.lightText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Route ID: $routeId',
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
                Row(
                  children: [
                    _buildRouteDotCount('Online', online, Palette.lightSuccess, isDark),
                    const SizedBox(width: 12.0),
                    _buildRouteDotCount('Driving', driving, Palette.lightSuccess, isDark),
                    const SizedBox(width: 12.0),
                    _buildRouteDotCount('Idling', idling, Palette.lightWarning, isDark),
                    const SizedBox(width: 12.0),
                    _buildRouteDotCount('Offline', offline, Palette.lightError, isDark),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12.0),
          Text(
            '$total vehicles',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              color: isDark ? Palette.darkText : Palette.lightText,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRouteDotCount(String label, int count, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6.0),
        Text(
          '$label: $count',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.0,
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIconCount({
    required IconData icon,
    required Color color,
    required int count,
    required bool isDark,
    String? tooltip,
  }) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6.0),
        Text(
          count.toString(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.0,
            fontWeight: FontWeight.w700,
            color: isDark ? Palette.darkText : Palette.lightText,
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: isDark ? (color.withValues(alpha: 20)) : (color.withValues(alpha: 16)),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: isDark ? Palette.darkBorder : Palette.lightBorder),
      ),
      child: tooltip != null ? Tooltip(message: tooltip, child: content) : content,
    );
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