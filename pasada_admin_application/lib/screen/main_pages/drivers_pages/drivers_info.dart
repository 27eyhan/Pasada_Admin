import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';

class DriverInfo extends StatefulWidget {
  final Map<String, dynamic> driver;
  const DriverInfo({Key? key, required this.driver}) : super(key: key);

  @override
  _DriverInfoState createState() => _DriverInfoState();
}

class _DriverInfoState extends State<DriverInfo> {
  @override
  Widget build(BuildContext context) {
    // Calculate dialog dimensions based on the screen width.
    final double screenWidth = MediaQuery.of(context).size.width * 0.7;
    final double sideLength = screenWidth * 0.6;
    final driver = widget.driver; // Retrieve the driver data.

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
            // Header with title and a close button.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Driver Information",
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
            Divider(color: Palette.blackColor.withOpacity(0.5)),
            const SizedBox(height: 16.0),
            // Display driver details (excluding driver_password and created_at).
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Driver ID: ${driver['driver_id']?.toString() ?? 'N/A'}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Palette.blackColor,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      "Name: ${driver['last_name'] ?? ''}, ${driver['first_name'] ?? ''}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Palette.blackColor,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      "Driver Number: ${driver['driver_number'] ?? 'N/A'}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Palette.blackColor,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      "Vehicle ID: ${driver['vehicle_id']?.toString() ?? 'N/A'}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Palette.blackColor,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      "Status: ${driver['driving_status'] ?? 'N/A'}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Palette.blackColor,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      "Last Online: ${driver['last_online'] ?? 'N/A'}",
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
            // Manage Driver button.
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
                onPressed: () {
                  // Add action to manage the driver here.
                },
                child: Text(
                  "Manage Driver",
                  style: TextStyle(
                    fontFamily: 'Inter',
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
