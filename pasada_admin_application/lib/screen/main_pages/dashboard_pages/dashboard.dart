import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:pasada_admin_application/maps/map_screen.dart';

class Dashboard extends StatefulWidget {

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late Widget _mapscreenInstance;
  @override
  void initState() {
    super.initState();
    _mapscreenInstance = const Mapscreen(); 
    debugPrint('[Dashboard] initState: Mapscreen instance created.');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[Dashboard] build called. Time: ${DateTime.now()}');
    return Scaffold(
      backgroundColor: Palette.whiteColor,
      appBar: AppBarSearch(), 
      drawer: MyDrawer(),
      body: _mapscreenInstance,
    );
  }
}