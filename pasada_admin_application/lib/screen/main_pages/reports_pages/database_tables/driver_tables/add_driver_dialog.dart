import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:bcrypt/bcrypt.dart';

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
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _driverNumberController.dispose();
    _vehicleIdController.dispose();
    _passwordController.dispose();
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
        final String hashedPassword = BCrypt.hashpw(_passwordController.text.trim(), BCrypt.gensalt());
        final newDriverData = {
          'driver_id': nextDriverId,
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'driver_number': _driverNumberController.text.trim(),
          'driver_password': hashedPassword,
          'vehicle_id': vehicleId,
          'created_at': createdAt,
          'driving_status': 'Offline',
          'last_online': null,
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
        // Log the detailed error
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
    final double dialogWidth = screenWidth * 0.35; // Made slightly wider

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Palette.greenColor, width: 2), // Changed to green
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
                  Icon(Icons.person_add, color: Palette.greenColor, size: 48), // Changed to green
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'Add New Driver',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        color: Palette.greenColor, // Changed to green
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Informative text
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Please fill in the details to add a new driver to the system.',
                      style: TextStyle(fontSize: 14.0),
                    ),
                  ),
                  
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
                          controller: _driverNumberController,
                          label: 'Driver Number',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value) => value == null || value.isEmpty ? 'Please enter driver number' : null,
                        ),
                        _buildFormField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) => value == null || value.isEmpty ? 'Please enter a password' : null,
                        ),
                        _buildFormField(
                          controller: _vehicleIdController,
                          label: 'Vehicle ID',
                          icon: Icons.directions_car_outlined,
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
                  
                  // Reduce the spacing before buttons
                  const SizedBox(height: 16.0),
                  
                  // Actions with enhanced styling
                  Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: <Widget>[
                        ElevatedButton(
                           style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                              // Increase button size
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                              elevation: 3,
                              minimumSize: Size(140, 50), // Set minimum size
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                side: BorderSide(color: Colors.grey[400]!),
                              ),
                           ),
                           onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Icon(Icons.cancel, size: 20), // Larger icon
                               SizedBox(width: 8),
                               Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), // Larger text
                             ],
                           ),
                        ),
                        const SizedBox(width: 15.0),
                        ElevatedButton(
                           style: ElevatedButton.styleFrom(
                              backgroundColor: Palette.greenColor,
                              foregroundColor: Palette.whiteColor,
                              // Increase button size
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                              elevation: 3,
                              minimumSize: Size(140, 50), // Set minimum size
                              shadowColor: Palette.greenColor.withAlpha(128),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                           ),
                           onPressed: _isLoading ? null : _saveDriver,
                           child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Palette.whiteColor)) // Larger spinner
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.save, size: 20), // Larger icon
                                    SizedBox(width: 8),
                                    Text('Save Driver', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), // Larger text
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
  
  // Helper method to build standardized form fields
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
          prefixIcon: Icon(icon, color: Palette.greenColor), // Changed to green
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Palette.greenColor, width: 2.0), // Changed to green
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