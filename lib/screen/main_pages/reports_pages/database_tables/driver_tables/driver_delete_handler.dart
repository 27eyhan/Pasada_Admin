import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';

class DriverDeleteHandler {
  static Future<void> handleDeleteDriver(
    BuildContext context,
    Map<String, dynamic> selectedDriverData,
    Function refreshDriverData,
    Function showInfoSnackBar,
  ) async {
    final SupabaseClient supabase = Supabase.instance.client;
    final driverId = selectedDriverData['driver_id'];
    final driverName = selectedDriverData['full_name'] ?? 'N/A';
    final driverNumber = selectedDriverData['driver_number']?.toString() ?? 'N/A';
    final vehicleId = selectedDriverData['vehicle_id']?.toString() ?? 'N/A';
    
    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Palette.redColor, width: 2),
            ),
            icon: Icon(Icons.warning_amber_rounded, color: Palette.redColor, size: 48),
            title: Text(
              'Delete Driver Confirmation', 
              style: TextStyle(fontWeight: FontWeight.bold, color: Palette.redColor),
              textAlign: TextAlign.center,
            ),
            contentPadding: const EdgeInsets.all(24.0),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You are about to delete the following driver:'),
                SizedBox(height: 16),
                _buildInfoRow('Driver ID:', driverId.toString()),
                _buildInfoRow('Name:', driverName),
                _buildInfoRow('Driver Number:', driverNumber),
                _buildInfoRow('Vehicle ID:', vehicleId),
                SizedBox(height: 16),
                Text(
                  'This driver will be moved to archives for 30 days before permanent deletion.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            actions: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Delete Driver', style: TextStyle(fontWeight: FontWeight.w600)),
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    showInfoSnackBar('Processing driver deletion...');
                    
                    // Step 1: Archive the driver BEFORE deleting
                    try {
                      debugPrint('Attempting to archive driver data');
                      
                      // Create a simple archive ID 
                      final int archiveId = DateTime.now().second * 1000 + int.parse(driverId.toString());
                      
                      debugPrint('Using archive ID: $archiveId');
                      
                      await supabase.from('driverArchives').insert({
                        'archive_id': archiveId,
                        'driver_id': int.parse(driverId.toString()),
                        'full_name': driverName,
                        'driver_number': driverNumber,
                        'driver_password': selectedDriverData['driver_password'] ?? '',
                        'last_vehicle_used': selectedDriverData['vehicle_id'] != null 
                            ? int.parse(selectedDriverData['vehicle_id'].toString()) 
                            : null,
                        'archived_at': DateTime.now().toIso8601String(),
                      });
                      
                      debugPrint('Archive operation completed successfully');
                      
                      // Step 2: Now that archiving succeeded, delete from driver table
                      await supabase
                          .from('driverTable')
                          .delete()
                          .match({'driver_id': driverId});
                      
                      showInfoSnackBar('Driver archived and removed successfully.');
                      refreshDriverData();
                      
                    } catch (e) {
                      debugPrint('Error: ${e.toString()}');
                      showInfoSnackBar('Error processing driver: ${e.toString()}');
                    }

                  } catch (e) {
                    showInfoSnackBar('Error in delete process: ${e.toString()}');
                  }
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      showInfoSnackBar('Error showing delete dialog: ${e.toString()}');
    }
  }

  static Widget _buildInfoRow(String label, String value) {
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
} 