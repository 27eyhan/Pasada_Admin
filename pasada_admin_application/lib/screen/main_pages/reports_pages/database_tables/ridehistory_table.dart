import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';

class RideHistoryTableScreen extends StatefulWidget {
  const RideHistoryTableScreen({Key? key}) : super(key: key);

  @override
  _RideHistoryTableScreenState createState() => _RideHistoryTableScreenState();
}

class _RideHistoryTableScreenState extends State<RideHistoryTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> rideHistoryData = [];
  bool isLoading = true;
  Timer? _refreshTimer; // Timer variable for refreshing the state

  @override
  void initState() {
    super.initState();
    fetchRideHistoryData();
    // Set up a periodic timer that refreshes every 30 seconds.
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchRideHistoryData();
    });
  }

  @override
  void dispose() {
    // Cancel the timer to prevent memory leaks.
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchRideHistoryData() async {
    try {
      // Select all columns from 'rideHistory'
      final data = await supabase.from('rideHistory').select('*');
      print("Fetched ride history data: $data"); // Debug: verify data retrieval
      final List listData = data as List;
      setState(() {
        rideHistoryData = listData.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching ride history data: $e');
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
          // Main content: loading indicator, "No data found" message, or the data table.
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : rideHistoryData.isEmpty
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
                              DataColumn(label: Text('Ride ID')),
                              DataColumn(label: Text('Vehicle ID')),
                              DataColumn(label: Text('Passenger ID')),
                              DataColumn(label: Text('Route ID')),
                              DataColumn(label: Text('Ride Status')),
                              DataColumn(label: Text('Passenger Type')),
                              DataColumn(label: Text('Pick Up Location')),
                              DataColumn(label: Text('Drop Off Location')),
                              DataColumn(label: Text('Mode Of Payment')),
                              DataColumn(label: Text('Fare')),
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Start Time')),
                              DataColumn(label: Text('End Time')),
                              DataColumn(label: Text('Duration')),
                              DataColumn(label: Text('Distance Travelled')),
                              DataColumn(label: Text('Traffic Conditions')),
                              DataColumn(label: Text('Notes')),
                              DataColumn(label: Text('Created At')),
                            ],
                            rows: rideHistoryData.map((ride) {
                              return DataRow(cells: [
                                DataCell(Text(ride['ride_id'].toString())),
                                DataCell(Text(ride['vehicle_id'].toString())),
                                DataCell(Text(ride['passenger_id'].toString())),
                                DataCell(Text(ride['route_id'].toString())),
                                DataCell(Text(ride['ride_status'].toString())),
                                DataCell(Text(ride['passenger_type'].toString())),
                                DataCell(Text(ride['pick_up_location'].toString())),
                                DataCell(Text(ride['drop_off_location'].toString())),
                                DataCell(Text(ride['mode_of_payment'].toString())),
                                DataCell(Text(ride['fare'].toString())),
                                DataCell(Text(ride['date'].toString())),
                                DataCell(Text(ride['start_time'].toString())),
                                DataCell(Text(ride['end_time'].toString())),
                                DataCell(Text(ride['duration'].toString())),
                                DataCell(Text(ride['distance_travelled'].toString())),
                                DataCell(Text(ride['traffic_conditions'].toString())),
                                DataCell(Text(ride['notes'].toString())),
                                DataCell(Text(ride['created_at'].toString())),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
          // Positioned back button at top-left
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
