import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:pasada_admin_application/widgets/responsive_layout.dart';
import 'package:pasada_admin_application/screen/main_pages/drivers_pages/drivers_info.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:pasada_admin_application/services/auth_service.dart';

class DriversContent extends StatefulWidget {
  final Function(String, {Map<String, dynamic>? args})? onNavigateToPage;

  const DriversContent({super.key, this.onNavigateToPage});

  @override
  _DriversContentState createState() => _DriversContentState();
}

class _DriversContentState extends State<DriversContent> {
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
    _configureAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  void _configureAutoRefresh() {
    _refreshTimer?.cancel();
    final auth = AuthService();
    final freq = auth.updateFrequency; // 'realtime' | '5min' | '15min' | 'manual'
    final auto = auth.autoRefreshEnabled;
    final intervalSec = auth.refreshIntervalSeconds;

    Duration? period;
    if (!auto && freq == 'manual') {
      period = null;
    } else if (freq == 'realtime') {
      period = Duration(seconds: intervalSec.clamp(5, 120));
    } else if (freq == '5min') {
      period = const Duration(minutes: 5);
    } else if (freq == '15min') {
      period = const Duration(minutes: 15);
    } else if (freq == '30min') {
      period = const Duration(minutes: 30);
    } else {
      period = auto ? Duration(seconds: intervalSec.clamp(10, 600)) : null;
    }

    if (period != null) {
      _refreshTimer = Timer.periodic(period, (_) => fetchDriverData());
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
      } else {
        // numeric sorting is default
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
          final status =
              driver["driving_status"]?.toString().toLowerCase() ?? "";
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
    return;
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
                                    Icons.person,
                                    color: isDark
                                        ? Palette.darkText
                                        : Palette.lightText,
                                    size: ResponsiveHelper.getResponsiveIconSize(context),
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                ResponsiveText(
                                  "Drivers",
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
                                      'All Drivers',
                                      totalDrivers,
                                      isDark ? Palette.darkText : Palette.lightText,
                                    ),
                                  ),
                                  _buildVerticalSeparator(isDark),
                                  Expanded(
                                    child: _buildCompactMetric(
                                      'Online',
                                      activeDrivers,
                                      isDark ? Palette.darkText : Palette.lightText,
                                    ),
                                  ),
                                  _buildVerticalSeparator(isDark),
                                  Expanded(
                                    child: _buildCompactMetric(
                                      'Offline',
                                      offlineDrivers,
                                      isDark ? Palette.darkText : Palette.lightText,
                                    ),
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
                                    color: isDark ? Palette.darkCard : Palette.lightCard,
                                    border: Border.all(
                                      color: isDark ? Palette.darkBorder : Palette.lightBorder,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
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

                            // Driver list with conditional rendering based on view mode
                            isGridView ? _buildGridView() : _buildListView(),
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
    return ResponsiveGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 3,
      largeDesktopColumns: 4,
      childAspectRatio: 2.2,
      children: filteredDriverData.map((driver) {
        final status = driver["driving_status"]?.toString().toLowerCase() ?? "";
        final isActive = status == "driving" ||
            status == "online" ||
            status == "idling" ||
            status == "active";
        return _buildDriverCard(driver, isActive);
      }).toList(),
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
        final isActive = status == "driving" ||
            status == "online" ||
            status == "idling" ||
            status == "active";

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildDriverListItem(driver, isActive),
        );
      },
    );
  }

  // List item for the list view
  Widget _buildDriverListItem(Map<String, dynamic> driver, bool isActive) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
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
            color: isDark ? Palette.darkCard : Palette.lightCard,
            border: Border.all(
                color: isDark 
                    ? Palette.darkBorder.withValues(alpha: 77)
                    : Palette.lightBorder.withValues(alpha: 77), 
                width: 1.0),
            borderRadius: BorderRadius.circular(12.0),
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
                              color: isDark ? Palette.darkText : Palette.lightText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            "ID: ${driver['driver_id']}",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.0,
                              color: isDark ? Palette.darkText : Palette.lightText,
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
                          _buildDriverInfoRow(Icons.phone_android,
                              "${driver['driver_number']}"),
                        ],
                      ),
                    ),

                    // Vehicle
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDriverInfoRow(Icons.directions_car_outlined,
                              "${driver['vehicle_id']}"),
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
                            isActive
                                ? Icons.play_circle_outline
                                : Icons.pause_circle_outline,
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
                  _buildActionButton(Icons.map_outlined, Palette.blackColor, driver),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver, bool isActive) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
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
            color: isDark ? Palette.darkCard : Palette.lightCard,
            border: Border.all(
                color: isDark 
                    ? Palette.darkBorder.withValues(alpha: 77)
                    : Palette.lightBorder.withValues(alpha: 77),
                width: 1.0),
            borderRadius: BorderRadius.circular(15.0),
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
                            color: isDark ? Palette.darkText : Palette.lightText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8.0),
                        _buildDriverInfoRow(Icons.badge_outlined,
                            "ID: ${driver['driver_id']}",
                            textColor: isDark ? Palette.darkText : Palette.lightText),
                        _buildDriverInfoRow(Icons.phone_android,
                            "${driver['driver_number']}",
                            textColor: isDark ? Palette.darkText : Palette.lightText),
                        _buildDriverInfoRow(Icons.directions_car_outlined,
                            "Vehicle: ${driver['vehicle_id']}",
                            textColor: isDark ? Palette.darkText : Palette.lightText),
                        _buildDriverInfoRow(
                          isActive
                              ? Icons.play_circle_outline
                              : Icons.pause_circle_outline,
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
                    _buildActionButton(Icons.map_outlined, Palette.blackColor, driver),
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
  Widget _buildActionButton(
      IconData icon, Color color, Map<String, dynamic> driver) {
    final bool isMap = icon == Icons.map_outlined;
    return Container(
      margin: EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: isMap ? Palette.lightSurface : color,
        shape: BoxShape.circle,
        border: isMap ? Border.all(color: Palette.blackColor, width: 1.5) : null,
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: isMap ? Palette.blackColor : Colors.white),
        onPressed: () {
          // Action button functionality for map icon
          if (icon == Icons.map_outlined) {
            // Navigate to dashboard with the driver ID as an argument
            if (widget.onNavigateToPage != null) {
              widget.onNavigateToPage!('/dashboard', args: {
                'viewDriverLocation': true,
                'driverId': driver['driver_id'],
                'driverName': driver['full_name'],
              });
            }
          }
          // Other icon actions can be added here
        },
        constraints: BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
        splashRadius: 18,
      ),
    );
  }

  // Helper widget for driver info rows with icons
  Widget _buildDriverInfoRow(IconData icon, String text, {Color? textColor}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? Palette.darkText : Palette.lightText,
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.0,
                color: textColor ?? (isDark ? Palette.darkText : Palette.lightText),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to capitalize first letter
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Compact metric item: uppercase label above value (Fleet-like)
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
