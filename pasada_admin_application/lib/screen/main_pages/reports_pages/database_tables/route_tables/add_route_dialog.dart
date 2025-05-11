import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';

class AddRouteDialog extends StatefulWidget {
  final SupabaseClient supabase;
  final VoidCallback onRouteActionComplete;

  const AddRouteDialog({
    Key? key,
    required this.supabase,
    required this.onRouteActionComplete,
  }) : super(key: key);

  @override
  _AddRouteDialogState createState() => _AddRouteDialogState();
}

class _AddRouteDialogState extends State<AddRouteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _startingPlaceController = TextEditingController();
  final _startingLocationController = TextEditingController();
  final _intermediate1PlaceController = TextEditingController();
  final _intermediateLocation1Controller = TextEditingController();
  final _intermediate2PlaceController = TextEditingController();
  final _intermediateLocation2Controller = TextEditingController();
  final _endingPlaceController = TextEditingController();
  final _endingLocationController = TextEditingController();
  final _routeController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _startingPlaceController.dispose();
    _startingLocationController.dispose();
    _intermediate1PlaceController.dispose();
    _intermediateLocation1Controller.dispose();
    _intermediate2PlaceController.dispose();
    _intermediateLocation2Controller.dispose();
    _endingPlaceController.dispose();
    _endingLocationController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  Future<void> _saveRoute() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      try {
        // 1. Find the highest current route_id
        final List<dynamic> response = await widget.supabase
            .from('driverRouteTable')
            .select('route_id')
            .order('route_id', ascending: false)
            .limit(1);

        int nextRouteId = 1; // Default if table is empty
        if (response.isNotEmpty) {
          final int? highestId = response[0]['route_id'];
          if (highestId != null) {
            nextRouteId = highestId + 1;
          }
        }

        // 2. Get current timestamp
        final String createdAt = DateTime.now().toIso8601String();

        // 3. Prepare data for insertion (handle optional fields)
        final newRouteData = {
          'route_id': nextRouteId,
          'starting_place': _startingPlaceController.text.trim(),
          'starting_location': _startingLocationController.text.trim(),
          'intermediate1_place': _intermediate1PlaceController.text.trim(),
          'intermediate_location1': _intermediateLocation1Controller.text.trim(),
          'intermediate2_place': _intermediate2PlaceController.text.trim(),
          'intermediate_location2': _intermediateLocation2Controller.text.trim(),
          'ending_place': _endingPlaceController.text.trim(),
          'ending_location': _endingLocationController.text.trim(),
          'route': _routeController.text.trim(),
          'created_at': createdAt,
        };

        // 4. Insert into Supabase
        await widget.supabase.from('driverRouteTable').insert(newRouteData);

        setState(() { _isLoading = false; });
        widget.onRouteActionComplete(); // Refresh the table
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Route added successfully! Route ID: $nextRouteId')),
        );

      } catch (e) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding route: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Adjust width if needed, routes have many fields
    final double dialogWidth = screenWidth * 0.4; 

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
                  Icon(Icons.route, color: Palette.greenColor, size: 48),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'Add New Route',
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
                      'Please fill in the details to add a new route to the system.',
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
                          controller: _startingPlaceController,
                          label: 'Starting Place',
                          icon: Icons.location_on_outlined,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        _buildFormField(
                          controller: _startingLocationController,
                          label: 'Starting Location (Lat, Lng)',
                          icon: Icons.map_outlined,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        _buildFormField(
                          controller: _intermediate1PlaceController,
                          label: 'Intermediate Place 1',
                          icon: Icons.location_on_outlined,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        _buildFormField(
                          controller: _intermediateLocation1Controller,
                          label: 'Intermediate Location 1',
                          icon: Icons.map_outlined,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        _buildFormField(
                          controller: _intermediate2PlaceController,
                          label: 'Intermediate Place 2',
                          icon: Icons.location_on_outlined,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        _buildFormField(
                          controller: _intermediateLocation2Controller,
                          label: 'Intermediate Location 2',
                          icon: Icons.map_outlined,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        _buildFormField(
                          controller: _endingPlaceController,
                          label: 'Ending Place',
                          icon: Icons.location_on_outlined,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        _buildFormField(
                          controller: _endingLocationController,
                          label: 'Ending Location (Lat, Lng)',
                          icon: Icons.map_outlined,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        _buildFormField(
                          controller: _routeController,
                          label: 'Route Name/Code',
                          icon: Icons.label_outline,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
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
                              backgroundColor: Palette.greenColor,
                              foregroundColor: Palette.whiteColor,
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                              elevation: 3,
                              minimumSize: Size(140, 50),
                              shadowColor: Palette.greenColor.withAlpha(128),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                           ),
                           onPressed: _isLoading ? null : _saveRoute,
                           child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Palette.whiteColor))
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.save, size: 20),
                                    SizedBox(width: 8),
                                    Text('Save Route', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
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
          contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }
} 