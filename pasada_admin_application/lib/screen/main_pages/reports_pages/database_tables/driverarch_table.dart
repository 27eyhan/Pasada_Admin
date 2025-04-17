import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';

class DriverArchTableScreen extends StatefulWidget {
  const DriverArchTableScreen({Key? key}) : super(key: key);

  @override
  _DriverArchTableScreenState createState() => _DriverArchTableScreenState();
}

class _DriverArchTableScreenState extends State<DriverArchTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> archiveData = [];
  bool isLoading = true;
  Timer? _refreshTimer; // Timer variable for refreshing the state

  @override
  void initState() {
    super.initState();
    fetchArchiveData();
    // Set up a periodic timer that refreshes every 30 seconds.
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchArchiveData();
    });
  }

  @override
  void dispose() {
    // Cancel the timer to prevent memory leaks.
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchArchiveData() async {
    try {
      // Select all columns from the 'driverArchives' table.
      final data = await supabase.from('driverArchives').select('*');
      print("Fetched archive data: $data"); // Debug: verify data retrieval
      final List listData = data as List;
      setState(() {
        archiveData = listData.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching archive data: $e');
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
          // Main content: loading indicator, "No data found.", or the DataTable.
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : archiveData.isEmpty
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
                              DataColumn(label: Text('Archive ID')),
                              DataColumn(label: Text('Driver ID')),
                              DataColumn(label: Text('First Name')),
                              DataColumn(label: Text('Last Name')),
                              DataColumn(label: Text('Driver Number')),
                              DataColumn(label: Text('Driver Password')),
                              DataColumn(label: Text('Last Vehicle Used')),
                              DataColumn(label: Text('Archived At')),
                            ],
                            rows: archiveData.map((archive) {
                              return DataRow(cells: [
                                DataCell(Text(archive['archive_id'].toString())),
                                DataCell(Text(archive['driver_id'].toString())),
                                DataCell(Text(archive['first_name'].toString())),
                                DataCell(Text(archive['last_name'].toString())),
                                DataCell(Text(archive['driver_number'].toString())),
                                DataCell(Text(archive['driver_password'].toString())),
                                DataCell(Text(archive['last_vehicle_used'].toString())),
                                DataCell(Text(archive['archived_at'].toString())),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
          // Positioned back button in the top-left corner.
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
