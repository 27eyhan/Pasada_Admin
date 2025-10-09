import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'dart:convert';

class EditRouteDialog extends StatefulWidget {
  final SupabaseClient supabase;
  final VoidCallback onRouteActionComplete;
  final Map<String, dynamic> routeData; // Required data for editing

  const EditRouteDialog({
    super.key,
    required this.supabase,
    required this.onRouteActionComplete,
    required this.routeData,
  });

  @override
  _EditRouteDialogState createState() => _EditRouteDialogState();
}

class _EditRouteDialogState extends State<EditRouteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _originNameController = TextEditingController();
  final _originLatController = TextEditingController();
  final _originLngController = TextEditingController();
  final _destinationNameController = TextEditingController();
  final _destinationLatController = TextEditingController();
  final _destinationLngController = TextEditingController();
  final _routeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _intermediateCoordinatesController = TextEditingController();
  String _status = 'Active';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields with existing route data
    _originNameController.text =
        widget.routeData['origin_name']?.toString() ?? '';
    _originLatController.text =
        widget.routeData['origin_lat']?.toString() ?? '';
    _originLngController.text =
        widget.routeData['origin_lng']?.toString() ?? '';
    _destinationNameController.text =
        widget.routeData['destination_name']?.toString() ?? '';
    _destinationLatController.text =
        widget.routeData['destination_lat']?.toString() ?? '';
    _destinationLngController.text =
        widget.routeData['destination_lng']?.toString() ?? '';
    _routeNameController.text =
        widget.routeData['route_name']?.toString() ?? '';
    _descriptionController.text =
        widget.routeData['description']?.toString() ?? '';
    // Normalize status value to ensure it matches dropdown options
    String statusFromData = widget.routeData['status']?.toString() ?? 'Active';
    // Handle case sensitivity and ensure valid value
    switch (statusFromData.toLowerCase()) {
      case 'active':
        _status = 'Active';
        break;
      case 'processing':
        _status = 'Processing';
        break;
      case 'inactive':
        _status = 'Inactive';
        break;
      default:
        _status = 'Active'; // Default fallback
    }

    // Handle intermediate coordinates (JSON)
    if (widget.routeData['intermediate_coordinates'] != null) {
      try {
        final prettyJson = const JsonEncoder.withIndent('  ')
            .convert(widget.routeData['intermediate_coordinates']);
        _intermediateCoordinatesController.text = prettyJson;
      } catch (e) {
        // If it's already a string or there's an error, use the raw value
        _intermediateCoordinatesController.text =
            widget.routeData['intermediate_coordinates'].toString();
      }
    }
  }

  @override
  void dispose() {
    _originNameController.dispose();
    _originLatController.dispose();
    _originLngController.dispose();
    _destinationNameController.dispose();
    _destinationLatController.dispose();
    _destinationLngController.dispose();
    _routeNameController.dispose();
    _descriptionController.dispose();
    _intermediateCoordinatesController.dispose();
    super.dispose();
  }

  Future<void> _updateRoute() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Parse intermediate coordinates JSON
        dynamic intermediateCoordinates;
        try {
          if (_intermediateCoordinatesController.text.isNotEmpty) {
            intermediateCoordinates =
                json.decode(_intermediateCoordinatesController.text);
          } else {
            // Default empty array if no coordinates provided
            intermediateCoordinates = [];
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Invalid JSON format for intermediate coordinates')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Prepare data for update
        final routeDetails = {
          'route_name': _routeNameController.text.trim(),
          'origin_name': _originNameController.text.trim(),
          'origin_lat': _originLatController.text.trim(),
          'origin_lng': _originLngController.text.trim(),
          'destination_name': _destinationNameController.text.trim(),
          'destination_lat': _destinationLatController.text.trim(),
          'destination_lng': _destinationLngController.text.trim(),
          'description': _descriptionController.text.trim(),
          'intermediate_coordinates': intermediateCoordinates,
          'status': _status,
        };

        final routeId = widget.routeData['officialroute_id'];
        await widget.supabase
            .from('official_routes')
            .update(routeDetails)
            .match({'officialroute_id': routeId});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Route $routeId updated successfully!')),
        );

        setState(() {
          _isLoading = false;
        });
        widget.onRouteActionComplete(); // Refresh the table
        Navigator.of(context).pop(); // Close the dialog
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
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
              _buildInfoRow(
                  'Route ID:', widget.routeData['officialroute_id'].toString()),
              _buildInfoRow(
                  'Created At:', widget.routeData['created_at'].toString()),
              SizedBox(height: 16),

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
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    _buildFormField(
                      controller: _originNameController,
                      label: 'Origin Place',
                      icon: Icons.location_on_outlined,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            controller: _originLatController,
                            label: 'Origin Latitude',
                            icon: Icons.map_outlined,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            controller: _originLngController,
                            label: 'Origin Longitude',
                            icon: Icons.map_outlined,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    _buildFormField(
                      controller: _destinationNameController,
                      label: 'Destination Place',
                      icon: Icons.location_on_outlined,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            controller: _destinationLatController,
                            label: 'Destination Latitude',
                            icon: Icons.map_outlined,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            controller: _destinationLngController,
                            label: 'Destination Longitude',
                            icon: Icons.map_outlined,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    _buildFormField(
                      controller: _intermediateCoordinatesController,
                      label: 'Intermediate Coordinates (JSON)',
                      icon: Icons.route_outlined,
                      maxLines: 5,
                      hintText:
                          '[{"lat": 14.123, "lng": 121.456, "name": "Stop 1"}, ...]',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null; // Optional field
                        }
                        try {
                          json.decode(value);
                          return null;
                        } catch (e) {
                          return 'Invalid JSON format';
                        }
                      },
                    ),
                    _buildFormField(
                      controller: _descriptionController,
                      label: 'Description',
                      icon: Icons.description_outlined,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                      maxLines: 2,
                    ),
                    // Status dropdown
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.toggle_on_outlined,
                              color: Palette.orangeColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                                color: Palette.orangeColor, width: 2.0),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0),
                        ),
                        initialValue: _status,
                        items: ['Active', 'Processing', 'Inactive']
                            .map((String status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _status = newValue;
                            });
                          }
                        },
                      ),
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
                    onPressed: _isLoading ? null : _updateRoute,
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
        maxLines: maxLines,
      ),
    );
  }
}
