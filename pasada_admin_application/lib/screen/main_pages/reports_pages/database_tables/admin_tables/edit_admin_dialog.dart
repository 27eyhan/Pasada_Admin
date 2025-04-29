import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';

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

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.adminData['first_name']?.toString() ?? '';
    _lastNameController.text = widget.adminData['last_name']?.toString() ?? '';
    _mobileNumberController.text = widget.adminData['admin_mobile_number']?.toString() ?? '';
    _usernameController.text = widget.adminData['admin_username']?.toString() ?? '';
    _passwordController.text = widget.adminData['admin_password']?.toString() ?? ''; // Pre-fill password
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileNumberController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
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
          'admin_username': _usernameController.text.trim(),
          'admin_password': _passwordController.text.trim(),
        };

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

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Consistent dialog width
    final double dialogWidth = screenWidth * 0.3; 

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      backgroundColor: Palette.whiteColor,
      child: Container(
         width: dialogWidth,
         padding: const EdgeInsets.all(20.0),
         child: SingleChildScrollView(
            child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Edit Admin',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        color: Palette.blackColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(labelText: 'First Name'),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter first name' : null,
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(labelText: 'Last Name'),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter last name' : null,
                        ),
                         SizedBox(height: 8),
                        TextFormField(
                          controller: _mobileNumberController,
                          decoration: const InputDecoration(labelText: 'Mobile Number'),
                           keyboardType: TextInputType.phone,
                          validator: (value) => value == null || value.isEmpty ? 'Please enter mobile number' : null,
                        ),
                         SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(labelText: 'Username'),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter username' : null,
                        ),
                         SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: 'Password'),
                          obscureText: true, // Hide password
                          // Add validator if password editing requires constraints
                          validator: (value) => value == null || value.isEmpty ? 'Please enter password' : null, 
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                     mainAxisAlignment: MainAxisAlignment.end,
                     children: <Widget>[
                        TextButton(
                           child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                           onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                        ),
                        const SizedBox(width: 8.0),
                        ElevatedButton(
                           style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Palette.whiteColor,
                           ),
                           onPressed: _isLoading ? null : _updateAdmin,
                           child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Palette.whiteColor))
                              : const Text('Save Changes'),
                        ),
                     ],
                  ),
               ],
            ),
         ),
      ),
    );
  }
} 