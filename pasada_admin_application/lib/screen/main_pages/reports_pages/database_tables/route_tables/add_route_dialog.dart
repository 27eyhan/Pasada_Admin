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
  final _originNameController = TextEditingController();
  final _destinationNameController = TextEditingController();
  final _routeNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _originNameController.dispose();
    _destinationNameController.dispose();
    _routeNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveRoute() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      try {
        // 1. Find the highest current officialroute_id
        final List<dynamic> response = await widget.supabase
            .from('official_routes')
            .select('officialroute_id')
            .order('officialroute_id', ascending: false)
            .limit(1);

        int nextRouteId = 1; // Default if table is empty
        if (response.isNotEmpty) {
          final int? highestId = response[0]['officialroute_id'];
          if (highestId != null) {
            nextRouteId = highestId + 1;
          }
        }

        // 2. Get current timestamp
        final String createdAt = DateTime.now().toIso8601String();

        // 3. Prepare data for insertion
        final newRouteData = {
          'officialroute_id': nextRouteId,
          'route_name': _routeNameController.text.trim(),
          'origin_name': _originNameController.text.trim(),
          'destination_name': _destinationNameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'status': 'Processing', // Default to "Processing"
          'created_at': createdAt,
        };

        // 4. Insert into Supabase
        await widget.supabase.from('official_routes').insert(newRouteData);

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
                          controller: _routeNameController,
                          label: 'Route Name/Code',
                          icon: Icons.label_outline,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        _buildFormField(
                          controller: _originNameController,
                          label: 'Origin Place',
                          icon: Icons.location_on_outlined,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        _buildFormField(
                          controller: _destinationNameController,
                          label: 'Destination Place',
                          icon: Icons.location_on_outlined,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                        _buildFormField(
                          controller: _descriptionController,
                          label: 'Description',
                          icon: Icons.description_outlined,
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                          maxLines: 2,
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
    int? maxLines = 1,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
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
        maxLines: maxLines,
      ),
    );
  }
} 