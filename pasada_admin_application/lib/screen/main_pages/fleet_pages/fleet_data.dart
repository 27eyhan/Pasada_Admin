import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/database_tables/vehicle_tables/edit_vehicle_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FleetData extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final SupabaseClient supabase;
  final VoidCallback onVehicleActionComplete;

  const FleetData({
    Key? key,
    required this.vehicle,
    required this.supabase,
    required this.onVehicleActionComplete,
  }) : super(key: key);

  @override
  _FleetDataState createState() => _FleetDataState();
}

class _FleetDataState extends State<FleetData> {
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = screenWidth * 0.35;
    final vehicle = widget.vehicle;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      backgroundColor: Palette.whiteColor,
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Fleet Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Palette.blackColor,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(
                    Icons.close,
                    size: 24,
                    color: Palette.blackColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Divider(color: Palette.blackColor.withValues(alpha: 128)),
            const SizedBox(height: 16.0),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow("Vehicle ID:", vehicle['vehicle_id']?.toString() ?? 'N/A'),
                  _buildDetailRow("Plate Number:", vehicle['plate_number'] ?? 'N/A'),
                  _buildDetailRow("Passenger Capacity:", vehicle['passenger_capacity']?.toString() ?? 'N/A'),
                  _buildDetailRow("Route ID:", vehicle['route_id']?.toString() ?? 'N/A'),
                  _buildDetailRow("Vehicle Location:", vehicle['vehicle_location'] ?? 'N/A'),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.whiteColor,
                  foregroundColor: Palette.blackColor,
                  elevation: 4.0,
                  shadowColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Palette.blackColor, width: 0.5),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                child: const Text(
                  "Manage Vehicle",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        "$label $value",
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: Palette.blackColor,
        ),
      ),
    );
  }
}