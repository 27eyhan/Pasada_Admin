import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/driver_filter_dialog.dart';
import 'package:pasada_admin_application/screen/main_pages/drivers_pages/drivers_info.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/driver_tables/add_driver_dialog.dart';
import 'package:provider/provider.dart';

class Drivers extends StatefulWidget {
  const Drivers({super.key});

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
                    // Fixed width sidebar drawer
                    Container(
                      width: 280, // Fixed width for the sidebar
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
                                        children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isDark
                                          ? Palette.darkSurface
                                          : Palette.lightSurface,
                                      child: Icon(
                                        Icons.person,
                                        color: isDark
                                            ? Palette.darkText
                                            : Palette.lightText,
                                      ),
                                    ),
                                    const SizedBox(width: 12.0),
                                    Text(
                                      "Drivers",
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
            builder: (context) => AddDriverDialog(
              supabase: supabase,
              onDriverAdded: () {
                fetchDriverData(); // Refresh the drivers list when a new driver is added
              }, onDriverActionComplete: () async {  },
            ),
          );
        },
        backgroundColor: Palette.lightPrimary,
        child: Icon(Icons.person_add, color: Colors.white),
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
            final status =
                driver["driving_status"]?.toString().toLowerCase() ?? "";
            final isActive = status == "driving" ||
                status == "online" ||
                status == "idling" ||
                status == "active";

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
                        colors: isDark
                            ? [Colors.grey.shade600, Colors.grey.shade800]
                            : [Colors.grey.shade400, Colors.grey.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.transparent,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
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
                        colors: isDark
                            ? [Colors.grey.shade600, Colors.grey.shade800]
                            : [Colors.grey.shade400, Colors.grey.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.transparent,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    return Container(
      margin: EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: isMap ? (isDark ? Palette.darkSurface : Palette.lightSurface) : color,
        shape: BoxShape.circle,
        border: isMap
            ? Border.all(
                color: isDark ? Palette.darkBorder : Palette.lightBorder,
                width: 1.5,
              )
            : null,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 18,
          color: isMap
              ? (isDark ? Palette.darkText : Palette.blackColor)
              : Colors.white,
        ),
        onPressed: () {
          // Action button functionality for map icon
          if (icon == Icons.map_outlined) {
            // Navigate to dashboard with the driver ID as an argument
            Navigator.pushNamed(context, '/dashboard', arguments: {
              'viewDriverLocation': true,
              'driverId': driver['driver_id'],
              'driverName': driver['full_name'],
            });
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
            color:
                textColor ?? (isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
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
