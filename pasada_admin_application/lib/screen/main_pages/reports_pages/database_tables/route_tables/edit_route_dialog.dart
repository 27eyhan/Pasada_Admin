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
                      'Edit Route',
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
                          controller: _startingPlaceController,
                          decoration: const InputDecoration(labelText: 'Starting Place'),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                         SizedBox(height: 8),
                         TextFormField(
                          controller: _startingLocationController,
                          decoration: const InputDecoration(labelText: 'Starting Location (Lat, Lng)'),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                         SizedBox(height: 8),
                         TextFormField(
                          controller: _intermediate1PlaceController,
                          decoration: const InputDecoration(labelText: 'Intermediate Place 1 (Optional)'),
                        ),
                         SizedBox(height: 8),
                         TextFormField(
                          controller: _intermediateLocation1Controller,
                          decoration: const InputDecoration(labelText: 'Intermediate Location 1 (Optional)'),
                        ),
                        SizedBox(height: 8),
                         TextFormField(
                          controller: _intermediate2PlaceController,
                          decoration: const InputDecoration(labelText: 'Intermediate Place 2 (Optional)'),
                        ),
                        SizedBox(height: 8),
                         TextFormField(
                          controller: _intermediateLocation2Controller,
                          decoration: const InputDecoration(labelText: 'Intermediate Location 2 (Optional)'),
                        ),
                         SizedBox(height: 8),
                         TextFormField(
                          controller: _endingPlaceController,
                          decoration: const InputDecoration(labelText: 'Ending Place'),
                           validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                         SizedBox(height: 8),
                         TextFormField(
                          controller: _endingLocationController,
                          decoration: const InputDecoration(labelText: 'Ending Location (Lat, Lng)'),
                           validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                         SizedBox(height: 8),
                         TextFormField(
                          controller: _routeController,
                          decoration: const InputDecoration(labelText: 'Route Name/Code'),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
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
                           onPressed: _isLoading ? null : _updateRoute,
                           child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Palette.whiteColor))
                              : const Text('Save Changes'),
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