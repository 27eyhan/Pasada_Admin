import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/widgets/responsive_dialog.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddRouteDialog extends StatefulWidget {
  final SupabaseClient supabase;
  final VoidCallback? onRouteAdded;

  const AddRouteDialog({
    super.key,
    required this.supabase,
    this.onRouteAdded,
  });

  @override
  State<AddRouteDialog> createState() => _AddRouteDialogState();
}

class _AddRouteDialogState extends State<AddRouteDialog> {
  final TextEditingController _routeNameController = TextEditingController();
  final TextEditingController _originNameController = TextEditingController();
  final TextEditingController _destinationNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _originLatController = TextEditingController();
  final TextEditingController _originLngController = TextEditingController();
  final TextEditingController _destinationLatController = TextEditingController();
  final TextEditingController _destinationLngController = TextEditingController();
  
  String _selectedStatus = 'active';
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Intermediate coordinates management
  final List<Map<String, dynamic>> _intermediateCoordinates = [];

  @override
  void dispose() {
    _routeNameController.dispose();
    _originNameController.dispose();
    _destinationNameController.dispose();
    _descriptionController.dispose();
    _originLatController.dispose();
    _originLngController.dispose();
    _destinationLatController.dispose();
    _destinationLngController.dispose();
    super.dispose();
  }

  Future<void> _addRoute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare the route data (excluding officialroute_id as it's auto-incrementing)
      final routeData = {
        'route_name': _routeNameController.text.trim(),
        'origin_name': _originNameController.text.trim(),
        'destination_name': _destinationNameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'status': _selectedStatus,
        'origin_lat': _originLatController.text.trim().isEmpty ? null : _originLatController.text.trim(),
        'origin_lng': _originLngController.text.trim().isEmpty ? null : _originLngController.text.trim(),
        'destination_lat': _destinationLatController.text.trim().isEmpty ? null : _destinationLatController.text.trim(),
        'destination_lng': _destinationLngController.text.trim().isEmpty ? null : _destinationLngController.text.trim(),
        'intermediate_coordinates': _intermediateCoordinates.isEmpty ? null : _intermediateCoordinates,
        'created_at': DateTime.now().toIso8601String(),
      };

      await widget.supabase
          .from('official_routes')
          .insert(routeData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Route added successfully'),
            backgroundColor: const Color(0xFF00CC58),
          ),
        );
        
