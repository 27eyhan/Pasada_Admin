import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';

class FleetData extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  const FleetData({Key? key, required this.vehicle}) : super(key: key);

  @override
  _FleetDataState createState() => _FleetDataState();
}

class _FleetDataState extends State<FleetData> {
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width * 0.7;
    final double sideLength = screenWidth * 0.6;
    final vehicle = widget.vehicle;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      backgroundColor: Palette.whiteColor,
      child: Container(
        width: sideLength,
        height: sideLength,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Fleet",
                  style: TextStyle(
                    fontSize: 22,
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Vehicle ID: ${vehicle['vehicle_id']?.toString() ?? 'N/A'}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Palette.blackColor,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      "Plate Number: ${vehicle['plate_number'] ?? 'N/A'}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Palette.blackColor,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      "Passenger Capacity: ${vehicle['passenger_capacity']?.toString() ?? 'N/A'}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Palette.blackColor,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      "Route ID: ${vehicle['route_id']?.toString() ?? 'N/A'}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Palette.blackColor,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      "Vehicle Location: ${vehicle['vehicle_location'] ?? 'N/A'}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Palette.blackColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.whiteColor,
                  foregroundColor: Palette.blackColor,
                  elevation: 6.0,
                  shadowColor: Colors.grey,
                  side: BorderSide(color: Colors.grey, width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
                onPressed: () {
                },
                child: Text(
                  "Manage Vehicle",
                  style: TextStyle(
                    fontSize: 16,
                    color: Palette.blackColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}