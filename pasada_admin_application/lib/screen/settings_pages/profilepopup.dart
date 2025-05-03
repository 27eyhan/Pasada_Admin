import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePopup extends StatefulWidget {
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
    
    try {
      final response = await supabase
          .from('adminTable')
          .select('admin_id, first_name, last_name, admin_username, admin_mobile_number, created_at')
          .limit(1)
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
    final double screenWidth = MediaQuery.of(context).size.width * 0.7;
    final double sideLength = screenWidth * 0.6;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      backgroundColor: Palette.whiteColor,
      child: Container(
        width: sideLength,
        height: sideLength,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Profile",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Palette.blackColor,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(
                    Icons.close,
                    size: 24,
                    color: Palette.blackColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Divider(color: Palette.blackColor.withValues(alpha: 128)),
            const SizedBox(height: 16.0),
            Expanded(
              child: isLoading 
                ? Center(child: CircularProgressIndicator())
                : adminData == null
                  ? Center(
                child: Text(
                        "No admin data found.",
                        style: TextStyle(fontSize: 16, color: Palette.blackColor),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Palette.blackColor.withValues(alpha: 40),
                              child: Icon(
                                Icons.person,
                                size: 50,
                    color: Palette.blackColor,
                              ),
                            ),
                            SizedBox(height: 20),
                            ProfileInfoTile(
                              label: "Admin ID",
                              value: adminData!['admin_id']?.toString() ?? 'N/A',
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
                  backgroundColor: Palette.whiteColor,
                  foregroundColor: Palette.blackColor,
                  elevation: 6.0,
                  shadowColor: Colors.grey,
                  side: BorderSide(color: Colors.grey, width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
                onPressed: () {
                },
                child: Text(
                  "Edit Profile",
                  style: TextStyle(
                    fontSize: 16,
                    color: Palette.blackColor,
                  ),
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
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Palette.blackColor,
            ),
          ),
        ],
      ),
    );
  }
}
