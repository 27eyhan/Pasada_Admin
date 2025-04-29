import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:uuid/uuid.dart'; // Import the uuid package

class PassengerDialog extends StatefulWidget {
  final SupabaseClient supabase;
  final VoidCallback onPassengerActionComplete; // Renamed callback
  final Map<String, dynamic>? passengerData; // Optional data for editing
  final bool isEditMode;

  const PassengerDialog({
    Key? key,
    required this.supabase,
    required this.onPassengerActionComplete,
    this.passengerData,
    this.isEditMode = false, // Default to false (Add mode)
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
        print("Updating passenger ID: $passengerId");
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
        print('Error saving passenger (update): $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating passenger: ${e.toString()}')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth * 0.3; // Adjusted width

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
                      widget.isEditMode ? 'Edit Passenger' : 'Add New Passenger',
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
                          controller: _displayNameController,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter display name' : null,
                        ),
                         SizedBox(height: 8),
                        TextFormField(
                          controller: _contactNumberController,
                          decoration: const InputDecoration(labelText: 'Contact Number'),
                          keyboardType: TextInputType.phone,
                          validator: (value) => value == null || value.isEmpty ? 'Please enter contact number' : null,
                        ),
                         SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email Address'),
                          keyboardType: TextInputType.emailAddress,
                           validator: (value) {
                             if (value == null || value.isEmpty) return 'Please enter email';
                             if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                                return 'Please enter a valid email address';
                             }
                              return null;
                          },
                        ),
                         SizedBox(height: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                     mainAxisAlignment: MainAxisAlignment.end,
                     children: <Widget>[
                        TextButton(
                           child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                           onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8.0),
                        ElevatedButton(
                           style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Palette.whiteColor,
                           ),
                           onPressed: _isLoading ? null : _savePassenger,
                           child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Palette.whiteColor))
                              : Text(widget.isEditMode ? 'Save Changes' : 'Add Passenger'),
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
