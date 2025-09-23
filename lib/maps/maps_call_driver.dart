import 'dart:typed_data'; // Needed for ByteData
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart'; // For debugPrint

class DriverLocationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchDriverLocations() async {
    debugPrint('[DriverLocationService] Fetching driver locations...');
    try {
      // Select necessary fields including current_location and join with vehicleTable for additional details
      final response = await _supabase.from('driverTable').select('''
            driver_id, 
            full_name, 
            vehicle_id, 
            current_location, 
            driving_status,
            vehicleTable(plate_number, route_id)
          ''');

      debugPrint('[DriverLocationService] Supabase response: $response');
      debugPrint(
          '[DriverLocationService] Type of response: ${response.runtimeType}');

      final List<Map<String, dynamic>> driverLocations = [];

      debugPrint('[DriverLocationService] About to start loop over response.');
      for (var record in response) {
        debugPrint('[DriverLocationService] Entered loop for one record.');
        final data = record;
        final locationData =
            data['current_location']; // Assuming this holds location info
        final drivingStatus = data['driving_status'];
        final driverId = data['driver_id'];

        debugPrint(
            '[DriverLocationService] Processing driver $driverId: Status=$drivingStatus, LocationData=$locationData');
        debugPrint(
            '[DriverLocationService] Raw vehicleTable data for driver $driverId: ${data['vehicleTable']}');

        // Only process drivers who have location data (regardless of status)
        if (locationData != null) {
          LatLng? position = _parseLocation(locationData);
          debugPrint(
              '[DriverLocationService] Parsed position for $driverId: $position');

          if (position != null) {
            // Extract vehicle details from the joined table
            final vehicleData = data['vehicleTable'];
            String plateNumber = 'N/A';
            String routeId = 'N/A';

            debugPrint(
                '[DriverLocationService] VehicleData type: ${vehicleData.runtimeType}, Data: $vehicleData');

            if (vehicleData != null) {
              if (vehicleData is List && vehicleData.isNotEmpty) {
                final vehicleInfo = vehicleData.first as Map<String, dynamic>;
                plateNumber = vehicleInfo['plate_number']?.toString() ?? 'N/A';
                routeId = vehicleInfo['route_id']?.toString() ?? 'N/A';
                debugPrint(
                    '[DriverLocationService] Extracted from List - Plate: $plateNumber, Route: $routeId');
              } else if (vehicleData is Map<String, dynamic>) {
                plateNumber = vehicleData['plate_number']?.toString() ?? 'N/A';
                routeId = vehicleData['route_id']?.toString() ?? 'N/A';
                debugPrint(
                    '[DriverLocationService] Extracted from Map - Plate: $plateNumber, Route: $routeId');
              }
            } else {
              debugPrint(
                  '[DriverLocationService] No vehicle data found for driver $driverId with vehicle_id: ${data['vehicle_id']}');
            }

            driverLocations.add({
              'driver_id': data['driver_id'],
              'full_name': data['full_name'],
              'vehicle_id': data['vehicle_id'],
              'position': position,
              'driving_status':
                  drivingStatus, // Include driving status for custom pins
              'plate_number': plateNumber,
              'route_id': routeId,
            });
          } else {
            debugPrint(
                'Could not parse location for driver_id: ${data['driver_id']}');
          }
        }
      }
      debugPrint(
          '[DriverLocationService] Finished loop. Returning ${driverLocations.length} locations.');
      return driverLocations;
    } catch (e) {
      debugPrint('>>> CAUGHT ERROR in fetchDriverLocations: $e');
      return []; // Return empty list on error
    }
  }

  // Helper function to parse location data
  // Adjust this based on how 'current_location' is stored in Supabase
  LatLng? _parseLocation(dynamic locationData) {
    debugPrint(
        '[DriverLocationService] Parsing location data: $locationData (${locationData.runtimeType})');

    // <<< NEW: Handle PostGIS WKB Hex String >>>
    // Check for 50 characters (25 bytes for EWKB Point + SRID)
    if (locationData is String &&
        locationData.length == 50 &&
        locationData.startsWith('0101000020E6100000')) {
      try {
        debugPrint(
            '[DriverLocationService] Trying to parse as EWKB Point with SRID');
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

        debugPrint(
            '[DriverLocationService] Successfully parsed EWKB Point with SRID: lng=$longitude, lat=$latitude');
        return LatLng(latitude, longitude);
      } catch (e) {
        debugPrint("Error parsing WKB hex string with SRID: $e");
        return null;
      }
    }
    // <<< END NEW >>>

    // Handle PostgreSQL OGC WKB hex format (e.g. 0101000000CA2EBDA2803E5E40D4916D2A9C422D40)
    if (locationData is String && locationData.startsWith('0101')) {
      try {
        debugPrint(
            '[DriverLocationService] Trying to parse as PostgreSQL WKB hex string: ${locationData.length} chars');

        // Convert hex string to byte list
        List<int> bytes = [];
        for (int i = 0; i < locationData.length; i += 2) {
          if (i + 2 <= locationData.length) {
            try {
              bytes.add(int.parse(locationData.substring(i, i + 2), radix: 16));
            } catch (e) {
              debugPrint(
                  '[DriverLocationService] Error parsing hex byte at position $i: ${locationData.substring(i, i + 2)}');
            }
          }
        }

        if (bytes.isEmpty) {
          debugPrint('[DriverLocationService] Failed to parse any hex bytes');
          return null;
        }

        // Wrap bytes in ByteData for easier manipulation
        var byteData = ByteData.sublistView(Uint8List.fromList(bytes));

        // Determine endianness
        bool isLittleEndian = bytes[0] == 1;
        debugPrint(
            '[DriverLocationService] Endianness: ${isLittleEndian ? "little" : "big"}');

        // Determine if the WKB has an SRID
        bool hasSRID = false;
        int byteOffset = 5; // Default for standard WKB

        // Check for SRID in the geometry type bytes
        if (bytes.length > 8) {
          int typeWithFlags = isLittleEndian
              ? byteData.getUint32(1, Endian.little)
              : byteData.getUint32(1, Endian.big);

          hasSRID = (typeWithFlags & 0x20000000) != 0;
          debugPrint(
              '[DriverLocationService] Geometry type: 0x${typeWithFlags.toRadixString(16)}, Has SRID: $hasSRID');

          if (hasSRID) {
            byteOffset = 9; // Skip endian, type, and srid
          }
        }

        if (bytes.length >= byteOffset + 16) {
          // Ensure we have enough data for both coordinates
          // Read coordinates based on endianness
          double longitude = byteData.getFloat64(
              byteOffset, isLittleEndian ? Endian.little : Endian.big);
          double latitude = byteData.getFloat64(
              byteOffset + 8, isLittleEndian ? Endian.little : Endian.big);

          debugPrint(
              '[DriverLocationService] Successfully parsed WKB hex: lng=$longitude, lat=$latitude');
          return LatLng(latitude, longitude);
        } else {
          debugPrint(
              '[DriverLocationService] Not enough bytes for coordinates, only ${bytes.length} bytes');
        }
      } catch (e) {
        debugPrint(
            '[DriverLocationService] Error parsing PostgreSQL WKB hex string: $e');
        return null;
      }
    }

    // Handle generic WKB hex string (without SRID)
    if (locationData is String && locationData.startsWith('0101000000')) {
      try {
        debugPrint(
            '[DriverLocationService] Trying to parse as WKB Point without SRID');
        // Convert hex string to byte list
        List<int> bytes = [];
        for (int i = 0; i < locationData.length; i += 2) {
          bytes.add(int.parse(locationData.substring(i, i + 2), radix: 16));
        }

        // Wrap bytes in ByteData for easier manipulation
        var byteData = ByteData.sublistView(Uint8List.fromList(bytes));

        // For standard WKB point (no SRID):
        // First byte is endianness (0 = big, 1 = little)
        // Next 4 bytes are geometry type (1 = point)
        // Then comes coordinate data
        int byteOffset = 5; // Skip header (1 byte endianness + 4 bytes type)

        // Read coordinates - byte order depends on endianness flag
        bool isLittleEndian = bytes[0] == 1;
        double longitude = byteData.getFloat64(
            byteOffset, isLittleEndian ? Endian.little : Endian.big);
        double latitude = byteData.getFloat64(
            byteOffset + 8, isLittleEndian ? Endian.little : Endian.big);

        debugPrint(
            '[DriverLocationService] Successfully parsed WKB Point without SRID: lng=$longitude, lat=$latitude');
        return LatLng(latitude, longitude);
      } catch (e) {
        debugPrint("Error parsing WKB hex string without SRID: $e");
        return null;
      }
    }

    // Handle GeoJSON format: {type: Point, coordinates: [lng, lat]}
    if (locationData is Map &&
        locationData['type'] != null &&
        locationData['coordinates'] != null &&
        locationData['type'] == 'Point') {
      try {
        debugPrint('[DriverLocationService] Trying to parse as GeoJSON Point');
        final coordinates = locationData['coordinates'];
        debugPrint(
            '[DriverLocationService] Found GeoJSON Point: coordinates=$coordinates, type=${coordinates.runtimeType}');
        if (coordinates is List && coordinates.length == 2) {
          // GeoJSON uses [longitude, latitude] order
          final lng = coordinates[0];
          final lat = coordinates[1];

          debugPrint(
              '[DriverLocationService] Extracted lng=$lng (${lng.runtimeType}), lat=$lat (${lat.runtimeType})');

          // Handle both numeric and string representations
          double? latVal, lngVal;

          if (lat is num) {
            latVal = lat.toDouble();
          } else if (lat is String) {
            latVal = double.tryParse(lat);
          }

          if (lng is num) {
            lngVal = lng.toDouble();
          } else if (lng is String) {
            lngVal = double.tryParse(lng);
          }

          if (latVal != null && lngVal != null) {
            debugPrint(
                '[DriverLocationService] Successfully parsed GeoJSON: lng=$lngVal, lat=$latVal');
            return LatLng(latVal, lngVal);
          }
        }
      } catch (e) {
        debugPrint("Error parsing GeoJSON Point: $e");
        return null;
      }
    }

    // Example 1: If locationData is a Map {'latitude': double, 'longitude': double}
    if (locationData is Map &&
        locationData.containsKey('latitude') &&
        locationData.containsKey('longitude')) {
      try {
        debugPrint(
            '[DriverLocationService] Trying to parse as Map with lat/lng properties');
        final lat = locationData['latitude'];
        final lng = locationData['longitude'];
        if (lat is num && lng is num) {
          debugPrint(
              '[DriverLocationService] Successfully parsed Map with lat/lng: lng=$lng, lat=$lat');
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
        if (locationData.contains(',')) {
          debugPrint(
              '[DriverLocationService] Trying to parse as comma-separated coordinates string');
          final parts = locationData.split(',');
          if (parts.length == 2) {
            final lat = double.tryParse(parts[0].trim());
            final lng = double.tryParse(parts[1].trim());
            if (lat != null && lng != null) {
              debugPrint(
                  '[DriverLocationService] Successfully parsed comma-separated: lng=$lng, lat=$lat');
              return LatLng(lat, lng);
            }
          }
        }
      } catch (e) {
        debugPrint("Error parsing String location data: $e");
        return null;
      }
    }

    // Example 3: If locationData is PostGIS point (often returned as String 'POINT(lng lat)')
    if (locationData is String &&
        locationData.toUpperCase().startsWith('POINT')) {
      try {
        debugPrint(
            '[DriverLocationService] Trying to parse as WKT POINT string');
        final coordsString = locationData.substring(
            locationData.indexOf('(') + 1, locationData.indexOf(')'));
        final parts = coordsString.split(' ');
        if (parts.length == 2) {
          final lng = double.tryParse(parts[0].trim());
          final lat = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) {
            debugPrint(
                '[DriverLocationService] Successfully parsed WKT POINT: lng=$lng, lat=$lat');
            return LatLng(lat, lng);
          }
        }
      } catch (e) {
        debugPrint("Error parsing PostGIS POINT string: $e");
        return null;
      }
    }

    // Add more parsing logic here if needed based on your actual data format
    debugPrint(
        '[DriverLocationService] Unrecognized location format: $locationData');
    return null; // Return null if parsing fails
  }
}
