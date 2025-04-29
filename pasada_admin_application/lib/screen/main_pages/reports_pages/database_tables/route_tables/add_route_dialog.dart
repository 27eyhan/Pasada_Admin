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
                      'Add New Route',
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
                          decoration: const InputDecoration(labelText: 'Intermediate Place 1'),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                         SizedBox(height: 8),
                         TextFormField(
                          controller: _intermediateLocation1Controller,
                          decoration: const InputDecoration(labelText: 'Intermediate Location 1'),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 8),
                         TextFormField(
                          controller: _intermediate2PlaceController,
                          decoration: const InputDecoration(labelText: 'Intermediate Place 2'),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 8),
                         TextFormField(
                          controller: _intermediateLocation2Controller,
                          decoration: const InputDecoration(labelText: 'Intermediate Location 2'),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
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
                           onPressed: _isLoading ? null : _saveRoute,
                           child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Palette.whiteColor))
                              : const Text('Save Route'),
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