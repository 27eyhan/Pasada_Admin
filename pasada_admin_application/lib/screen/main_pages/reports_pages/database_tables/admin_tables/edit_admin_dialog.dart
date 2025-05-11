import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:bcrypt/bcrypt.dart';

class EditAdminDialog extends StatefulWidget {
  final SupabaseClient supabase;
  final Map<String, dynamic> adminData;

  const EditAdminDialog({
    Key? key,
    required this.supabase,
    required this.adminData,
  }) : super(key: key);

  @override
  _EditAdminDialogState createState() => _EditAdminDialogState();
}

class _EditAdminDialogState extends State<EditAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _passwordsMatch = true;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.adminData['first_name']?.toString() ?? '';
    _lastNameController.text = widget.adminData['last_name']?.toString() ?? '';
    _mobileNumberController.text = widget.adminData['admin_mobile_number']?.toString() ?? '';
    _usernameController.text = widget.adminData['admin_username']?.toString() ?? '';
    _passwordController.text = '';
    _confirmPasswordController.text = '';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileNumberController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<bool> _updateAdmin() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      try {
        final adminDetails = {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'admin_mobile_number': _mobileNumberController.text.trim(),
        };

        if (_passwordController.text.isNotEmpty) {
          final String hashedPassword = BCrypt.hashpw(
            _passwordController.text.trim(), 
            BCrypt.gensalt()
          );
          adminDetails['admin_password'] = hashedPassword;
        }

        final adminId = widget.adminData['admin_id'];
        await widget.supabase
            .from('adminTable')
            .update(adminDetails)
            .match({'admin_id': adminId});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Admin $adminId updated successfully!')),
        );

        setState(() { _isLoading = false; });
        Navigator.of(context).pop(true);
        return true;

      } catch (e) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating admin: ${e.toString()}')),
        );
        Navigator.of(context).pop(false);
        return false;
      }
    }
    return false;
  }

  void _checkPasswordsMatch() {
    setState(() {
      if (_passwordController.text.isEmpty && _confirmPasswordController.text.isEmpty) {
        _passwordsMatch = true;
      } else {
        _passwordsMatch = _passwordController.text == _confirmPasswordController.text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Consistent dialog width
    final double dialogWidth = screenWidth * 0.35; 

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Palette.orangeColor, width: 2),
      ),
      backgroundColor: Palette.whiteColor,
      child: Container(
         width: dialogWidth,
         padding: const EdgeInsets.all(24.0),
         child: SingleChildScrollView(
            child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: <Widget>[
                  // Icon and title
                  Icon(Icons.edit_note, color: Palette.orangeColor, size: 48),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'Edit Admin Information',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        color: Palette.orangeColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Non-editable admin ID field
                  _buildInfoRow('Admin ID:', widget.adminData['admin_id'].toString()),
                  // Non-editable username field
                  _buildInfoRow('Username:', widget.adminData['admin_username']?.toString() ?? 'N/A'),
                  SizedBox(height: 16),
                  
                  // Form with improved styling
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _buildFormField(
                          controller: _firstNameController,
                          label: 'First Name',
                          icon: Icons.person_outline,
                          validator: (value) => value == null || value.isEmpty ? 'Please enter first name' : null,
                        ),
                        _buildFormField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          icon: Icons.person_outline,
                          validator: (value) => value == null || value.isEmpty ? 'Please enter last name' : null,
                        ),
                        _buildFormField(
                          controller: _mobileNumberController,
                          label: 'Mobile Number',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value) => value == null || value.isEmpty ? 'Please enter mobile number' : null,
                        ),
                        _buildFormField(
                          controller: _passwordController,
                          label: 'New Password (leave empty to keep current)',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          onChanged: (_) => _checkPasswordsMatch(),
                          validator: (value) => value != null && value.isNotEmpty && value.length < 6 
                              ? 'Password must be at least 6 characters' 
                              : null,
                        ),
                        _buildFormField(
                          controller: _confirmPasswordController,
                          label: 'Confirm New Password',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          onChanged: (_) => _checkPasswordsMatch(),
                          validator: (value) {
                            if (_passwordController.text.isEmpty) {
                              return null;
                            }
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        if (!_passwordsMatch && _passwordController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                            child: Text(
                              'Passwords do not match',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16.0),
                  
                  // Action buttons with enhanced styling
                  Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: <Widget>[
                        ElevatedButton(
                           style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                              elevation: 3,
                              minimumSize: Size(140, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                side: BorderSide(color: Colors.grey[400]!),
                              ),
                           ),
                           onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Icon(Icons.cancel, size: 20),
                               SizedBox(width: 8),
                               Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                             ],
                           ),
                        ),
                        const SizedBox(width: 15.0),
                        ElevatedButton(
                           style: ElevatedButton.styleFrom(
                              backgroundColor: Palette.orangeColor,
                              foregroundColor: Palette.whiteColor,
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                              elevation: 3,
                              minimumSize: Size(140, 50), 
                              shadowColor: Palette.orangeColor.withAlpha(128),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                           ),
                           onPressed: _isLoading ? null : _updateAdmin,
                           child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Palette.whiteColor))
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.save, size: 20),
                                    SizedBox(width: 8),
                                    Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                  ],
                                ),
                        ),
                     ],
                  ),
               ],
            ),
         ),
      ),
    );
  }
  
  // Helper method to build read-only info rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to build form fields
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Function(String)? onChanged,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Palette.orangeColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Palette.orangeColor, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }
} 