import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';

class AddVehicleDialog extends StatefulWidget {
  final SupabaseClient supabase;
  final VoidCallback onVehicleActionComplete;

  const AddVehicleDialog({
    Key? key,
    required this.supabase,
    required this.onVehicleActionComplete,
  }) : super(key: key);

  @override
  _AddVehicleDialogState createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends State<AddVehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _plateNumberController = TextEditingController();
  final _routeIdController = TextEditingController();
  final _passengerCapacityController = TextEditingController();
  // Vehicle Location might be handled differently (e.g., GPS)
  // For now, let's make it an optional text field
  final _vehicleLocationController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _plateNumberController.dispose();
    _routeIdController.dispose();
    _passengerCapacityController.dispose();
    _vehicleLocationController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String routeIdText = _routeIdController.text.trim();
      final int? routeId = int.tryParse(routeIdText);

      final String capacityText = _passengerCapacityController.text.trim();
      final int? capacity = int.tryParse(capacityText);

      try {
        // 0. Validate route_id exists in driverRouteTable
        if (routeId != null) {
          final routeCheckResponse = await widget.supabase
              .from('official_routes') // Correct table name
              .select('officialroute_id')
              .eq('officialroute_id', routeId)
              .limit(1);

          final List routeList = routeCheckResponse as List;
          if (routeList.isEmpty) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Error: Route ID $routeId does not exist.')),
            );
            return; // Stop execution if route ID is invalid
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Invalid Route ID format.')),
          );
          return;
        }

        // 1. Find the highest current vehicle_id (optional, could let DB handle)
        // For consistency with AddDriverDialog, we'll generate it.
        final List<dynamic> response = await widget.supabase
            .from('vehicleTable')
            .select('vehicle_id')
            .order('vehicle_id', ascending: false)
            .limit(1);

        int nextVehicleId = 1; // Default if table is empty
        if (response.isNotEmpty) {
          final int? highestId = response[0]['vehicle_id'];
          if (highestId != null) {
            nextVehicleId = highestId + 1;
          }
        }

        // 2. Get current timestamp
        final String createdAt = DateTime.now().toIso8601String();

        // 3. Prepare data for insertion
        final newVehicleData = {
          'vehicle_id': nextVehicleId,
          'plate_number': _plateNumberController.text.trim(),
          'route_id': routeId,
          'passenger_capacity': capacity,
          'created_at': createdAt,
        };

        // 4. Insert into Supabase
        await widget.supabase.from('vehicleTable').insert(newVehicleData);

        setState(() {
          _isLoading = false;
        });
        widget.onVehicleActionComplete(); // Refresh the table
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Vehicle added successfully! Vehicle ID: $nextVehicleId')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding vehicle: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth * 0.35;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Palette.greenColor, width: 2),
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
              Icon(Icons.directions_car_outlined,
                  color: Palette.greenColor, size: 48),
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  'Add New Vehicle',
                  style: TextStyle(
                    fontSize: 22.0,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    color: Palette.greenColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Informative text
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Please fill in the details to add a new vehicle to the system.',
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
                      controller: _plateNumberController,
                      label: 'Plate Number',
                      icon: Icons.credit_card,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter plate number'
                          : null,
                    ),
                    _buildFormField(
                      controller: _routeIdController,
                      label: 'Route ID',
                      icon: Icons.route,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter route ID';
                        if (int.tryParse(value) == null)
                          return 'Please enter a valid number';
                        return null;
                      },
                    ),
                    _buildFormField(
                      controller: _passengerCapacityController,
                      label: 'Passenger Capacity',
                      icon: Icons.people,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter capacity';
                        if (int.tryParse(value) == null)
                          return 'Please enter a valid number';
                        return null;
                      },
                    ),
                    // _buildFormField(
                    //   controller: _vehicleLocationController,
                    //   label: 'Vehicle Location',
                    //   icon: Icons.location_on,
                    //   validator: (value) => value == null || value.isEmpty ? 'Please enter vehicle location' : null,
                    // ),
                  ],
                ),
              ),

              // Reduce spacing before buttons
              const SizedBox(height: 16.0),

              // Action buttons with enhanced styling
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                      elevation: 3,
                      minimumSize: Size(140, 50),
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
                        Icon(Icons.cancel, size: 20),
                        SizedBox(width: 8),
                        Text('Cancel',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.greenColor,
                      foregroundColor: Palette.whiteColor,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                      elevation: 3,
                      minimumSize: Size(140, 50),
                      shadowColor: Palette.greenColor.withAlpha(128),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    onPressed: _isLoading ? null : _saveVehicle,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Palette.whiteColor))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.save, size: 20),
                              SizedBox(width: 8),
                              Text('Save Vehicle',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16)),
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
          prefixIcon: Icon(icon, color: Palette.greenColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Palette.greenColor, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding:
              EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }
}
