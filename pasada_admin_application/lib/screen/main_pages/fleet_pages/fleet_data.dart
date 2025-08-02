import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/vehicle_tables/edit_vehicle_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth * 0.35;
    final double dialogHeight =
        screenWidth * 0.38; // Reduced height from 0.45 to 0.38
    final vehicle = widget.vehicle;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Palette.greenColor, width: 2),
      ),
      elevation: 8.0,
      backgroundColor: Palette.whiteColor,
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Enhanced header with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_bus,
                        color: Palette.greenColor, size: 28),
                    SizedBox(width: 12.0),
                    Text(
                      "Fleet Details",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Palette.greenColor,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: Palette.blackColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Divider(color: Palette.greenColor.withAlpha(50), thickness: 1.5),
            const SizedBox(height: 16.0),

            // Vehicle ID badge - wrap in alignment to prevent stretching
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.only(bottom: 16.0),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Palette.greenColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Palette.greenColor.withAlpha(100)),
                ),
                child: Text(
                  "Vehicle ID: ${vehicle['vehicle_id']?.toString() ?? 'N/A'}",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Palette.greenColor,
                  ),
                ),
              ),
            ),

            // Improved detail rows
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEnhancedDetailRow(
                        "Plate Number:",
                        vehicle['plate_number'] ?? 'N/A',
                        Icons.credit_card_outlined),
                    _buildEnhancedDetailRow(
                        "Passenger Capacity:",
                        vehicle['passenger_capacity']?.toString() ?? 'N/A',
                        Icons.people_outline),
                    _buildEnhancedDetailRow(
                        "Route ID:",
                        vehicle['route_id']?.toString() ?? 'N/A',
                        Icons.map_outlined),
                    _buildEnhancedDetailRow(
                        "Vehicle Location:",
                        vehicle['vehicle_location'] ?? 'N/A',
                        Icons.location_on_outlined),
                    // Display driver info if available
                    if (vehicle['driverTable'] != null &&
                        vehicle['driverTable'] is List &&
                        vehicle['driverTable'].isNotEmpty)
                      ..._buildDriverInfo(vehicle['driverTable'].first),
                  ],
                ),
              ),
            ),

            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.whiteColor,
                  foregroundColor: Palette.blackColor,
                  elevation: 4.0,
                  shadowColor: Colors.grey.shade300,
                  side: BorderSide(color: Colors.grey.shade400, width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
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
          ],
        ),
      ),
    );
  }

  // Enhanced detail row with icon
  Widget _buildEnhancedDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Palette.greenColor.withAlpha(220),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Palette.blackColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build driver info section if available
  List<Widget> _buildDriverInfo(Map<String, dynamic> driverData) {
    return [
      Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
        child: Divider(color: Colors.grey.withAlpha(100)),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Icon(Icons.person, color: Palette.greenColor),
            SizedBox(width: 8),
            Text(
              "Assigned Driver",
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Palette.greenColor,
              ),
            ),
          ],
        ),
      ),
      _buildEnhancedDetailRow("Driver ID:",
          driverData['driver_id']?.toString() ?? 'N/A', Icons.badge_outlined),
      _buildEnhancedDetailRow("Full Name:",
          driverData['full_name']?.toString() ?? 'N/A', Icons.person_outlined),
      _buildEnhancedDetailRow(
          "Status:",
          _capitalizeFirstLetter(driverData['driving_status'] ?? 'N/A'),
          Icons.local_taxi_outlined),
    ];
  }

  // Helper method to capitalize first letter
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
