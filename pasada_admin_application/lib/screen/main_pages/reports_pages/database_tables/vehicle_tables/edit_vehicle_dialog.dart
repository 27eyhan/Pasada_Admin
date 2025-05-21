import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/main_pages/fleet_pages/fleet_data.dart'; // Import FleetData

class EditVehicleDialog extends StatefulWidget {
  final SupabaseClient supabase;
  final VoidCallback onVehicleActionComplete;
  final Map<String, dynamic> vehicleData; // Required data for editing
  final bool openedFromFleetData; // Add flag

  const EditVehicleDialog({
    Key? key,
    required this.supabase,
    required this.onVehicleActionComplete,
    required this.vehicleData,
    this.openedFromFleetData = false, // Default to false
  }) : super(key: key);

  @override
  _EditVehicleDialogState createState() => _EditVehicleDialogState();
}

class _EditVehicleDialogState extends State<EditVehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _plateNumberController = TextEditingController();
  final _routeIdController = TextEditingController();
  final _passengerCapacityController = TextEditingController();
  final _vehicleLocationController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields with existing vehicle data
    _plateNumberController.text =
        widget.vehicleData['plate_number']?.toString() ?? '';
    _routeIdController.text = widget.vehicleData['route_id']?.toString() ?? '';
    _passengerCapacityController.text =
        widget.vehicleData['passenger_capacity']?.toString() ?? '';
    _vehicleLocationController.text =
        widget.vehicleData['vehicle_location']?.toString() ?? '';
  }

  @override
  void dispose() {
    _plateNumberController.dispose();
    _routeIdController.dispose();
    _passengerCapacityController.dispose();
    _vehicleLocationController.dispose();
    super.dispose();
  }

  Future<void> _updateVehicle() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String routeIdText = _routeIdController.text.trim();
      final int? routeId = int.tryParse(routeIdText);

      final String capacityText = _passengerCapacityController.text.trim();
      final int? capacity = int.tryParse(capacityText);

      try {
        // 0. Validate route_id exists in driverRouteTable before updating
        if (routeId != null) {
          final routeCheckResponse = await widget.supabase
              .from('driverRouteTable')
              .select('route_id')
              .eq('route_id', routeId)
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
            return; // Stop execution
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Invalid Route ID format.')),
          );
          return; // Stop execution
        }

        // 1. Prepare data for update
        final vehicleDetails = {
          'plate_number': _plateNumberController.text.trim(),
          'route_id': routeId,
          'passenger_capacity': capacity,
        };

        final vehicleId = widget.vehicleData['vehicle_id'];
        await widget.supabase
            .from('vehicleTable')
            .update(vehicleDetails)
            .match({'vehicle_id': vehicleId});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle $vehicleId updated successfully!')),
        );

        setState(() {
          _isLoading = false;
        });
        widget.onVehicleActionComplete(); // Refresh the table
        Navigator.of(context).pop(); // Close the dialog
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating vehicle: ${e.toString()}')),
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
                  'Edit Vehicle Information',
                  style: TextStyle(
                    fontSize: 22.0,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    color: Palette.orangeColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Non-editable fields
              _buildInfoRow(
                  'Vehicle ID:', widget.vehicleData['vehicle_id'].toString()),
              _buildInfoRow(
                  'Created At:', widget.vehicleData['created_at'].toString()),
              SizedBox(height: 16),

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
                    //   label: 'Vehicle Location (Optional)',
                    //   icon: Icons.location_on,
                    // ),
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                      elevation: 3,
                      minimumSize: Size(140, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () {
                            // Close current dialog first
                            Navigator.of(context).pop();

                            // If opened from FleetData, reopen it
                            if (widget.openedFromFleetData) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return FleetData(
                                    vehicle: widget.vehicleData,
                                    supabase: widget.supabase,
                                    onVehicleActionComplete:
                                        widget.onVehicleActionComplete,
                                  );
                                },
                              );
                            }
                          },
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
                      backgroundColor: Palette.orangeColor,
                      foregroundColor: Palette.whiteColor,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                      elevation: 3,
                      minimumSize: Size(140, 50),
                      shadowColor: Palette.orangeColor.withAlpha(128),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    onPressed: _isLoading ? null : _updateVehicle,
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
                              Text('Save Changes',
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
    String? Function(String?)? validator,
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
