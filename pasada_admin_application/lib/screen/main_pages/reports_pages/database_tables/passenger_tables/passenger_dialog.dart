import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';

class PassengerDialog extends StatefulWidget {
  final SupabaseClient supabase;
  final VoidCallback onPassengerActionComplete;
  final Map<String, dynamic>? passengerData;
  final bool isEditMode;

  const PassengerDialog({
    Key? key,
    required this.supabase,
    required this.onPassengerActionComplete,
    this.passengerData,
    this.isEditMode = false,
  }) : super(key: key);

  @override
  _PassengerDialogState createState() => _PassengerDialogState();
}

class _PassengerDialogState extends State<PassengerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.passengerData != null) {
      _displayNameController.text = widget.passengerData!['display_name']?.toString() ?? '';
      _contactNumberController.text = widget.passengerData!['contact_number']?.toString() ?? '';
      _emailController.text = widget.passengerData!['passenger_email']?.toString() ?? '';
      // _selectedPassengerType = widget.passengerData!['passenger_type']?.toString();
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _savePassenger() async {
    if (_formKey.currentState!.validate()) {
      
      // --- Handle Add Mode (Show Under Development Message) ---
      if (!widget.isEditMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add Passenger functionality is under development.'),
            duration: Duration(seconds: 3),
          ),
        );
        // Optionally pop the dialog or reset state here if desired
        // Navigator.of(context).pop(); 
        return; // Stop execution for Add mode
      }
      // --- End Add Mode Handling ---

      // Proceed with saving only if in Edit mode
      setState(() { _isLoading = true; });

      try {
        final passengerDetails = {
          'display_name': _displayNameController.text.trim(),
          'contact_number': _contactNumberController.text.trim(),
          'passenger_email': _emailController.text.trim(),
        };

        final passengerId = widget.passengerData!['id'];
        await widget.supabase
            .from('passenger')
            .update(passengerDetails)
            .match({'id': passengerId});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passenger $passengerId updated successfully!')),
        );

        // No longer need the 'else' block for adding here

        setState(() { _isLoading = false; });
        widget.onPassengerActionComplete(); // Refresh the table
        Navigator.of(context).pop(); // Close the dialog

      } catch (e) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating passenger: ${e.toString()}')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth * 0.35; // Consistent with other dialogs

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
                  // Icon and title in a more prominent style
                  Icon(Icons.edit_note, color: Palette.orangeColor, size: 48),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      widget.isEditMode ? 'Edit Passenger Information' : 'Add New Passenger',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        color: Palette.orangeColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Non-editable passenger ID field
                  if (widget.isEditMode)
                    _buildInfoRow('Passenger ID:', widget.passengerData!['id'].toString()),
                  if (widget.isEditMode)
                    _buildInfoRow('Created At:', widget.passengerData!['created_at'].toString()),
                  if (widget.isEditMode)
                    SizedBox(height: 16),
                  
                  // Form with improved styling
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _buildFormField(
                          controller: _displayNameController,
                          label: 'Display Name',
                          icon: Icons.person_outline,
                          validator: (value) => value == null || value.isEmpty ? 'Please enter display name' : null,
                        ),
                        _buildFormField(
                          controller: _contactNumberController,
                          label: 'Contact Number',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value) => value == null || value.isEmpty ? 'Please enter contact number' : null,
                        ),
                        _buildFormField(
                          controller: _emailController,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                           validator: (value) {
                             if (value == null || value.isEmpty) return 'Please enter email';
                             if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                                return 'Please enter a valid email address';
                             }
                              return null;
                          },
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
                           onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
                           onPressed: _isLoading ? null : _savePassenger,
                           child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Palette.whiteColor))
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.save, size: 20),
                                    SizedBox(width: 8),
                                    Text(widget.isEditMode ? 'Save Changes' : 'Add Passenger', 
                                         style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
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
      ),
    );
  }
}
