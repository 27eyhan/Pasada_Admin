import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';

class EditRouteDialog extends StatefulWidget {
  final SupabaseClient supabase;
  final VoidCallback onRouteActionComplete;
  final Map<String, dynamic> routeData; // Required data for editing

  const EditRouteDialog({
    Key? key,
    required this.supabase,
    required this.onRouteActionComplete,
    required this.routeData,
  }) : super(key: key);

  @override
  _EditRouteDialogState createState() => _EditRouteDialogState();
}

class _EditRouteDialogState extends State<EditRouteDialog> {
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
  void initState() {
    super.initState();
    // Pre-fill fields with existing route data
    _startingPlaceController.text = widget.routeData['starting_place']?.toString() ?? '';
    _startingLocationController.text = widget.routeData['starting_location']?.toString() ?? '';
    _intermediate1PlaceController.text = widget.routeData['intermediate1_place']?.toString() ?? '';
    _intermediateLocation1Controller.text = widget.routeData['intermediate_location1']?.toString() ?? '';
    _intermediate2PlaceController.text = widget.routeData['intermediate2_place']?.toString() ?? '';
    _intermediateLocation2Controller.text = widget.routeData['intermediate_location2']?.toString() ?? '';
    _endingPlaceController.text = widget.routeData['ending_place']?.toString() ?? '';
    _endingLocationController.text = widget.routeData['ending_location']?.toString() ?? '';
    _routeController.text = widget.routeData['route']?.toString() ?? '';
  }

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

  Future<void> _updateRoute() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      try {
        // 1. Prepare data for update (handle optional fields)
        final routeDetails = {
          'starting_place': _startingPlaceController.text.trim(),
          'starting_location': _startingLocationController.text.trim(),
          'intermediate1_place': _intermediate1PlaceController.text.trim().isNotEmpty ? _intermediate1PlaceController.text.trim() : null,
          'intermediate_location1': _intermediateLocation1Controller.text.trim().isNotEmpty ? _intermediateLocation1Controller.text.trim() : null,
          'intermediate2_place': _intermediate2PlaceController.text.trim().isNotEmpty ? _intermediate2PlaceController.text.trim() : null,
          'intermediate_location2': _intermediateLocation2Controller.text.trim().isNotEmpty ? _intermediateLocation2Controller.text.trim() : null,
          'ending_place': _endingPlaceController.text.trim(),
          'ending_location': _endingLocationController.text.trim(),
          'route': _routeController.text.trim(),
        };

        final routeId = widget.routeData['route_id'];
        await widget.supabase
            .from('driverRouteTable')
            .update(routeDetails)
            .match({'route_id': routeId});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Route $routeId updated successfully!')),
        );

        setState(() { _isLoading = false; });
        widget.onRouteActionComplete(); // Refresh the table
        Navigator.of(context).pop(); // Close the dialog

      } catch (e) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating route: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth * 0.4; 

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
                      'Edit Route Information',
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
                  _buildInfoRow('Route ID:', widget.routeData['route_id'].toString()),
                  _buildInfoRow('Created At:', widget.routeData['created_at'].toString()),
                  SizedBox(height: 16),
                  
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
                          label: 'Intermediate Place 1 (Optional)',
                          icon: Icons.location_on_outlined,
                        ),
                        _buildFormField(
                          controller: _intermediateLocation1Controller,
                          label: 'Intermediate Location 1 (Optional)',
                          icon: Icons.map_outlined,
                        ),
                        _buildFormField(
                          controller: _intermediate2PlaceController,
                          label: 'Intermediate Place 2 (Optional)',
                          icon: Icons.location_on_outlined,
                        ),
                        _buildFormField(
                          controller: _intermediateLocation2Controller,
                          label: 'Intermediate Location 2 (Optional)',
                          icon: Icons.map_outlined,
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
                           onPressed: _isLoading ? null : _updateRoute,
                           child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Palette.whiteColor))
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.save, size: 20),
                                    SizedBox(width: 8),
                                    Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
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
          contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }
} 