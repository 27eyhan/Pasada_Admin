import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';

class AdminTableScreen extends StatefulWidget {
  const AdminTableScreen({Key? key}) : super(key: key);

  @override
  _AdminTableScreenState createState() => _AdminTableScreenState();
}

class _AdminTableScreenState extends State<AdminTableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> adminData = [];
  bool isLoading = true;
  Timer? _refreshTimer; // Timer variable for refreshing the state

  @override
  void initState() {
    super.initState();
    fetchAdminData();
    // Set up a periodic timer that refreshes every 30 seconds.
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchAdminData();
    });
  }

  @override
  void dispose() {
    // Cancel the timer to prevent memory leaks.
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchAdminData() async {
    try {
      // Use .select('*') to explicitly select all columns
      final data = await supabase.from('adminTable').select('*');
      print("Fetched data: $data"); // Debug print to verify data retrieval
      final List listData = data as List;
      setState(() {
        adminData = listData.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching admin data: $e');
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
      // Wrap the body in a Stack to overlay the back button
      body: Stack(
        children: [
          // Main content for data table
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : adminData.isEmpty
                  ? const Center(child: Text("No data found."))
                  : SingleChildScrollView(
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
                            DataColumn(label: Text('Admin ID')),
                            DataColumn(label: Text('First Name')),
                            DataColumn(label: Text('Last Name')),
                            DataColumn(label: Text('Mobile Number')),
                            DataColumn(label: Text('Password')),
                            DataColumn(label: Text('Created At')),
                          ],
                          rows: adminData.map((admin) {
                            return DataRow(cells: [
                              DataCell(Text(admin['admin_id'].toString())),
                              DataCell(Text(admin['first_name'].toString())),
                              DataCell(Text(admin['last_name'].toString())),
                              DataCell(Text(admin['admin_mobile_number'].toString())),
                              DataCell(Text(admin['admin_password'].toString())),
                              DataCell(Text(admin['created_at'].toString())),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
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
