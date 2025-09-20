import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/vehicle_tables/edit_vehicle_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

class FleetData extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final SupabaseClient supabase;
  final VoidCallback onVehicleActionComplete;

  const FleetData({
    super.key,
    required this.vehicle,
    required this.supabase,
    required this.onVehicleActionComplete,
  });

  @override
  _FleetDataState createState() => _FleetDataState();
}

class _FleetDataState extends State<FleetData> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth * 0.5;
    final double dialogHeight = screenWidth * 0.26;
    final vehicle = widget.vehicle;

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
            // Compact header
            Container(
              padding: const EdgeInsets.all(16.0),
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
                    radius: 14,
                    backgroundColor: isDark ? Palette.darkCard : Palette.lightCard,
                    child: Icon(
                      Icons.directions_bus,
                      color: isDark ? Palette.darkText : Palette.lightText,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Text(
                    "Fleet Details",
                    style: TextStyle(
                      fontSize: 18.0,
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
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isDark ? Palette.darkCard : Palette.lightCard,
                          border: Border.all(
                            color: isDark 
                                ? Palette.darkBorder.withValues(alpha: 77)
                                : Palette.lightBorder.withValues(alpha: 77),
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content area with two columns
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle ID badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        "Vehicle ID: ${vehicle['vehicle_id']?.toString() ?? 'N/A'}",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Palette.darkPrimary : Palette.lightPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Two column layout
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column - Vehicle Information
                        Expanded(
                          child: _buildUniformDetailCard(
                            "Vehicle Information",
                            [
                              _buildCompactDetailRow(
                                "Plate Number",
                                vehicle['plate_number'] ?? 'N/A',
                                Icons.credit_card_outlined,
                                isDark,
                              ),
                              _buildCompactDetailRow(
                                "Passenger Capacity",
                                "${vehicle['passenger_capacity'] ?? 'N/A'} seats",
                                Icons.people_outline,
                                isDark,
                              ),
                              _buildCompactDetailRow(
                                "Route ID",
                                vehicle['route_id']?.toString() ?? 'N/A',
                                Icons.map_outlined,
                                isDark,
                              ),
                              _buildCompactDetailRow(
                                "Location",
                                vehicle['vehicle_location'] ?? 'N/A',
                                Icons.location_on_outlined,
                                isDark,
                              ),
                            ],
                            isDark,
                          ),
                        ),

                        const SizedBox(width: 12.0),

                        // Right column - Driver Information
                        Expanded(
                          child: vehicle['driverTable'] != null &&
                                  vehicle['driverTable'] is List &&
                                  vehicle['driverTable'].isNotEmpty
                              ? _buildUniformDetailCard(
                                  "Assigned Driver",
                                  [
                                    _buildCompactDetailRow(
                                      "Driver ID",
                                      vehicle['driverTable'].first['driver_id']?.toString() ?? 'N/A',
                                      Icons.badge_outlined,
                                      isDark,
                                    ),
                                    _buildCompactDetailRow(
                                      "Full Name",
                                      vehicle['driverTable'].first['full_name'] ?? 'N/A',
                                      Icons.person_outlined,
                                      isDark,
                                    ),
                                    _buildCompactDetailRow(
                                      "Status",
                                      _capitalizeFirstLetter(vehicle['driverTable'].first['driving_status'] ?? 'N/A'),
                                      Icons.local_taxi_outlined,
                                      isDark,
                                      statusColor: _getStatusColor(vehicle['driverTable'].first['driving_status'] ?? 'offline'),
                                    ),
                                  ],
                                  isDark,
                                )
                              : _buildUniformDetailCard(
                                  "Assigned Driver",
                                  [
                                    _buildCompactDetailRow(
                                      "Status",
                                      "No Driver Assigned",
                                      Icons.person_off_outlined,
                                      isDark,
                                      statusColor: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                                    ),
                                  ],
                                  isDark,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Action button
            Container(
              padding: const EdgeInsets.all(12.0),
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Palette.darkCard : Palette.lightCard,
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
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return EditVehicleDialog(
                          supabase: widget.supabase,
                          onVehicleActionComplete: widget.onVehicleActionComplete,
                          vehicleData: widget.vehicle,
                          openedFromFleetData: true,
                        );
                      },
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "Manage Vehicle",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build uniform detail card with fixed height
  Widget _buildUniformDetailCard(String title, List<Widget> children, bool isDark) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDark 
              ? Palette.darkBorder.withValues(alpha: 77)
              : Palette.lightBorder.withValues(alpha: 77),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              color: isDark ? Palette.darkText : Palette.lightText,
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build compact individual detail row
  Widget _buildCompactDetailRow(
    String label,
    String value,
    IconData icon,
    bool isDark, {
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: statusColor ?? (isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.0,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: statusColor ?? (isDark ? Palette.darkText : Palette.lightText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Get status color based on vehicle status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return Palette.lightSuccess;
      case 'driving':
        return Palette.lightSuccess;
      case 'idling':
        return Palette.lightWarning;
      default:
        return Palette.lightError;
    }
  }

  // Helper method to capitalize first letter
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
