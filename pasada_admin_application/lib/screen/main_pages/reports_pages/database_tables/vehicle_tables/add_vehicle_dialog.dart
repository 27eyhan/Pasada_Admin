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
      setState(() { _isLoading = true; });

      final String routeIdText = _routeIdController.text.trim();
      final int? routeId = int.tryParse(routeIdText);

      final String capacityText = _passengerCapacityController.text.trim();
      final int? capacity = int.tryParse(capacityText);

      try {
        // 0. Validate route_id exists in driverRouteTable
        if (routeId != null) {
          final routeCheckResponse = await widget.supabase
              .from('driverRouteTable') // Correct table name
              .select('route_id')
              .eq('route_id', routeId)
              .limit(1);
          
          final List routeList = routeCheckResponse as List;
          if (routeList.isEmpty) {
             setState(() { _isLoading = false; });
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Error: Route ID $routeId does not exist.')),
             );
             return; // Stop execution if route ID is invalid
          }
        } else {
          setState(() { _isLoading = false; });
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
          'vehicle_location': _vehicleLocationController.text.trim(),
          'created_at': createdAt,
        };

        // 4. Insert into Supabase
        await widget.supabase.from('vehicleTable').insert(newVehicleData);

        setState(() { _isLoading = false; });
        widget.onVehicleActionComplete(); // Refresh the table
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle added successfully! Vehicle ID: $nextVehicleId')),
        );

      } catch (e) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding vehicle: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
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
                      'Add New Vehicle',
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
                          controller: _plateNumberController,
                          decoration: const InputDecoration(labelText: 'Plate Number'),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter plate number' : null,
                        ),
                         SizedBox(height: 8),
                        TextFormField(
                          controller: _routeIdController,
                          decoration: const InputDecoration(labelText: 'Route ID'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter route ID';
                            if (int.tryParse(value) == null) return 'Please enter a valid number';
                            return null;
                          },
                        ),
                         SizedBox(height: 8),
                        TextFormField(
                          controller: _passengerCapacityController,
                          decoration: const InputDecoration(labelText: 'Passenger Capacity'),
                          keyboardType: TextInputType.number,
                           validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter capacity';
                            if (int.tryParse(value) == null) return 'Please enter a valid number';
                            return null;
                          },
                        ),
                        SizedBox(height: 8),
                         TextFormField(
                          controller: _vehicleLocationController,
                          decoration: const InputDecoration(labelText: 'Vehicle Location'),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter vehicle location' : null,
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
                           onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8.0),
                        ElevatedButton(
                           style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Palette.whiteColor,
                           ),
                           onPressed: _isLoading ? null : _saveVehicle,
                           child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Palette.whiteColor))
                              : const Text('Save Vehicle'),
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