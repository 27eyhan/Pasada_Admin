import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:pasada_admin_application/widgets/responsive_dialog.dart';
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
    final vehicle = widget.vehicle;

    return ResponsiveDialog(
      title: "Fleet Details",
      titleIcon: Icons.directions_bus,
      child: ResponsiveDialogContent(
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
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 16),
                fontWeight: FontWeight.w600,
                color: isDark ? Palette.darkPrimary : Palette.lightPrimary,
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 16)),

          // Main content with responsive layout
          ResponsiveHelper.isMobile(context)
              ? _buildMobileLayout(vehicle, isDark)
              : _buildDesktopLayout(vehicle, isDark),
        ],
      ),
    );
  }

  // Mobile layout - stacked cards
  Widget _buildMobileLayout(Map<String, dynamic> vehicle, bool isDark) {
    return Column(
      children: [
        // Vehicle Information Card
        _buildResponsiveDetailCard(
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
        
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 16)),
        
        // Driver Information Card
        vehicle['driverTable'] != null &&
                vehicle['driverTable'] is List &&
                vehicle['driverTable'].isNotEmpty
            ? _buildResponsiveDetailCard(
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
            : _buildResponsiveDetailCard(
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
        
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 16)),
        
        // Action button
        _buildResponsiveActionButton(isDark),
      ],
    );
  }

  // Desktop layout - side by side cards
  Widget _buildDesktopLayout(Map<String, dynamic> vehicle, bool isDark) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column - Vehicle Information
            Expanded(
              child: _buildResponsiveDetailCard(
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

            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 12)),

            // Right column - Driver Information
            Expanded(
              child: vehicle['driverTable'] != null &&
                      vehicle['driverTable'] is List &&
                      vehicle['driverTable'].isNotEmpty
                  ? _buildResponsiveDetailCard(
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
                  : _buildResponsiveDetailCard(
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
        
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 16)),
        
        // Action button
        _buildResponsiveActionButton(isDark),
      ],
    );
  }

  // Build responsive detail card
  Widget _buildResponsiveDetailCard(String title, List<Widget> children, bool isDark) {
    return Container(
      height: ResponsiveHelper.isMobile(context) ? 250 : 300,
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context)),
        border: Border.all(
          color: isDark 
              ? Palette.darkBorder.withValues(alpha: 77)
              : Palette.lightBorder.withValues(alpha: 77),
          width: 1.0,
        ),
      ),
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveCardPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 12, tablet: 14, desktop: 14),
              fontWeight: FontWeight.w700,
              color: isDark ? Palette.darkText : Palette.lightText,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 6, tablet: 8, desktop: 8)),
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

  // Build responsive action button
  Widget _buildResponsiveActionButton(bool isDark) {
    return ResponsiveDialogActions(
      children: [
        ElevatedButton(
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
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context)),
            ),
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveHelper.getResponsiveSpacing(context, mobile: 10, tablet: 12, desktop: 12),
              horizontal: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 20),
            ),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit, size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 16, tablet: 18, desktop: 18)),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 6, tablet: 8, desktop: 8)),
              Text(
                "Manage Vehicle",
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 16),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ],
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
