import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';

class VehicleTableScreen extends StatefulWidget {
  const VehicleTableScreen({Key? key}) : super(key: key);

  @override
  _VehicleTableScreenState createState() => _VehicleTableScreenState();
}

class _VehicleTableScreenState extends State<VehicleTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> vehicleData = [];
  bool isLoading = true;
  Timer? _refreshTimer; // Timer variable for refreshing the state

  @override
  void initState() {
    super.initState();
    fetchVehicleData();
    // Set up a periodic timer that refreshes every 30 seconds.
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchVehicleData();
    });
  }

  @override
  void dispose() {
    // Cancel the timer to prevent memory leaks.
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchVehicleData() async {
    try {
      // Retrieve all columns from 'vehicleTable'
      final data = await supabase.from('vehicleTable').select('*');
      print("Fetched vehicle data: $data"); // Debug: verify data retrieval
      final List listData = data as List;
      setState(() {
        vehicleData = listData.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching vehicle data: $e');
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
          // Main content: loading indicator, "No data found." message, or the DataTable.
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : vehicleData.isEmpty
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
                              DataColumn(label: Text('Vehicle ID')),
                              DataColumn(label: Text('Plate Number')),
                              DataColumn(label: Text('Route ID')),
                              DataColumn(label: Text('Passenger Capacity')),
                              DataColumn(label: Text('Vehicle Location')),
                              DataColumn(label: Text('Created At')),
                            ],
                            rows: vehicleData.map((vehicle) {
                              return DataRow(cells: [
                                DataCell(Text(vehicle['vehicle_id'].toString())),
                                DataCell(Text(vehicle['plate_number'].toString())),
                                DataCell(Text(vehicle['route_id'].toString())),
                                DataCell(Text(vehicle['passenger_capacity'].toString())),
                                DataCell(Text(vehicle['vehicle_location'].toString())),
                                DataCell(Text(vehicle['created_at'].toString())),
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