        if (widget.onRouteAdded != null) {
          widget.onRouteAdded!();
        }
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding route: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return ResponsiveDialog(
      title: 'Add New Route',
      titleIcon: Icons.add_road,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFormFields(context, isDark),
              SizedBox(height: ResponsiveHelper.isMobile(context) ? 16.0 : ResponsiveHelper.getResponsiveCardPadding(context)),
              _buildActions(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields(BuildContext context, bool isDark) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = isMobile ? 16.0 : ResponsiveHelper.getResponsiveCardPadding(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: isDark ? Palette.darkBorder : Palette.lightBorder, width: 1.0),
      ),
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route Name
          _buildTextField(
            controller: _routeNameController,
            label: 'Route Name',
            hint: 'Enter route name (e.g., Route 1, Main Line)',
            isRequired: true,
            isDark: isDark,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 12.0 : 16.0),

          // Origin and Destination Row
          isMobile
              ? Column(
                  children: [
                    _buildTextField(
                      controller: _originNameController,
                      label: 'Origin',
                      hint: 'Enter origin location (e.g., Manila Terminal)',
                      isRequired: true,
                      isDark: isDark,
                      isMobile: isMobile,
                    ),
                    SizedBox(height: isMobile ? 12.0 : 16.0),
                    _buildTextField(
                      controller: _destinationNameController,
                      label: 'Destination',
                      hint: 'Enter destination location (e.g., Quezon City Terminal)',
                      isRequired: true,
                      isDark: isDark,
                      isMobile: isMobile,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _originNameController,
                        label: 'Origin',
                        hint: 'Enter origin location',
                        isRequired: true,
                        isDark: isDark,
                        isMobile: isMobile,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: _buildTextField(
                        controller: _destinationNameController,
                        label: 'Destination',
                        hint: 'Enter destination location',
                        isRequired: true,
                        isDark: isDark,
                        isMobile: isMobile,
                      ),
                    ),
                  ],
                ),
          SizedBox(height: isMobile ? 12.0 : 16.0),

          // Coordinates Section
          _buildCoordinatesSection(isDark, isMobile),
          SizedBox(height: isMobile ? 12.0 : 16.0),

          // Status Dropdown
          _buildStatusDropdown(isDark, isMobile),
          SizedBox(height: isMobile ? 12.0 : 16.0),

          // Description
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Enter route description (optional)',
            isRequired: false,
            isDark: isDark,
            isMobile: isMobile,
            maxLines: isMobile ? 2 : 3,
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinatesSection(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Coordinates (Important)',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 12,
              tablet: 13,
              desktop: 14,
            ),
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
        SizedBox(height: isMobile ? 6.0 : 8.0),
        Text(
          'Add precise coordinates for better route mapping',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 10,
              tablet: 11,
              desktop: 12,
            ),
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
        SizedBox(height: isMobile ? 8.0 : 12.0),
        
        // Origin Coordinates
        Text(
          'Origin Coordinates',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 11,
              tablet: 12,
              desktop: 13,
            ),
            color: isDark ? Palette.darkText : Palette.lightText,
          ),
        ),
        SizedBox(height: isMobile ? 6.0 : 8.0),
        isMobile
            ? Column(
                children: [
                  _buildCoordinateField(
                    controller: _originLatController,
                    label: 'Latitude',
                    hint: '14.5995',
                    isDark: isDark,
                    isMobile: isMobile,
                  ),
                  SizedBox(height: 8.0),
                  _buildCoordinateField(
                    controller: _originLngController,
                    label: 'Longitude',
                    hint: '120.9842',
                    isDark: isDark,
                    isMobile: isMobile,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildCoordinateField(
                      controller: _originLatController,
                      label: 'Latitude',
                      hint: '14.5995',
                      isDark: isDark,
                      isMobile: isMobile,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: _buildCoordinateField(
                      controller: _originLngController,
                      label: 'Longitude',
                      hint: '120.9842',
                      isDark: isDark,
                      isMobile: isMobile,
                    ),
                  ),
                ],
              ),
        
        SizedBox(height: isMobile ? 12.0 : 16.0),
        
        // Destination Coordinates
        Text(
          'Destination Coordinates',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 11,
              tablet: 12,
              desktop: 13,
            ),
            color: isDark ? Palette.darkText : Palette.lightText,
          ),
        ),
        SizedBox(height: isMobile ? 6.0 : 8.0),
        isMobile
            ? Column(
                children: [
                  _buildCoordinateField(
                    controller: _destinationLatController,
                    label: 'Latitude',
                    hint: '14.6760',
                    isDark: isDark,
                    isMobile: isMobile,
                  ),
                  SizedBox(height: 8.0),
                  _buildCoordinateField(
                    controller: _destinationLngController,
                    label: 'Longitude',
                    hint: '121.0437',
                    isDark: isDark,
                    isMobile: isMobile,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildCoordinateField(
                      controller: _destinationLatController,
                      label: 'Latitude',
                      hint: '14.6760',
                      isDark: isDark,
                      isMobile: isMobile,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: _buildCoordinateField(
                      controller: _destinationLngController,
                      label: 'Longitude',
                      hint: '121.0437',
                      isDark: isDark,
                      isMobile: isMobile,
                    ),
                  ),
                ],
              ),
        
        SizedBox(height: isMobile ? 12.0 : 16.0),
        
        // Intermediate Coordinates Section
        _buildIntermediateCoordinatesSection(isDark, isMobile),
      ],
    );
  }

  Widget _buildCoordinateField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 10,
              tablet: 11,
              desktop: 12,
            ),
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
        SizedBox(height: isMobile ? 4.0 : 6.0),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 11,
                tablet: 12,
                desktop: 13,
              ),
            ),
            filled: true,
            fillColor: isDark ? Palette.darkBackground : Palette.lightBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.0),
              borderSide: BorderSide(
                color: isDark ? Palette.darkBorder : Palette.lightBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.0),
              borderSide: BorderSide(
                color: isDark ? Palette.darkBorder : Palette.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.0),
              borderSide: const BorderSide(
                color: Color(0xFF00CC58),
                width: 1.5,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 8.0, 
              vertical: isMobile ? 8.0 : 10.0,
            ),
          ),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 11,
              tablet: 12,
              desktop: 13,
            ),
            color: isDark ? Palette.darkText : Palette.lightText,
          ),
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              final double? parsed = double.tryParse(value.trim());
              if (parsed == null) {
                return 'Invalid number';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildIntermediateCoordinatesSection(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Intermediate Waypoints',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
                color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _addIntermediateWaypoint,
              icon: Icon(
                Icons.add_location,
                size: 16,
                color: isDark ? Palette.darkText : Palette.lightText,
              ),
              label: Text(
                'Add Waypoint',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 11,
                    tablet: 12,
                    desktop: 13,
                  ),
                  color: isDark ? Palette.darkText : Palette.lightText,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? Palette.darkBorder : Palette.lightBorder,
                ),
                backgroundColor: isDark ? Palette.darkCard : Palette.lightCard,
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 6.0 : 8.0),
        Text(
          'Add intermediate stops along the route (optional)',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 10,
              tablet: 11,
              desktop: 12,
            ),
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
        SizedBox(height: isMobile ? 8.0 : 12.0),
        
        // List of intermediate waypoints
        if (_intermediateCoordinates.isEmpty)
          Container(
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
            decoration: BoxDecoration(
              color: isDark ? Palette.darkBackground : Palette.lightBackground,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: isDark ? Palette.darkBorder : Palette.lightBorder,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'No intermediate waypoints added yet. Click "Add Waypoint" to add stops along the route.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        mobile: 10,
                        tablet: 11,
                        desktop: 12,
                      ),
                      color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ..._intermediateCoordinates.asMap().entries.map((entry) {
            final index = entry.key;
            final waypoint = entry.value;
            return _buildWaypointItem(index, waypoint, isDark, isMobile);
          }
        ),
      ],
    );
  }

  Widget _buildWaypointItem(int index, Map<String, dynamic> waypoint, bool isDark, bool isMobile) {
    final latController = TextEditingController(text: waypoint['lat']?.toString() ?? '');
    final lngController = TextEditingController(text: waypoint['lng']?.toString() ?? '');
    
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8.0 : 12.0),
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDark ? Palette.darkBorder : Palette.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: const Color(0xFF00CC58),
              ),
              const SizedBox(width: 8.0),
              Text(
                'Waypoint ${index + 1}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 11,
                    tablet: 12,
                    desktop: 13,
                  ),
                  color: isDark ? Palette.darkText : Palette.lightText,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _removeIntermediateWaypoint(index),
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red,
                ),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8.0 : 12.0),
          isMobile
              ? Column(
                  children: [
                    _buildWaypointCoordinateField(
                      controller: latController,
                      label: 'Latitude',
                      hint: '14.5995',
                      isDark: isDark,
                      isMobile: isMobile,
                      onChanged: (value) {
                        setState(() {
                          _intermediateCoordinates[index]['lat'] = value.trim().isEmpty ? null : value.trim();
                        });
                      },
                    ),
                    SizedBox(height: 8.0),
                    _buildWaypointCoordinateField(
                      controller: lngController,
                      label: 'Longitude',
                      hint: '120.9842',
                      isDark: isDark,
                      isMobile: isMobile,
                      onChanged: (value) {
                        setState(() {
                          _intermediateCoordinates[index]['lng'] = value.trim().isEmpty ? null : value.trim();
                        });
                      },
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildWaypointCoordinateField(
                        controller: latController,
                        label: 'Latitude',
                        hint: '14.5995',
                        isDark: isDark,
                        isMobile: isMobile,
                        onChanged: (value) {
                          setState(() {
                            _intermediateCoordinates[index]['lat'] = value.trim().isEmpty ? null : value.trim();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: _buildWaypointCoordinateField(
                        controller: lngController,
                        label: 'Longitude',
                        hint: '120.9842',
                        isDark: isDark,
                        isMobile: isMobile,
                        onChanged: (value) {
                          setState(() {
                            _intermediateCoordinates[index]['lng'] = value.trim().isEmpty ? null : value.trim();
                          });
                        },
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  void _addIntermediateWaypoint() {
    setState(() {
      _intermediateCoordinates.add({
        'lat': null,
        'lng': null,
      });
    });
  }

  void _removeIntermediateWaypoint(int index) {
    setState(() {
      _intermediateCoordinates.removeAt(index);
    });
  }

  Widget _buildWaypointCoordinateField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    required bool isMobile,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 10,
              tablet: 11,
              desktop: 12,
            ),
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
        SizedBox(height: isMobile ? 4.0 : 6.0),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 11,
                tablet: 12,
                desktop: 13,
              ),
            ),
            filled: true,
            fillColor: isDark ? Palette.darkBackground : Palette.lightBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.0),
              borderSide: BorderSide(
                color: isDark ? Palette.darkBorder : Palette.lightBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.0),
              borderSide: BorderSide(
                color: isDark ? Palette.darkBorder : Palette.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.0),
              borderSide: const BorderSide(
                color: Color(0xFF00CC58),
                width: 1.5,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 8.0, 
              vertical: isMobile ? 8.0 : 10.0,
            ),
          ),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 11,
              tablet: 12,
              desktop: 13,
            ),
            color: isDark ? Palette.darkText : Palette.lightText,
          ),
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              final double? parsed = double.tryParse(value.trim());
              if (parsed == null) {
                return 'Invalid number';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isRequired,
    required bool isDark,
    required bool isMobile,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${isRequired ? ' *' : ''}',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 12,
              tablet: 13,
              desktop: 14,
            ),
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
        SizedBox(height: isMobile ? 6.0 : 8.0),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
            ),
            filled: true,
            fillColor: isDark ? Palette.darkBackground : Palette.lightBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(
                color: isDark ? Palette.darkBorder : Palette.lightBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(
                color: isDark ? Palette.darkBorder : Palette.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(
                color: Color(0xFF00CC58),
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2.0,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.0, 
              vertical: isMobile ? 10.0 : 12.0,
            ),
          ),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 13,
              tablet: 14,
              desktop: 15,
            ),
            color: isDark ? Palette.darkText : Palette.lightText,
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildStatusDropdown(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status *',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 12,
              tablet: 13,
              desktop: 14,
            ),
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
        SizedBox(height: isMobile ? 6.0 : 8.0),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Palette.darkBackground : Palette.lightBackground,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: isDark ? Palette.darkBorder : Palette.lightBorder,
            ),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.0, 
                vertical: isMobile ? 10.0 : 12.0,
              ),
            ),
            dropdownColor: isDark ? Palette.darkCard : Palette.lightCard,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 13,
                tablet: 14,
                desktop: 15,
              ),
              color: isDark ? Palette.darkText : Palette.lightText,
            ),
            items: const [
              DropdownMenuItem(
                value: 'active',
                child: Text('Active'),
              ),
              DropdownMenuItem(
                value: 'inactive',
                child: Text('Inactive'),
              ),
              DropdownMenuItem(
                value: 'maintenance',
                child: Text('Maintenance'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedStatus = value;
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a status';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, bool isDark) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final buttonPadding = isMobile ? 10.0 : 12.0;
    
    return isMobile
        ? Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: buttonPadding),
                    side: BorderSide(
                      color: isDark ? Palette.darkBorder : Palette.lightBorder,
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark ? Palette.darkText : Palette.lightText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addRoute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00CC58),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: buttonPadding),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Add Route',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: buttonPadding),
                    side: BorderSide(
                      color: isDark ? Palette.darkBorder : Palette.lightBorder,
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Palette.darkText : Palette.lightText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addRoute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00CC58),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: buttonPadding),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Add Route',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ],
          );
  }
}
