import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseSummaryService {
  // Singleton pattern
  DatabaseSummaryService._internal();
  static final DatabaseSummaryService _instance = DatabaseSummaryService._internal();
  factory DatabaseSummaryService() => _instance;

  final SupabaseClient supabase = Supabase.instance.client;

  // Fetch and summarize booking data
  Future<Map<String, dynamic>> getBookingsSummary() async {
    try {
      // Get bookings data from the bookings table
      final bookingsData = await supabase
          .from('bookings')
          .select('booking_id, fare, ride_status');
      
      // Calculate metrics manually
      int totalCount = bookingsData.length;
      int completedCount = 0;
      int cancelledCount = 0;
      double totalFare = 0;
      int validFares = 0;
      
      for (var booking in bookingsData) {
        // Count by status
        String status = booking['ride_status']?.toString().toLowerCase() ?? '';
        if (status == 'completed') {
          completedCount++;
        } else if (status == 'cancelled') {
          cancelledCount++;
        }
        
        // Sum fares
        if (booking['fare'] != null) {
          double? fare = double.tryParse(booking['fare'].toString());
          if (fare != null) {
            totalFare += fare;
            validFares++;
          }
        }
      }
      
      // Calculate average fare
      double avgFare = validFares > 0 ? totalFare / validFares : 0;
          
      return {
        'total': totalCount,
        'completed': completedCount,
        'cancelled': cancelledCount,
        'avgFare': avgFare.toStringAsFixed(2),
        'lastUpdated': DateTime.now().toString()
      };
    } catch (e) {
      print('Error fetching booking summary: $e');
      return {
        'error': 'Failed to fetch booking data',
        'message': e.toString()
      };
    }
  }

  // Fetch and summarize driver data
  Future<Map<String, dynamic>> getDriversSummary() async {
    try {
      // Get drivers data from driverTable
      final driversData = await supabase
          .from('driverTable')
          .select('driver_id, full_name, driving_status');
      
      // Calculate metrics manually
      int totalCount = driversData.length;
      int activeCount = 0;
      
      for (var driver in driversData) {
        String status = driver['driving_status']?.toString().toLowerCase() ?? '';
        if (status == 'online' || status == 'driving' || 
            status == 'idling' || status == 'active') {
          activeCount++;
        }
      }
          
      return {
        'total': totalCount,
        'active': activeCount,
        'inactive': totalCount - activeCount,
        'lastUpdated': DateTime.now().toString()
      };
    } catch (e) {
      print('Error fetching driver summary: $e');
      return {
        'error': 'Failed to fetch driver data',
        'message': e.toString()
      };
    }
  }

  // Fetch and summarize route data
  Future<Map<String, dynamic>> getRoutesSummary() async {
    try {
      // Get routes data from official_routes
      final routesData = await supabase
          .from('official_routes')
          .select('officialroute_id, route_name, origin_name, destination_name');
      
      // Calculate metrics manually
      int totalRoutes = routesData.length;
      
      // Find most popular route (simplified - we can't easily count bookings per route)
      String mostPopularRoute = routesData.isNotEmpty ? 
          '${routesData[0]['origin_name']} to ${routesData[0]['destination_name']}' : 
          'Unknown';
          
      return {
        'totalRoutes': totalRoutes,
        'mostPopular': mostPopularRoute,
        'lastUpdated': DateTime.now().toString()
      };
    } catch (e) {
      print('Error fetching route summary: $e');
      return {
        'error': 'Failed to fetch route data',
        'message': e.toString()
      };
    }
  }

  // Fetch and summarize vehicle data
  Future<Map<String, dynamic>> getVehiclesSummary() async {
    try {
      // Get vehicles data with their associated drivers
      final vehiclesData = await supabase
          .from('vehicleTable')
          .select('vehicle_id, plate_number, driverTable(driving_status)');
      
      // Calculate metrics manually
      int totalCount = vehiclesData.length;
      int activeCount = 0;
      
      // Count vehicles as active if they have an active driver
      for (var vehicle in vehiclesData) {
        final driverData = vehicle['driverTable'];
        
        // Vehicle is active if it has a driver with active status
        if (driverData != null && driverData is List && driverData.isNotEmpty) {
          final driverStatus = driverData[0]['driving_status']?.toString().toLowerCase() ?? '';
          if (driverStatus == 'online' || driverStatus == 'driving' || 
              driverStatus == 'idling' || driverStatus == 'active') {
            activeCount++;
          }
        }
      }
          
      return {
        'total': totalCount,
        'active': activeCount,
        'inactive': totalCount - activeCount,
        'lastUpdated': DateTime.now().toString()
      };
    } catch (e) {
      print('Error fetching vehicle summary: $e');
      return {
        'error': 'Failed to fetch vehicle data',
        'message': e.toString()
      };
    }
  }

  // Main method to get a comprehensive database summary
  Future<String> getFullDatabaseContext() async {
    try {
      Map<String, dynamic> summaryData = {};
      
      // Try to get each dataset, but continue if any fail
      try {
        summaryData['bookings'] = await getBookingsSummary();
      } catch (e) {
        summaryData['bookings'] = {'error': e.toString()};
      }
      
      try {
        summaryData['drivers'] = await getDriversSummary();
      } catch (e) {
        summaryData['drivers'] = {'error': e.toString()};
      }
      
      try {
        summaryData['routes'] = await getRoutesSummary();
      } catch (e) {
        summaryData['routes'] = {'error': e.toString()};
      }
      
      try {
        summaryData['vehicles'] = await getVehiclesSummary();
      } catch (e) {
        summaryData['vehicles'] = {'error': e.toString()};
      }
      
      // Check if we have valid data for each section
      final hasBookingsData = !summaryData['bookings'].containsKey('error');
      final hasDriversData = !summaryData['drivers'].containsKey('error');
      final hasRoutesData = !summaryData['routes'].containsKey('error');
      final hasVehiclesData = !summaryData['vehicles'].containsKey('error');
      
      // Format data as a concise text summary for Gemini
      StringBuffer summary = StringBuffer("SYSTEM DATA SUMMARY:\n");
      
      // Only include sections with valid data
      if (hasBookingsData) {
        final bookings = summaryData['bookings'];
        summary.writeln("- Bookings: ${bookings['total']} total (${bookings['completed']} completed, ${bookings['cancelled']} cancelled)");
        summary.writeln("- Avg. Fare: ${bookings['avgFare']} PHP");
      }
      
      if (hasDriversData) {
        final drivers = summaryData['drivers'];
        summary.writeln("- Drivers: ${drivers['total']} total (${drivers['active']} active)");
      }
      
      if (hasRoutesData) {
        final routes = summaryData['routes'];
        summary.writeln("- Routes: ${routes['totalRoutes']} total (Most popular: ${routes['mostPopular']})");
      }
      
      if (hasVehiclesData) {
        final vehicles = summaryData['vehicles'];
        summary.writeln("- Vehicles: ${vehicles['total']} total (${vehicles['active']} active)");
      }
      
      // If we have no valid data, provide a fallback message
      if (!hasBookingsData && !hasDriversData && !hasRoutesData && !hasVehiclesData) {
        return "System data currently unavailable. Please check back later.";
      }
      
      return summary.toString();
    } catch (e) {
      print('Error generating database context: $e');
      return "Error retrieving system data: $e";
    }
  }
} 