import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';

class DriverRouteTableScreen extends StatefulWidget {
  const DriverRouteTableScreen({Key? key}) : super(key: key);

  @override
  _DriverRouteTableScreenState createState() => _DriverRouteTableScreenState();
}

class _DriverRouteTableScreenState extends State<DriverRouteTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> routeData = [];
  bool isLoading = true;
  Timer? _refreshTimer; // Timer variable for refreshing the state

  @override
  void initState() {
    super.initState();
    fetchRouteData();
    // Set up a periodic timer that refreshes every 30 seconds.
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchRouteData();
    });
  }

  @override
  void dispose() {
    // Cancel the timer to prevent memory leaks.
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchRouteData() async {
    try {
      // Fetch all columns from 'driverRouteTable'
      final data = await supabase.from('driverRouteTable').select('*');
      print("Fetched route data: $data"); // Debug: verify data retrieval
      final List listData = data as List;
      setState(() {
        routeData = listData.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching route data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.whiteColor,
      appBar: AppBarSearch(),
      drawer: MyDrawer(),
      body: Stack(
        children: [
          // Main content:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : routeData.isEmpty
                  ? const Center(child: Text("No data found."))
                  : Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          margin: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Palette.whiteColor,
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: Palette.blackColor.withValues(alpha: 128),
                              width: 1,
                            ),
                          ),
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Route ID')),
                              DataColumn(label: Text('Created At')),
                              DataColumn(label: Text('Starting Place')),
                              DataColumn(label: Text('Starting Location')),
                              DataColumn(label: Text('Intermediate1 Place')),
                              DataColumn(label: Text('Intermediate Location1')),
                              DataColumn(label: Text('Intermediate2 Place')),
                              DataColumn(label: Text('Intermediate Location2')),
                              DataColumn(label: Text('Ending Place')),
                              DataColumn(label: Text('Ending Location')),
                              DataColumn(label: Text('Route')),
                            ],
                            rows: routeData.map((route) {
                              return DataRow(cells: [
                                DataCell(Text(route['route_id'].toString())),
                                DataCell(Text(route['created_at'].toString())),
                                DataCell(Text(route['starting_place'].toString())),
                                DataCell(Text(route['starting_location'].toString())),
                                DataCell(Text(route['intermediate1_place'].toString())),
                                DataCell(Text(route['intermediate_location1'].toString())),
                                DataCell(Text(route['intermediate2_place'].toString())),
                                DataCell(Text(route['intermediate_location2'].toString())),
                                DataCell(Text(route['ending_place'].toString())),
                                DataCell(Text(route['ending_location'].toString())),
                                DataCell(Text(route['route'].toString())),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
          // Positioned back button at top-left.
          Positioned(
            top: 26.0,
            left: 26.0,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Palette.blackColor, width: 1.0),
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: IconButton(
                  iconSize: 28.0,
                  icon: const Icon(Icons.arrow_back, color: Palette.blackColor),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
