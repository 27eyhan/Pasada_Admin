import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/admin_table.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/driver_tables/driver_table.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/passenger_tables/passenger_table.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/driver_tables/driverarch_table.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/vehicle_table.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/route_table.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/ridehistory_table.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/adminarch_table.dart';

class SelectTable extends StatefulWidget {
  @override
  _SelectTableState createState() => _SelectTableState();
}

class _SelectTableState extends State<SelectTable> {
  // Static list of table names
  final List<String> tableNames = [
    'Admin',
    'Passenger',
    'Driver',
    'Vehicle',
    'Route',
    'Ride History',
    'Admin Archives',
    'Driver Archives',
    'Passenger Archives',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.whiteColor,
      appBar: AppBarSearch(),
      drawer: MyDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: List.generate(
              tableNames.length,
              (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _buildContainer(context, tableNames[index]),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContainer(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        switch (title) {
          case 'Admin':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdminTableScreen()),
            );
            break;
          case 'Driver':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DriverTableScreen()),
            );
            break;
          case 'Passenger':
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PassengerTableScreen()),
            );
            break;
          case 'Vehicle':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VehicleTableScreen()),
            );
            break;
          case 'Route':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DriverRouteTableScreen()),
            );
            break;
          case 'Ride History':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RideHistoryTableScreen()),
            );
            break;
          case 'Admin Archives':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdminArchTableScreen()),
            );
            break;
          case 'Driver Archives':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DriverArchTableScreen()),
            );
            break;
          case 'Passenger Archives':
            // Do nothing (or optionally handle this case separately)
            break;
          default:
            Navigator.pushNamed(context, '/data_tables', arguments: title);
            break;
        }
      },
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.47,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Palette.whiteColor,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Palette.blackColor.withValues(alpha: 128),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                "Database for $title",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.0,
                  color: Palette.blackColor.withValues(alpha: 128),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
