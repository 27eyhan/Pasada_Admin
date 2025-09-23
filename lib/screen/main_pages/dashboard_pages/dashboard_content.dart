import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/maps/map_screen.dart';
import 'package:provider/provider.dart';

class DashboardContent extends StatefulWidget {
  final Map<String, dynamic>? driverLocationArgs;
  final Function(String, {Map<String, dynamic>? args})? onNavigateToPage;

  const DashboardContent({
    super.key,
    this.driverLocationArgs,
    this.onNavigateToPage,
  });

  @override
  _DashboardContentState createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  late Mapscreen _mapscreenInstance;
  final GlobalKey<MapsScreenState> _mapScreenKey = GlobalKey<MapsScreenState>();
  
  // Filter state
  Set<String> selectedStatuses = {};
  String? selectedVehicleId;
  String sortOption = 'numeric'; // Default sorting

  @override
  void initState() {
    super.initState();
    // Pass the driver location arguments to the map screen
    _mapscreenInstance = Mapscreen(
      key: _mapScreenKey,
      driverToFocus: widget.driverLocationArgs != null
          ? widget.driverLocationArgs!['driverId']
          : null,
      initialShowDriverInfo: widget.driverLocationArgs != null
          ? widget.driverLocationArgs!['viewDriverLocation']
          : false,
      selectedStatuses: selectedStatuses,
      selectedVehicleId: selectedVehicleId,
      sortOption: sortOption,
    );

    debugPrint(
        '[DashboardContent] initState: Mapscreen instance created with driver focus: ${widget.driverLocationArgs?.toString() ?? 'none'}');
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    // Get route arguments if they weren't passed through constructor
    final Map<String, dynamic>? routeArgs = widget.driverLocationArgs;

    debugPrint(
        '[DashboardContent] build called with route args: ${routeArgs?.toString() ?? 'none'}. Time: ${DateTime.now()}');

    // If we got route arguments but didn't initialize with them, recreate the map screen
    if (routeArgs != null && widget.driverLocationArgs == null) {
      _mapscreenInstance = Mapscreen(
        key: _mapScreenKey,
        driverToFocus: routeArgs['driverId'],
        initialShowDriverInfo: routeArgs['viewDriverLocation'] ?? false,
        selectedStatuses: selectedStatuses,
        selectedVehicleId: selectedVehicleId,
        sortOption: sortOption,
      );
    }

    return Container(
      color: isDark ? Palette.darkBackground : Palette.lightBackground,
      child: _mapscreenInstance,
    );
  }
}
