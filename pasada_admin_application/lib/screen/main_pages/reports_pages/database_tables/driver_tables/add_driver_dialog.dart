import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/services.dart';

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
  final _fullNameController = TextEditingController();
  final _driverNumberController = TextEditingController();
  final _vehicleIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  // final _routeIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _driverNumberController.dispose();
    _vehicleIdController.dispose();
    _passwordController.dispose();
    _licenseNumberController.dispose();
    // _routeIdController.dispose();
    super.dispose();
  }

  Future<void> _saveDriver() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

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
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Error: Vehicle ID $vehicleId does not exist.')),
            );
            return; // Stop execution if vehicle ID is invalid
          }
          
          // Check if vehicle ID is already assigned to another driver
          final driverVehicleCheck = await widget.supabase
              .from('driverTable')
              .select('driver_id, full_name')
              .eq('vehicle_id', vehicleId)
              .limit(1);
              
          final List existingDriversWithVehicle = driverVehicleCheck as List;
          if (existingDriversWithVehicle.isNotEmpty) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('There\'s already a driver in Vehicle ID: $vehicleId. Please choose a different vehicle.'),
              ),
            );
            return; // Stop execution if vehicle ID is already assigned
          }
        } else {
          // This case should technically be caught by the validator, but good to double-check
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Invalid Vehicle ID format.')),
          );
          return;
        }
        
        // Validate that route_id exists in officialroute table
        // final routeIdText = _routeIdController.text.trim();
        // final int? routeId = int.tryParse(routeIdText);
        
        // if (routeId != null) {
        //   final routeCheckResponse = await widget.supabase
        //       .from('official_routes')
        //       .select('officialroute_id')
        //       .eq('officialroute_id', routeId)
        //       .limit(1);
              
        //   final List routeList = routeCheckResponse as List;
        //   if (routeList.isEmpty) {
        //     setState(() {
        //       _isLoading = false;
        //     });
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       SnackBar(
        //         content: Text('Error: Route ID $routeId does not exist.'),
        //       ),
        //     );
        //     return; // Stop execution if route ID is invalid
        //   }
        // } else {
        //   setState(() {
        //     _isLoading = false;
        //   });
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     const SnackBar(content: Text('Error: Invalid Route ID format.')),
        //   );
        //   return;
        // }
        
        // Check for license number duplication
        final licenseNumberCheck = await widget.supabase
            .from('driverTable')
            .select('driver_id')
            .eq('driver_license_number', _licenseNumberController.text.trim())
            .limit(1);
            
        final List existingLicenseNumbers = licenseNumberCheck as List;
        if (existingLicenseNumbers.isNotEmpty) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Duplication of Driver\'s License Number is not allowed.'),
            ),
          );
          return; // Stop execution if license number is already used
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
        final String hashedPassword =
            BCrypt.hashpw(_passwordController.text.trim(), BCrypt.gensalt());
        final newDriverData = {
          'driver_id': nextDriverId,
          'full_name': _fullNameController.text.trim(),
          'driver_number': _driverNumberController.text.trim(),
          'driver_license_number': _licenseNumberController.text.trim(),
          'driver_password': hashedPassword,
          'vehicle_id': vehicleId,
          // 'currentroute_id': int.tryParse(_routeIdController.text.trim()),
          'created_at': createdAt,
          'driving_status': 'Offline',
          'last_online': null,
        };

        // 4. Insert into Supabase
        await widget.supabase.from('driverTable').insert(newDriverData);

        setState(() {
          _isLoading = false;
        });
        widget.onDriverAdded(); // Refresh the table in the parent widget
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Driver added successfully! Driver ID: $nextDriverId')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
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
        side:
            BorderSide(color: Palette.greenColor, width: 2), // Changed to green
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
              Icon(Icons.person_add,
                  color: Palette.greenColor, size: 48), // Changed to green
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
                      controller: _fullNameController,
                      label: 'Name',
                      icon: Icons.person_outline,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter driver name'
                          : null,
                    ),
                    _buildFormField(
                      controller: _licenseNumberController,
                      label: 'License Number',
                      icon: Icons.credit_card,
                      hintText: 'AXX-XX-XXXXXX',
                      inputFormatters: [
                        LicenseNumberFormatter(),
                        LengthLimitingTextInputFormatter(
                            13), // A00-00-000000 = 12 chars
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter driver license number';
                        }

                        // Regex pattern for Philippine license format "A00-00-000000"
                        RegExp licenseFormat =
                            RegExp(r'^[A-Z]\d{2}-\d{2}-\d{6}$');
                        if (!licenseFormat.hasMatch(value)) {
                          return 'Format should be A00-00-000000 (letter-numbers)';
                        }

                        return null;
                      },
                    ),
                    _buildFormField(
                      controller: _driverNumberController,
                      label: 'Driver Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      hintText: '+63',
                      inputFormatters: [
                        PhoneNumberFormatter(),
                        LengthLimitingTextInputFormatter(13), // +63 + 10 digits
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter driver number';
                        }
                        
                        // Check for proper Philippines phone format
                        RegExp phoneFormat = RegExp(r'^\+63\d{10}$');
                        if (!phoneFormat.hasMatch(value)) {
                          return 'Format should be +63 followed by 10 digits';
                        }
                        
                        return null;
                      },
                    ),
                    _buildFormField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a password'
                          : null,
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
                    // _buildFormField(
                    //   controller: _routeIdController,
                    //   label: 'Route ID',
                    //   icon: Icons.route,
                    //   keyboardType: TextInputType.number,
                    //   hintText: 'Enter Route ID',
                    //   validator: (value) {
                    //     if (value == null || value.isEmpty) {
                    //       return 'Please enter route ID';
                    //     }
                    //     if (int.tryParse(value) == null) {
                    //       return 'Please enter a valid number';
                    //     }
                    //     return null;
                    //   },
                    // ),
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                      elevation: 3,
                      minimumSize: Size(140, 50), // Set minimum size
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                    ),
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cancel, size: 20), // Larger icon
                        SizedBox(width: 8),
                        Text('Cancel',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16)), // Larger text
                      ],
                    ),
                  ),
                  const SizedBox(width: 15.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.greenColor,
                      foregroundColor: Palette.whiteColor,
                      // Increase button size
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                      elevation: 3,
                      minimumSize: Size(140, 50), // Set minimum size
                      shadowColor: Palette.greenColor.withAlpha(128),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    onPressed: _isLoading ? null : _saveDriver,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Palette.whiteColor)) // Larger spinner
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.save, size: 20), // Larger icon
                              SizedBox(width: 8),
                              Text('Save Driver',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16)), // Larger text
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
    String? hintText,
    String? helperText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          helperText: helperText,
          prefixIcon: Icon(icon, color: Palette.greenColor), // Changed to green
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
                color: Palette.greenColor, width: 2.0), // Changed to green
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding:
              EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        inputFormatters: inputFormatters,
      ),
    );
  }
}

