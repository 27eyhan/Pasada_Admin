import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/widgets/table_preview_helper.dart';

class TableNavigationHelper {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Map table names to their corresponding widget constructors using centralized preview system
  static final Map<String, Widget Function()> _tableWidgets = {
    'Admin': () => _createAdminTable(),
    'Driver': () => _createDriverTable(),
    'Vehicle': () => _createVehicleTable(),
    'Passenger': () => _createPassengerTable(),
    'Driver Reviews': () => _createDriverReviewsTable(),
    'Route': () => _createRouteTable(),
    'Bookings': () => _createBookingsTable(),
    'Payments': () => _buildPlaceholderWidget('Payments'), // Placeholder for now
  };

  // Get widget for a specific table name
  static Widget? getTableWidget(String tableName) {
    final widgetBuilder = _tableWidgets[tableName];
    return widgetBuilder?.call();
  }

  // Check if a table name exists
  static bool hasTable(String tableName) {
    return _tableWidgets.containsKey(tableName);
  }

  // Get all available table names
  static List<String> getAllTableNames() {
    return _tableWidgets.keys.toList();
  }

  // Factory methods for creating table widgets using the centralized system
  static Widget _createAdminTable() {
    return TablePreviewHelper.createAdminTable(
      dataFetcher: () async {
        final data = await _supabase.from('adminTable').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        print('Admin table refreshed');
      },
      includeNavigation: false, // Don't include navigation when used within main navigation
    );
  }

  static Widget _createDriverTable() {
    return TablePreviewHelper.createDriverTable(
      dataFetcher: () async {
        final data = await _supabase.from('driverTable').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        print('Driver table refreshed');
      },
      onFilterPressed: () {
        print('Driver filter pressed');
      },
      includeNavigation: false, // Don't include navigation when used within main navigation
    );
  }

  static Widget _createVehicleTable() {
    return TablePreviewHelper.createVehicleTable(
      dataFetcher: () async {
        final data = await _supabase.from('vehicleTable').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        print('Vehicle table refreshed');
      },
      includeNavigation: false, // Don't include navigation when used within main navigation
    );
  }

  static Widget _createPassengerTable() {
    return TablePreviewHelper.createPassengerTable(
      dataFetcher: () async {
        final data = await _supabase.from('passenger').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        print('Passenger table refreshed');
      },
      includeNavigation: false, // Don't include navigation when used within main navigation
    );
  }

  static Widget _createRouteTable() {
    return TablePreviewHelper.createRouteTable(
      dataFetcher: () async {
        final data = await _supabase.from('official_routes').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        print('Route table refreshed');
      },
      includeNavigation: false, // Don't include navigation when used within main navigation
    );
  }

  static Widget _createBookingsTable() {
    return TablePreviewHelper.createBookingsTable(
      dataFetcher: () async {
        final data = await _supabase.from('bookings').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        print('Bookings table refreshed');
      },
      includeNavigation: false, // Don't include navigation when used within main navigation
    );
  }

  static Widget _createDriverReviewsTable() {
    return TablePreviewHelper.createDriverReviewsTable(
      dataFetcher: () async {
        final data = await _supabase.from('driverReviewsTable').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        print('Driver reviews table refreshed');
      },
      includeNavigation: false, // Don't include navigation when used within main navigation
    );
  }

  // Build placeholder widget for tables not yet implemented
  static Widget _buildPlaceholderWidget(String tableName) {
    return Builder(
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text('$tableName Table'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction,
                  size: 64,
                  color: Colors.orange,
                ),
                SizedBox(height: 16),
                Text(
                  '$tableName Table',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This table is under construction',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Navigate back
                    Navigator.of(context).pop();
                  },
                  child: Text('Go Back'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
