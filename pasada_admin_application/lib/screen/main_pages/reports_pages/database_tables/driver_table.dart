import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';

class DriverTableScreen extends StatefulWidget {
  const DriverTableScreen({Key? key}) : super(key: key);

  @override
  _DriverTableScreenState createState() => _DriverTableScreenState();
}

class _DriverTableScreenState extends State<DriverTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> driverData = [];
  bool isLoading = true;
  Timer? _refreshTimer; // Timer variable for refreshing the state

  @override
  void initState() {
    super.initState();
    fetchDriverData();
    // Set up a periodic timer that refreshes every 30 seconds.
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchDriverData();
    });
  }

  @override
  void dispose() {
    // Cancel the timer to prevent memory leaks.
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchDriverData() async {
    try {
      // Select all columns from 'driverTable'
      final data = await supabase.from('driverTable').select('*');
      print("Fetched driver data: $data"); // Debug: verify data retrieval
      final List listData = data as List;
      setState(() {
        driverData = listData.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching driver data: $e');
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
          // Main content: loading indicator or table display.
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : driverData.isEmpty
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
                              DataColumn(label: Text('Driver ID')),
                              DataColumn(label: Text('First Name')),
                              DataColumn(label: Text('Last Name')),
                              DataColumn(label: Text('Driver Number')),
                              DataColumn(label: Text('Password')),
                              DataColumn(label: Text('Created At')),
                              DataColumn(label: Text('Vehicle ID')),
                              DataColumn(label: Text('Driving Status')),
                              DataColumn(label: Text('Last Online')),
                            ],
                            rows: driverData.map((driver) {
                              return DataRow(cells: [
                                DataCell(Text(driver['driver_id'].toString())),
                                DataCell(Text(driver['first_name'].toString())),
                                DataCell(Text(driver['last_name'].toString())),
                                DataCell(Text(driver['driver_number'].toString())),
                                DataCell(Text(driver['driver_password'].toString())),
                                DataCell(Text(driver['created_at'].toString())),
                                DataCell(Text(driver['vehicle_id'].toString())),
                                DataCell(Text(driver['driving_status'].toString())),
                                DataCell(Text(driver['last_online'].toString())),
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
