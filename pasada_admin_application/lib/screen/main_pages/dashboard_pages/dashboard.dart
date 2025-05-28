import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:pasada_admin_application/maps/map_screen.dart';

class Dashboard extends StatefulWidget {
  final Map<String, dynamic>? driverLocationArgs;
  
  const Dashboard({Key? key, this.driverLocationArgs}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late Widget _mapscreenInstance;
  
  @override
  void initState() {
    super.initState();
    // Pass the driver location arguments to the map screen
    _mapscreenInstance = Mapscreen(
      driverToFocus: widget.driverLocationArgs != null ? 
        widget.driverLocationArgs!['driverId'] : null,
      initialShowDriverInfo: widget.driverLocationArgs != null ? 
        widget.driverLocationArgs!['viewDriverLocation'] : false,
    );
    
    debugPrint('[Dashboard] initState: Mapscreen instance created with driver focus: ${widget.driverLocationArgs?.toString() ?? 'none'}');
  }

  @override
  Widget build(BuildContext context) {
    // Get route arguments if they weren't passed through constructor
    final Map<String, dynamic>? routeArgs = 
        widget.driverLocationArgs ?? ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    debugPrint('[Dashboard] build called with route args: ${routeArgs?.toString() ?? 'none'}. Time: ${DateTime.now()}');
    
    // If we got route arguments but didn't initialize with them, recreate the map screen
    if (routeArgs != null && widget.driverLocationArgs == null) {
      _mapscreenInstance = Mapscreen(
        driverToFocus: routeArgs['driverId'],
        initialShowDriverInfo: routeArgs['viewDriverLocation'] ?? false,
      );
    }
    
    return Scaffold(
      backgroundColor: Palette.whiteColor,
      appBar: AppBarSearch(), 
      drawer: MyDrawer(),
      body: _mapscreenInstance,
    );
  }
}