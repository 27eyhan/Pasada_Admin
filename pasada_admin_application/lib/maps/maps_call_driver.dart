import 'dart:typed_data'; // Needed for ByteData
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart'; // For debugPrint

class DriverLocationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchDriverLocations() async {
    debugPrint('[DriverLocationService] Fetching driver locations...');
    try {
      // Select necessary fields including current_location
      // Assuming current_location is stored in a format that includes latitude and longitude
      final response = await _supabase
          .from('driverTable')
          .select('driver_id, first_name, last_name, vehicle_id, current_location, driving_status'); // Added driving_status

      debugPrint('[DriverLocationService] Supabase response: $response');
      debugPrint('[DriverLocationService] Type of response: ${response.runtimeType}');

      final List<Map<String, dynamic>> driverLocations = [];

      debugPrint('[DriverLocationService] About to start loop over response.');
      for (var record in response) {
        debugPrint('[DriverLocationService] Entered loop for one record.');
        final data = record;
        final locationData = data['current_location']; // Assuming this holds location info
        final drivingStatus = data['driving_status'];
        final driverId = data['driver_id'];

        debugPrint('[DriverLocationService] Processing driver $driverId: Status=$drivingStatus, LocationData=$locationData');

        // Only process drivers who have location data (regardless of status)
        if (locationData != null) {
           LatLng? position = _parseLocation(locationData);
           debugPrint('[DriverLocationService] Parsed position for $driverId: $position');

           if (position != null) {
               driverLocations.add({
                  'driver_id': data['driver_id'],
                  'first_name': data['first_name'],
                  'last_name': data['last_name'],
                  'vehicle_id': data['vehicle_id'],
                  'position': position,
               });
           } else {
               debugPrint('Could not parse location for driver_id: ${data['driver_id']}');
           }
        }
      }
      debugPrint('[DriverLocationService] Finished loop. Returning ${driverLocations.length} locations.');
      return driverLocations;
    } catch (e) {
      debugPrint('>>> CAUGHT ERROR in fetchDriverLocations: $e');
      return []; // Return empty list on error
    }
  }

  // Helper function to parse location data
  // Adjust this based on how 'current_location' is stored in Supabase
  LatLng? _parseLocation(dynamic locationData) {
    // <<< NEW: Handle PostGIS WKB Hex String >>>
    // Check for 50 characters (25 bytes for EWKB Point + SRID)
    if (locationData is String && locationData.length == 50 && locationData.startsWith('0101000020E6100000')) {
      try {
        // Convert hex string to byte list
        List<int> bytes = [];
        for (int i = 0; i < locationData.length; i += 2) {
          bytes.add(int.parse(locationData.substring(i, i + 2), radix: 16));
        }

        // Wrap bytes in ByteData for easier manipulation (ensure little endian)
        var byteData = ByteData.sublistView(Uint8List.fromList(bytes));

        // Extract longitude (starts at byte 9, 8 bytes long)
        // WKB Header: 01 (byte order) 01000000 (point type) 20E6100000 (SRID 4326)
        // Data starts after header (byte 9)
        double longitude = byteData.getFloat64(9, Endian.little);
        // Extract latitude (starts at byte 17, 8 bytes long)
        double latitude = byteData.getFloat64(17, Endian.little);

        return LatLng(latitude, longitude);
      } catch (e) {
        debugPrint("Error parsing WKB hex string: $e");
        return null;
      }
    }
    // <<< END NEW >>>

    // Example 1: If locationData is a Map {'latitude': double, 'longitude': double}
    if (locationData is Map && locationData.containsKey('latitude') && locationData.containsKey('longitude')) {
       try {
         final lat = locationData['latitude'];
         final lng = locationData['longitude'];
         if (lat is num && lng is num) {
            return LatLng(lat.toDouble(), lng.toDouble());
         }
       } catch (e) {
         debugPrint("Error parsing Map location data: $e");
         return null;
       }
    }

    // Example 2: If locationData is a String "latitude,longitude"
    if (locationData is String) {
      try {
        final parts = locationData.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) {
            return LatLng(lat, lng);
          }
        }
      } catch (e) {
         debugPrint("Error parsing String location data: $e");
         return null;
       }
    }

    // Example 3: If locationData is PostGIS point (often returned as String 'POINT(lng lat)')
     if (locationData is String && locationData.toUpperCase().startsWith('POINT')) {
       try {
         final coordsString = locationData.substring(locationData.indexOf('(') + 1, locationData.indexOf(')'));
         final parts = coordsString.split(' ');
         if (parts.length == 2) {
           final lng = double.tryParse(parts[0].trim());
           final lat = double.tryParse(parts[1].trim());
           if (lat != null && lng != null) {
             return LatLng(lat, lng);
           }
         }
       } catch (e) {
          debugPrint("Error parsing PostGIS POINT string: $e");
          return null;
       }
     }

    // Add more parsing logic here if needed based on your actual data format
    debugPrint('[DriverLocationService] Unrecognized location format: $locationData');
    return null; // Return null if parsing fails
  }
}
