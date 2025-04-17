import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';

class PassengerTableScreen extends StatefulWidget {
  const PassengerTableScreen({Key? key}) : super(key: key);

  @override
  _PassengerTableScreenState createState() => _PassengerTableScreenState();
}

class _PassengerTableScreenState extends State<PassengerTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> passengerData = [];
  bool isLoading = true;
  Timer? _refreshTimer; // Timer variable for refreshing the state

  @override
  void initState() {
    super.initState();
    fetchPassengerData();
    // Set up a periodic timer that refreshes every 30 seconds.
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchPassengerData();
    });
  }

  @override
  void dispose() {
    // Cancel the timer to prevent memory leaks.
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchPassengerData() async {
    try {
      // Select all columns from 'passenger'
      final data = await supabase.from('passenger').select('*');
      print("Fetched passenger data: $data"); // Debug: verify data retrieval
      final List listData = data as List;
      setState(() {
        passengerData = listData.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching passenger data: $e');
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
          // Main content: displays a loading indicator, "No data found." message, 
          // or the DataTable with passenger data.
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : passengerData.isEmpty
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
                              DataColumn(label: Text('Created At')),
                              DataColumn(label: Text('First Name')),
                              DataColumn(label: Text('Last Name')),
                              DataColumn(label: Text('Contact Number')),
                              DataColumn(label: Text('Passenger Email')),
                              DataColumn(label: Text('Passenger Type')),
                              DataColumn(label: Text('Valid ID')),
                              DataColumn(label: Text('Last Login')),
                              DataColumn(label: Text('ID')),
                            ],
                            rows: passengerData.map((passenger) {
                              return DataRow(cells: [
                                DataCell(Text(passenger['created_at'].toString())),
                                DataCell(Text(passenger['first_name'].toString())),
                                DataCell(Text(passenger['last_name'].toString())),
                                DataCell(Text(passenger['contact_number'].toString())),
                                DataCell(Text(passenger['passenger_email'].toString())),
                                DataCell(Text(passenger['passenger_type'].toString())),
                                DataCell(Text(passenger['valid_id'].toString())),
                                DataCell(Text(passenger['last_login'].toString())),
                                DataCell(Text(passenger['id'].toString())),
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