// Custom input formatter for license number
class LicenseNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Return if deleting
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    String newText = newValue.text.toUpperCase();
    final buffer = StringBuffer();
    int index = 0;

    // Format as A00-00-000000
    for (int i = 0; i < newText.length && index < 13; i++) {
      if (index == 0 && RegExp(r'[A-Z]').hasMatch(newText[i])) {
        buffer.write(newText[i]);
        index++;
      } else if ((index >= 1 && index <= 2) &&
          RegExp(r'\d').hasMatch(newText[i])) {
        buffer.write(newText[i]);
        index++;
      } else if (index == 3) {
        buffer.write('-');
        i--; // Don't consume the character
        index++;
      } else if ((index >= 4 && index <= 5) &&
          RegExp(r'\d').hasMatch(newText[i])) {
        buffer.write(newText[i]);
        index++;
      } else if (index == 6) {
        buffer.write('-');
        i--; // Don't consume the character
        index++;
      } else if (index >= 7 && RegExp(r'\d').hasMatch(newText[i])) {
        buffer.write(newText[i]);
        index++;
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Custom input formatter for Philippine phone numbers
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Return if deleting
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    String newText = newValue.text;
    
    // If the text doesn't start with +63, add it
    if (!newText.startsWith('+63') && newText.isNotEmpty) {
      if (newText.startsWith('+')) {
        if (newText.length > 1 && newText[1] != '6') {
          newText = '+6' + newText.substring(1);
        }
        if (newText.length > 2 && newText[2] != '3') {
          newText = '+63' + newText.substring(2);
        }
      } else {
        newText = '+63' + newText;
      }
    }
    
    // Ensure only digits after +63
    final buffer = StringBuffer();
    buffer.write('+63');
    
    // Only add digits after +63, up to 10 digits
    int digitCount = 0;
    for (int i = 3; i < newText.length && digitCount < 10; i++) {
      if (RegExp(r'\d').hasMatch(newText[i])) {
        buffer.write(newText[i]);
        digitCount++;
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
