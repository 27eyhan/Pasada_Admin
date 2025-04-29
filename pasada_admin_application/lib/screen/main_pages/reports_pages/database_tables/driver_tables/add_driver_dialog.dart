import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';

class AddDriverDialog extends StatefulWidget {
  final SupabaseClient supabase;
  final VoidCallback onDriverAdded; // Callback to refresh the table

  const AddDriverDialog({
    Key? key,
    required this.supabase,
    required this.onDriverAdded,
  }) : super(key: key);

  @override
  _AddDriverDialogState createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends State<AddDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _driverNumberController = TextEditingController();
  final _vehicleIdController = TextEditingController();
  final _passwordController = TextEditingController(); // Added password field
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _driverNumberController.dispose();
    _vehicleIdController.dispose();
    _passwordController.dispose(); // Dispose password controller
    super.dispose();
  }

  Future<void> _saveDriver() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      final String vehicleIdText = _vehicleIdController.text.trim();
      final int? vehicleId = int.tryParse(vehicleIdText);

      try {
        // 0. Validate vehicle_id exists in vehicleTable
        if (vehicleId != null) {
          final vehicleCheckResponse = await widget.supabase
              .from('vehicleTable')
              .select('vehicle_id')
              .eq('vehicle_id', vehicleId)
              .limit(1); // Check if at least one row exists

           final List vehicleList = vehicleCheckResponse as List;
          if (vehicleList.isEmpty) {
             setState(() { _isLoading = false; });
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Error: Vehicle ID $vehicleId does not exist.')),
             );
             return; // Stop execution if vehicle ID is invalid
          }
        } else {
          // This case should technically be caught by the validator, but good to double-check
          setState(() { _isLoading = false; });
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Error: Invalid Vehicle ID format.')),
          );
          return;
        }

        // 1. Find the highest current driver_id
        final List<dynamic> response = await widget.supabase
            .from('driverTable')
            .select('driver_id')
            .order('driver_id', ascending: false)
            .limit(1);

        int nextDriverId = 1; // Default if table is empty
        if (response.isNotEmpty) {
          final int? highestId = response[0]['driver_id'];
          if (highestId != null) {
            nextDriverId = highestId + 1;
          }
        }

        // 2. Get current timestamp
        final String createdAt = DateTime.now().toIso8601String();

        // 3. Prepare data for insertion
        final newDriverData = {
          'driver_id': nextDriverId,
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'driver_number': _driverNumberController.text.trim(),
          'driver_password': _passwordController.text.trim(), // Add password
          'vehicle_id': vehicleId, // Use the parsed and validated vehicleId
          'created_at': createdAt,
          'driving_status': 'Offline', // Default status
          'last_online': null, // Default last online
        };

        // 4. Insert into Supabase
        await widget.supabase.from('driverTable').insert(newDriverData);

        setState(() { _isLoading = false; });
        widget.onDriverAdded(); // Refresh the table in the parent widget
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Driver added successfully! Driver ID: $nextDriverId')),
        );

      } catch (e) {
        setState(() { _isLoading = false; });
        print('Error adding driver: $e'); // Log the detailed error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding driver: ${e.toString()}')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Calculate width slightly smaller than drivers_info.dart (e.g., 50%)
    final double dialogWidth = screenWidth * 0.2;

    return Dialog( // Change AlertDialog to Dialog
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      backgroundColor: Palette.whiteColor,
      child: Container( // Wrap content in a Container with specific width
         width: dialogWidth,
         // Let height be determined by content, remove explicit height
         padding: const EdgeInsets.all(20.0), // Adjust padding as needed
         child: SingleChildScrollView( // Keep content scrollable
            child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch content to container width
               children: <Widget>[
                  // Title (as a Text widget, Dialog doesn't have a title property)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Add New Driver',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        color: Palette.blackColor,
                      ),
                      textAlign: TextAlign.center, // Center the title
                    ),
                  ),
                  // Form
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
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(labelText: 'Last Name'),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter last name' : null,
                        ),
                        TextFormField(
                          controller: _driverNumberController,
                          decoration: const InputDecoration(labelText: 'Driver Number'),
                          keyboardType: TextInputType.phone,
                          validator: (value) => value == null || value.isEmpty ? 'Please enter driver number' : null,
                        ),
                        TextFormField( // Added Password Field
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: 'Password'),
                          obscureText: true, // Hide password
                          validator: (value) => value == null || value.isEmpty ? 'Please enter a password' : null,
                        ),
                        TextFormField(
                          controller: _vehicleIdController,
                          decoration: const InputDecoration(labelText: 'Vehicle ID'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter vehicle ID';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0), // Spacing before actions
                  // Actions (as a Row)
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
                           onPressed: _isLoading ? null : _saveDriver,
                           child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Palette.whiteColor))
                              : const Text('Save Driver'),
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