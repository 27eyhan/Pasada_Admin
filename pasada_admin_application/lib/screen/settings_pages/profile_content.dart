import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/services/auth_service.dart';
import 'package:pasada_admin_application/screen/settings_pages/settings_utils.dart';

class ProfileContent extends StatefulWidget {
  final bool isDark;
  
  const ProfileContent({Key? key, required this.isDark}) : super(key: key);

  @override
  _ProfileContentState createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? adminData;
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;

  // Controllers for editing
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAdminData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  Future<void> fetchAdminData() async {
    setState(() {
      isLoading = true;
    });
    
    final currentAdminID = AuthService().currentAdminID;

    if (currentAdminID == null) {
      print("Error in ProfileContent: Admin ID not found in AuthService.");
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
        // Initialize controllers with current data
        _firstNameController.text = adminData?['first_name']?.toString() ?? '';
        _lastNameController.text = adminData?['last_name']?.toString() ?? '';
        _mobileNumberController.text = adminData?['admin_mobile_number']?.toString() ?? '';
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

  void _startEditing() {
    setState(() {
      isEditing = true;
      // Reset controllers to current values
      _firstNameController.text = adminData?['first_name']?.toString() ?? '';
      _lastNameController.text = adminData?['last_name']?.toString() ?? '';
      _mobileNumberController.text = adminData?['admin_mobile_number']?.toString() ?? '';
    });
  }

  void _cancelEditing() {
    setState(() {
      isEditing = false;
      // Reset controllers to current values
      _firstNameController.text = adminData?['first_name']?.toString() ?? '';
      _lastNameController.text = adminData?['last_name']?.toString() ?? '';
      _mobileNumberController.text = adminData?['admin_mobile_number']?.toString() ?? '';
    });
  }

  Future<void> _saveChanges() async {
    if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('First name and last name are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final adminDetails = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'admin_mobile_number': _mobileNumberController.text.trim(),
      };

      final adminId = adminData?['admin_id'];
      await supabase
          .from('adminTable')
          .update(adminDetails)
          .match({'admin_id': adminId});

      // Refresh data
      await fetchAdminData();

      setState(() {
        isEditing = false;
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Palette.greenColor,
        ),
      );
    } catch (e) {
      setState(() {
        isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: Palette.greenColor));
    }

    if (adminData == null) {
      return Center(
        child: Text(
          "No admin data found.",
          style: TextStyle(fontSize: 16, color: widget.isDark ? Palette.darkText : Palette.lightText, fontFamily: 'Inter'),
        ),
      );
    }

    return Column(
      children: [
        // Profile Avatar
        Center(
          child: Container(
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
              radius: 40,
              backgroundColor: Palette.greenColor.withAlpha(40),
              child: Icon(
                Icons.person,
                size: 35,
                color: Palette.greenColor,
              ),
            ),
          ),
        ),
        SizedBox(height: 24),
        
        // Admin ID Badge
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Palette.greenColor.withAlpha(40),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Palette.greenColor.withAlpha(100)),
            ),
            child: Text(
              "Admin ID: ${adminData!['admin_id']?.toString() ?? 'N/A'}",
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Palette.greenColor,
              ),
            ),
          ),
        ),
        
        // Profile Information
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark ? Palette.darkSurface : Palette.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark ? Palette.darkBorder : Palette.lightBorder,
            ),
          ),
          child: Column(
            children: [
              // Name field
              if (isEditing) ...[
                _buildEditableField(
                  controller: _firstNameController,
                  label: "First Name",
                  icon: Icons.person_outline,
                ),
                SizedBox(height: 16),
                _buildEditableField(
                  controller: _lastNameController,
                  label: "Last Name",
                  icon: Icons.person_outline,
                ),
              ] else ...[
                ProfileInfoTile(
                  label: "Name",
                  value: "${adminData!['first_name'] ?? 'N/A'} ${adminData!['last_name'] ?? ''}",
                  isDark: widget.isDark,
                ),
              ],
              
              Divider(color: widget.isDark ? Palette.darkDivider : Palette.lightDivider),
              
              // Username field (read-only)
              ProfileInfoTile(
                label: "Username",
                value: adminData!['admin_username']?.toString() ?? 'N/A',
                isDark: widget.isDark,
              ),
              
              Divider(color: widget.isDark ? Palette.darkDivider : Palette.lightDivider),
              
              // Mobile number field
              if (isEditing) ...[
                _buildEditableField(
                  controller: _mobileNumberController,
                  label: "Mobile Num",
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
              ] else ...[
                ProfileInfoTile(
                  label: "Mobile Num",
                  value: adminData!['admin_mobile_number']?.toString() ?? 'N/A',
                  isDark: widget.isDark,
                ),
              ],
              
              Divider(color: widget.isDark ? Palette.darkDivider : Palette.lightDivider),
              
              // Account created (read-only)
              ProfileInfoTile(
                label: "Account Created",
                value: formatDate(adminData!['created_at']?.toString()),
                isDark: widget.isDark,
              ),
            ],
          ),
        ),
        
        SizedBox(height: 24),
        
        // Action Buttons
        Center(
          child: isEditing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isSaving ? null : _cancelEditing,
                      icon: Icon(Icons.cancel, size: 18),
                      label: Text("Cancel"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 2,
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: isSaving ? null : _saveChanges,
                      icon: isSaving 
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                            )
                          : Icon(Icons.save, size: 18),
                      label: Text(isSaving ? "Saving..." : "Save Changes"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.greenColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 2,
                        shadowColor: Palette.greenColor.withAlpha(100),
                      ),
                    ),
                  ],
                )
              : ElevatedButton.icon(
                  onPressed: _startEditing,
                  icon: Icon(Icons.edit, size: 18),
                  label: Text("Edit Profile"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.greenColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 2,
                    shadowColor: Palette.greenColor.withAlpha(100),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Row(
      children: [
        // Left side with icon and label
        Row(
          children: [
            Icon(icon, color: Palette.greenColor, size: 20),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: widget.isDark ? Palette.darkText : Palette.lightText,
              ),
            ),
          ],
        ),
        // Spacer to push the text field to the right
        Spacer(),
        // Right side with the text field
        SizedBox(
          width: 200, // Constrain the text field width
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Palette.greenColor, width: 2.0),
              ),
              filled: true,
              fillColor: widget.isDark ? Palette.darkSurface : Colors.grey[50],
              contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              isDense: true, // Make the field more compact
            ),
          ),
        ),
      ],
    );
  }
}
