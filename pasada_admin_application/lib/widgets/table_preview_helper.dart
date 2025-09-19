import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/widgets/table_preview_widget.dart';

class TablePreviewHelper {
  static Widget createAdminTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
  }) {
    return TablePreviewWidget(
      tableName: 'Admin',
      tableDescription: 'Administrator accounts and permissions',
      tableIcon: Icons.admin_panel_settings,
      tableColor: Palette.lightPrimary,
      dataFetcher: dataFetcher,
      columns: const [
        DataColumn(label: Text('Admin ID')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Mobile')),
        DataColumn(label: Text('Username')),
        DataColumn(label: Text('Created At')),
      ],
      rowBuilder: (data) => data.map((admin) {
        return DataRow(
          cells: [
            DataCell(Text(admin['admin_id']?.toString() ?? 'N/A')),
            DataCell(Text('${admin['first_name'] ?? ''} ${admin['last_name'] ?? ''}')),
            DataCell(Text(admin['admin_mobile_number']?.toString() ?? 'N/A')),
            DataCell(Text(admin['admin_username']?.toString() ?? 'N/A')),
            DataCell(Text(admin['created_at']?.toString() ?? 'N/A')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      includeNavigation: includeNavigation,
    );
  }

  static Widget createDriverTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
  }) {
    return TablePreviewWidget(
      tableName: 'Driver',
      tableDescription: 'Driver accounts and vehicle assignments',
      tableIcon: Icons.person_outline,
      tableColor: Palette.lightSuccess,
      dataFetcher: dataFetcher,
      columns: const [
        DataColumn(label: Text('Driver ID')),
        DataColumn(label: Text('Full Name')),
        DataColumn(label: Text('Driver Number')),
        DataColumn(label: Text('License Number')),
        DataColumn(label: Text('Vehicle Plate')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Last Online')),
        DataColumn(label: Text('Created At')),
      ],
      rowBuilder: (data) => data.map((driver) {
        return DataRow(
          cells: [
            DataCell(Text(driver['driver_id']?.toString() ?? 'N/A')),
            DataCell(Text(driver['full_name']?.toString() ?? 'N/A')),
            DataCell(Text(driver['driver_number']?.toString() ?? 'N/A')),
            DataCell(Text(driver['driver_license_number']?.toString() ?? 'N/A')),
            DataCell(Text(driver['vehicleplate_number']?.toString() ?? 'N/A')),
            DataCell(Text(driver['driving_status']?.toString() ?? 'N/A')),
            DataCell(Text(driver['last_online']?.toString() ?? 'N/A')),
            DataCell(Text(driver['created_at']?.toString() ?? 'N/A')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      showFilterButton: true,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      includeNavigation: includeNavigation,
    );
  }

  static Widget createPassengerTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
  }) {
    return TablePreviewWidget(
      tableName: 'Passenger',
      tableDescription: 'Passenger information and profiles',
      tableIcon: Icons.person,
      tableColor: Palette.lightInfo,
      dataFetcher: dataFetcher,
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Display Name')),
        DataColumn(label: Text('Contact Number')),
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Last Login')),
        DataColumn(label: Text('Created At')),
      ],
      rowBuilder: (data) => data.map((passenger) {
        return DataRow(
          cells: [
            DataCell(Text(passenger['id']?.toString() ?? 'N/A')),
            DataCell(Text(passenger['display_name']?.toString() ?? 'N/A')),
            DataCell(Text(passenger['contact_number']?.toString() ?? 'N/A')),
            DataCell(Text(passenger['passenger_email']?.toString() ?? 'N/A')),
            DataCell(Text(passenger['passenger_type']?.toString() ?? 'N/A')),
            DataCell(Text(passenger['last_login']?.toString() ?? 'N/A')),
            DataCell(Text(passenger['created_at']?.toString() ?? 'N/A')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      includeNavigation: includeNavigation,
    );
  }

  static Widget createVehicleTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
  }) {
    return TablePreviewWidget(
      tableName: 'Vehicle',
      tableDescription: 'Fleet vehicles and specifications',
      tableIcon: Icons.directions_bus,
      tableColor: Palette.lightSecondary,
      dataFetcher: dataFetcher,
      columns: const [
        DataColumn(label: Text('Vehicle ID')),
        DataColumn(label: Text('Plate Number')),
        DataColumn(label: Text('Route ID')),
        DataColumn(label: Text('Passenger Capacity')),
        DataColumn(label: Text('Sitting Passengers')),
        DataColumn(label: Text('Standing Passengers')),
        DataColumn(label: Text('Created At')),
      ],
      rowBuilder: (data) => data.map((vehicle) {
        return DataRow(
          cells: [
            DataCell(Text(vehicle['vehicle_id']?.toString() ?? 'N/A')),
            DataCell(Text(vehicle['plate_number']?.toString() ?? 'N/A')),
            DataCell(Text(vehicle['route_id']?.toString() ?? 'N/A')),
            DataCell(Text(vehicle['passenger_capacity']?.toString() ?? 'N/A')),
            DataCell(Text(vehicle['sitting_passenger']?.toString() ?? 'N/A')),
            DataCell(Text(vehicle['standing_passenger']?.toString() ?? 'N/A')),
            DataCell(Text(vehicle['created_at']?.toString() ?? 'N/A')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      includeNavigation: includeNavigation,
    );
  }

  static Widget createRouteTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
  }) {
    return TablePreviewWidget(
      tableName: 'Route',
      tableDescription: 'Transportation routes and stops',
      tableIcon: Icons.route,
      tableColor: Palette.lightPrimary,
      dataFetcher: dataFetcher,
      columns: const [
        DataColumn(label: Text('Route ID')),
        DataColumn(label: Text('Route Name')),
        DataColumn(label: Text('Origin')),
        DataColumn(label: Text('Destination')),
        DataColumn(label: Text('Description')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Created At')),
      ],
      rowBuilder: (data) => data.map((route) {
        return DataRow(
          cells: [
            DataCell(Text(route['officialroute_id']?.toString() ?? 'N/A')),
            DataCell(Text(route['route_name']?.toString() ?? 'N/A')),
            DataCell(Text(route['origin_name']?.toString() ?? 'N/A')),
            DataCell(Text(route['destination_name']?.toString() ?? 'N/A')),
            DataCell(Text(route['description']?.toString() ?? 'N/A')),
            DataCell(Text(route['status']?.toString() ?? 'N/A')),
            DataCell(Text(route['created_at']?.toString() ?? 'N/A')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      includeNavigation: includeNavigation,
    );
  }

  static Widget createBookingsTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
  }) {
    return TablePreviewWidget(
      tableName: 'Bookings',
      tableDescription: 'Ride bookings and transaction history',
      tableIcon: Icons.book_online,
      tableColor: Palette.lightInfo,
      dataFetcher: dataFetcher,
      columns: const [
        DataColumn(label: Text('Booking ID')),
        DataColumn(label: Text('Passenger')),
        DataColumn(label: Text('Driver')),
        DataColumn(label: Text('Route')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Created At')),
      ],
      rowBuilder: (data) => data.map((booking) {
        return DataRow(
          cells: [
            DataCell(Text(booking['booking_id']?.toString() ?? 'N/A')),
            DataCell(Text(booking['passenger_id']?.toString() ?? 'N/A')),
            DataCell(Text(booking['driver_id']?.toString() ?? 'N/A')),
            DataCell(Text(booking['route_id']?.toString() ?? 'N/A')),
            DataCell(Text(booking['booking_status']?.toString() ?? 'N/A')),
            DataCell(Text(booking['created_at']?.toString() ?? 'N/A')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      includeNavigation: includeNavigation,
    );
  }

  static Widget createDriverReviewsTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
  }) {
    return TablePreviewWidget(
      tableName: 'Driver Reviews',
      tableDescription: 'Driver ratings and customer feedback',
      tableIcon: Icons.star_rate,
      tableColor: Palette.lightWarning,
      dataFetcher: dataFetcher,
      columns: const [
        DataColumn(label: Text('Review ID')),
        DataColumn(label: Text('Driver')),
        DataColumn(label: Text('Passenger')),
        DataColumn(label: Text('Rating')),
        DataColumn(label: Text('Comment')),
        DataColumn(label: Text('Created At')),
      ],
      rowBuilder: (data) => data.map((review) {
        return DataRow(
          cells: [
            DataCell(Text(review['review_id']?.toString() ?? 'N/A')),
            DataCell(Text(review['driver_id']?.toString() ?? 'N/A')),
            DataCell(Text(review['passenger_id']?.toString() ?? 'N/A')),
            DataCell(Text(review['rating']?.toString() ?? 'N/A')),
            DataCell(Text(review['comment']?.toString() ?? 'N/A')),
            DataCell(Text(review['created_at']?.toString() ?? 'N/A')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      includeNavigation: includeNavigation,
    );
  }

  static Widget createDriverArchivesTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
  }) {
    return TablePreviewWidget(
      tableName: 'Driver Archives',
      tableDescription: 'Historical driver data and records',
      tableIcon: Icons.archive,
      tableColor: Palette.lightTextSecondary,
      dataFetcher: dataFetcher,
      columns: const [
        DataColumn(label: Text('Archive ID')),
        DataColumn(label: Text('Driver ID')),
        DataColumn(label: Text('Full Name')),
        DataColumn(label: Text('Driver Number')),
        DataColumn(label: Text('Last Vehicle Used')),
        DataColumn(label: Text('Archived At')),
      ],
      rowBuilder: (data) => data.map((archive) {
        return DataRow(
          cells: [
            DataCell(Text(archive['archive_id']?.toString() ?? 'N/A')),
            DataCell(Text(archive['driver_id']?.toString() ?? 'N/A')),
            DataCell(Text(archive['full_name']?.toString() ?? 'N/A')),
            DataCell(Text(archive['driver_number']?.toString() ?? 'N/A')),
            DataCell(Text(archive['last_vehicle_used']?.toString() ?? 'N/A')),
            DataCell(Text(archive['archived_at']?.toString() ?? 'N/A')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      includeNavigation: includeNavigation,
    );
  }
}
