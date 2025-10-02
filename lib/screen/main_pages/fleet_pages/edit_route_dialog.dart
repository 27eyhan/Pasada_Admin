import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/widgets/responsive_dialog.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditRouteDialog extends StatefulWidget {
  final String routeId;
  final Map<String, dynamic> routeData;
  final SupabaseClient supabase;
  final VoidCallback? onRouteUpdated;

  const EditRouteDialog({
    super.key,
    required this.routeId,
    required this.routeData,
    required this.supabase,
    this.onRouteUpdated,
  });

  @override
  State<EditRouteDialog> createState() => _EditRouteDialogState();
}

class _EditRouteDialogState extends State<EditRouteDialog> {
  late final TextEditingController _routeNameController;
  late final TextEditingController _originNameController;
  late final TextEditingController _destinationNameController;
  late final TextEditingController _descriptionController;
  late String _selectedStatus;
  
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _routeNameController = TextEditingController(text: widget.routeData['route_name']?.toString() ?? '');
    _originNameController = TextEditingController(text: widget.routeData['origin_name']?.toString() ?? '');
    _destinationNameController = TextEditingController(text: widget.routeData['destination_name']?.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.routeData['description']?.toString() ?? '');
    _selectedStatus = widget.routeData['status']?.toString() ?? 'active';
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _originNameController.dispose();
    _destinationNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateRoute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.supabase
          .from('official_routes')
          .update({
            'route_name': _routeNameController.text.trim(),
            'origin_name': _originNameController.text.trim(),
            'destination_name': _destinationNameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'status': _selectedStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('officialroute_id', widget.routeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Route updated successfully'),
            backgroundColor: const Color(0xFF00CC58),
          ),
        );
        
        if (widget.onRouteUpdated != null) {
          widget.onRouteUpdated!();
        }
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating route: ${e.toString()}'),
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
      title: 'Edit Route',
      titleIcon: Icons.edit_road,
      child: Form(
        key: _formKey,
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
            hint: 'Enter route name',
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
                      hint: 'Enter origin location',
                      isRequired: true,
                      isDark: isDark,
                      isMobile: isMobile,
                    ),
                    SizedBox(height: isMobile ? 12.0 : 16.0),
                    _buildTextField(
                      controller: _destinationNameController,
                      label: 'Destination',
                      hint: 'Enter destination location',
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
            value: _selectedStatus,
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
                  onPressed: _isLoading ? null : _updateRoute,
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
                          'Update Route',
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
                  onPressed: _isLoading ? null : _updateRoute,
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
                          'Update Route',
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
