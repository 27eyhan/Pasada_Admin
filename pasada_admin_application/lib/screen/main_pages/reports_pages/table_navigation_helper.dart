import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/widgets/table_preview_helper.dart';

class TableNavigationHelper {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Map table names to their corresponding widget constructors using centralized preview system
  static final Map<String, Widget Function(Function(String, {Map<String, dynamic>? args})?)> _tableWidgets = {
    'Admin': (onNavigateToPage) => _createAdminTable(onNavigateToPage),
    'Driver': (onNavigateToPage) => _createDriverTable(onNavigateToPage),
    'Vehicle': (onNavigateToPage) => _createVehicleTable(onNavigateToPage),
    'Passenger': (onNavigateToPage) => _createPassengerTable(onNavigateToPage),
    'Route': (onNavigateToPage) => _createRouteTable(onNavigateToPage),
    'Bookings': (onNavigateToPage) => _createBookingsTable(onNavigateToPage),
    'Driver Archives': (onNavigateToPage) => _createDriverArchivesTable(onNavigateToPage),
    'Admin Archives': (onNavigateToPage) => _createAdminArchivesTable(onNavigateToPage),
  };

  // Get widget for a specific table name
  static Widget? getTableWidget(String tableName, Function(String, {Map<String, dynamic>? args})? onNavigateToPage) {
    final widgetBuilder = _tableWidgets[tableName];
    return widgetBuilder?.call(onNavigateToPage);
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
  static Widget _createAdminTable(Function(String, {Map<String, dynamic>? args})? onNavigateToPage) {
    return TablePreviewHelper.createAdminTable(
      dataFetcher: () async {
        final data = await _supabase.from('adminTable').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        print('Admin table refreshed');
      },
      includeNavigation: false, // Don't include navigation when used within main navigation
      onBackPressed: () {
        if (onNavigateToPage != null) {
          onNavigateToPage('/select_table');
        }
      },
    );
  }

  static Widget _createDriverTable(Function(String, {Map<String, dynamic>? args})? onNavigateToPage) {
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
      onBackPressed: () {
        if (onNavigateToPage != null) {
          onNavigateToPage('/select_table');
        }
      },
    );
  }

  static Widget _createVehicleTable(Function(String, {Map<String, dynamic>? args})? onNavigateToPage) {
    return TablePreviewHelper.createVehicleTable(
      dataFetcher: () async {
        final data = await _supabase.from('vehicleTable').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        print('Vehicle table refreshed');
      },
      includeNavigation: false, // Don't include navigation when used within main navigation
      onBackPressed: () {
        if (onNavigateToPage != null) {
          onNavigateToPage('/select_table');
        }
      },
    );
  }

  static Widget _createPassengerTable(Function(String, {Map<String, dynamic>? args})? onNavigateToPage) {
    return TablePreviewHelper.createPassengerTable(
      dataFetcher: () async {
        final data = await _supabase.from('passenger').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        print('Passenger table refreshed');
      },
      includeNavigation: false, // Don't include navigation when used within main navigation
      onBackPressed: () {
        if (onNavigateToPage != null) {
          onNavigateToPage('/select_table');
        }
      },
    );
  }

  static Widget _createRouteTable(Function(String, {Map<String, dynamic>? args})? onNavigateToPage) {
    return TablePreviewHelper.createRouteTable(
      dataFetcher: () async {
        final data = await _supabase.from('official_routes').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        print('Route table refreshed');
      },
      includeNavigation: false, // Don't include navigation when used within main navigation
      onBackPressed: () {
        if (onNavigateToPage != null) {
          onNavigateToPage('/select_table');
        }
      },
    );
  }

  static Widget _createBookingsTable(Function(String, {Map<String, dynamic>? args})? onNavigateToPage) {
    return TablePreviewHelper.createBookingsTable(
      dataFetcher: () async {
        final data = await _supabase.from('bookings').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        print('Bookings table refreshed');
      },
      includeNavigation: false, // Don't include navigation when used within main navigation
      onBackPressed: () {
        if (onNavigateToPage != null) {
          onNavigateToPage('/select_table');
        }
      },
    );
  }

  static Widget _createDriverArchivesTable(Function(String, {Map<String, dynamic>? args})? onNavigateToPage) {
    return TablePreviewHelper.createDriverArchivesTable(
      dataFetcher: () async {
        final data = await _supabase.from('driverArchives').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      includeNavigation: false, // Don't include navigation when used within main navigation
      onBackPressed: () {
        if (onNavigateToPage != null) {
          onNavigateToPage('/select_table');
        }
      },
    );
  }

  static Widget _createAdminArchivesTable(Function(String, {Map<String, dynamic>? args})? onNavigateToPage) {
    return TablePreviewHelper.createAdminArchivesTable(
      dataFetcher: () async {
        final data = await _supabase.from('adminArchives').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      includeNavigation: false, // Don't include navigation when used within main navigation
      onBackPressed: () {
        if (onNavigateToPage != null) {
          onNavigateToPage('/select_table');
        }
      },
    );
  }
}
