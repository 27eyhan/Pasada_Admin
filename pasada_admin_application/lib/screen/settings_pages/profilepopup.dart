import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/services/auth_service.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/admin_tables/edit_admin_dialog.dart';

class ProfilePopup extends StatefulWidget {
  const ProfilePopup({Key? key}) : super(key: key);

  @override
  _ProfilePopupState createState() => _ProfilePopupState();
}

class _ProfilePopupState extends State<ProfilePopup> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? adminData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAdminData();
  }

  Future<void> fetchAdminData() async {
    setState(() {
      isLoading = true;
    });
    
    final currentAdminID = AuthService().currentAdminID;

    if (currentAdminID == null) {
      print("Error in ProfilePopup: Admin ID not found in AuthService.");
      if (mounted) {
        setState(() {
          isLoading = false;
          adminData = null;
        });
      }
      return;
    }
    
    try {
      final response = await supabase
          .from('adminTable')
          .select('admin_id, first_name, last_name, admin_username, admin_mobile_number, created_at')
          .eq('admin_id', currentAdminID)
          .maybeSingle();
          
      if (mounted) {
        setState(() {
          adminData = response;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching admin data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('MM/dd/yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width * 0.6;
    final double sideLength = screenWidth * 0.6;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Palette.greenColor, width: 2),
      ),
      elevation: 8.0,
      backgroundColor: Palette.whiteColor,
      child: Container(
        width: sideLength,
        height: sideLength,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Palette.greenColor, size: 28),
                    SizedBox(width: 12.0),
                    Text(
                      "Profile",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Palette.greenColor,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: Palette.blackColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Divider(color: Palette.greenColor.withAlpha(50), thickness: 1.5),
            const SizedBox(height: 16.0),
            Expanded(
              child: isLoading 
                ? Center(child: CircularProgressIndicator(color: Palette.greenColor))
                : adminData == null
                  ? Center(
                      child: Text(
                        "No admin data found.",
                        style: TextStyle(fontSize: 16, color: Palette.blackColor, fontFamily: 'Inter'),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Palette.greenColor.withAlpha(40),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Palette.greenColor.withAlpha(40),
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Palette.greenColor,
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            // Admin ID with badge-like styling
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              margin: EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: Palette.greenColor.withAlpha(40),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Palette.greenColor.withAlpha(100)),
                              ),
                              child: Text(
                                "Admin ID: ${adminData!['admin_id']?.toString() ?? 'N/A'}",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Palette.greenColor,
                                ),
                              ),
                            ),
                            ProfileInfoTile(
                              label: "Name",
                              value: "${adminData!['first_name'] ?? 'N/A'} ${adminData!['last_name'] ?? ''}",
                            ),
                            ProfileInfoTile(
                              label: "Username",
                              value: adminData!['admin_username']?.toString() ?? 'N/A',
                            ),
                            ProfileInfoTile(
                              label: "Mobile Number",
                              value: adminData!['admin_mobile_number']?.toString() ?? 'N/A',
                            ),
                            ProfileInfoTile(
                              label: "Account Created",
                              value: formatDate(adminData!['created_at']?.toString()),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.greenColor,
                  foregroundColor: Palette.blackColor,
                  elevation: 4.0,
                  shadowColor: Colors.grey.shade300,
                  side: BorderSide(color: Palette.greenColor, width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                ),
                onPressed: () {
                  if (adminData != null) {
                    showDialog(
                      context: context,
                      builder: (context) => EditAdminDialog(
                        supabase: supabase,
                        adminData: adminData!,
                      ),
                    ).then((updated) {
                      if (updated == true) {
                        fetchAdminData(); // Refresh the data if changes were made
                      }
                    });
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 20, color: Palette.whiteColor),
                    SizedBox(width: 8),
                    Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Palette.whiteColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileInfoTile extends StatelessWidget {
  final String label;
  final String value;
  
  const ProfileInfoTile({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Inter',
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: Palette.blackColor,
            ),
          ),
        ],
      ),
    );
  }
}
