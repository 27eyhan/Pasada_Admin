import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/screen/main_pages/fleet_pages/fleet_data.dart'; // Import FleetData
import 'package:provider/provider.dart';

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
              .from('official_routes')
              .select('officialroute_id')
              .eq('officialroute_id', routeId)
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth * 0.4;
    final double dialogHeight = screenWidth * 0.23;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: isDark ? Palette.darkCard : Palette.lightCard,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isDark 
                ? Palette.darkBorder.withValues(alpha: 77)
                : Palette.lightBorder.withValues(alpha: 77),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.08),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modern header
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: isDark ? Palette.darkCard : Palette.lightCard,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark 
                        ? Palette.darkBorder.withValues(alpha: 77)
                        : Palette.lightBorder.withValues(alpha: 77),
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isDark ? Palette.darkSurface : Palette.lightSurface,
                    child: Icon(
                      Icons.edit_note,
                      color: isDark ? Palette.darkText : Palette.lightText,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Text(
                    "Edit Vehicle Information",
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Palette.darkText : Palette.lightText,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Palette.darkCard : Palette.lightCard,
                          border: Border.all(
                            color: isDark 
                                ? Palette.darkBorder.withValues(alpha: 77)
                                : Palette.lightBorder.withValues(alpha: 77),
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle ID badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Palette.darkPrimary.withValues(alpha: 0.1)
                            : Palette.lightPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark 
                              ? Palette.darkPrimary.withValues(alpha: 0.3)
                              : Palette.lightPrimary.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        "Vehicle ID: ${widget.vehicleData['vehicle_id']?.toString() ?? 'N/A'}",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Palette.darkPrimary : Palette.lightPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Form with modern styling
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildModernFormField(
                            controller: _plateNumberController,
                            label: 'Plate Number',
                            icon: Icons.credit_card_outlined,
                            isDark: isDark,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please enter plate number'
                                : null,
                          ),
                          const SizedBox(height: 16.0),
                          _buildModernFormField(
                            controller: _routeIdController,
                            label: 'Route ID',
                            icon: Icons.map_outlined,
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Please enter route ID';
                              if (int.tryParse(value) == null)
                                return 'Please enter a valid number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          _buildModernFormField(
                            controller: _passengerCapacityController,
                            label: 'Passenger Capacity',
                            icon: Icons.people_outline,
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Please enter capacity';
                              if (int.tryParse(value) == null)
                                return 'Please enter a valid number';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: isDark ? Palette.darkCard : Palette.lightCard,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16.0),
                  bottomRight: Radius.circular(16.0),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark 
                        ? Palette.darkBorder.withValues(alpha: 77)
                        : Palette.lightBorder.withValues(alpha: 77),
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Palette.darkSurface : Palette.lightSurface,
                        foregroundColor: isDark ? Palette.darkText : Palette.lightText,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        side: BorderSide(
                          color: isDark 
                              ? Palette.darkBorder.withValues(alpha: 77)
                              : Palette.lightBorder.withValues(alpha: 77),
                          width: 1.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              if (widget.openedFromFleetData) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return FleetData(
                                      vehicle: widget.vehicleData,
                                      supabase: widget.supabase,
                                      onVehicleActionComplete: widget.onVehicleActionComplete,
                                    );
                                  },
                                );
                              }
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Palette.darkPrimary : Palette.lightPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      onPressed: _isLoading ? null : _updateVehicle,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern form field with dark mode support
  Widget _buildModernFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Palette.darkSurface : Palette.lightSurface,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: isDark 
              ? Palette.darkBorder.withValues(alpha: 77)
              : Palette.lightBorder.withValues(alpha: 77),
          width: 1.0,
        ),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          color: isDark ? Palette.darkText : Palette.lightText,
          fontSize: 14.0,
          fontFamily: 'Inter',
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
            fontSize: 12.0,
            fontFamily: 'Inter',
          ),
          prefixIcon: Icon(
            icon,
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
            size: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: isDark ? Palette.darkPrimary : Palette.lightPrimary,
              width: 2.0,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }
}
