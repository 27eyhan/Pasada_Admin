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
    VoidCallback? onBackPressed,
    VoidCallback? onArchive,
    ValueChanged<Map<String, dynamic>?>? onSelectionChanged,
  }) {
    return TablePreviewWidget(
      tableName: 'Admin',
      tableDescription: 'Administrator accounts and permissions',
      tableIcon: Icons.admin_panel_settings,
      tableColor: Palette.lightPrimary,
      dataFetcher: dataFetcher,
      columns: const [
        DataColumn(label: Text('Admin ID')),
        DataColumn(label: Text('First Name')),
        DataColumn(label: Text('Last Name')),
        DataColumn(label: Text('Mobile')),
        DataColumn(label: Text('Username')),
        DataColumn(label: Text('Created At')),
      ],
      rowBuilder: (data) => data.map((admin) {
        return DataRow(
          cells: [
            DataCell(Text(admin['admin_id']?.toString() ?? 'N/A')),
            DataCell(Text(admin['first_name']?.toString() ?? 'N/A')),
            DataCell(Text(admin['last_name']?.toString() ?? 'N/A')),
            DataCell(Text(admin['admin_mobile_number']?.toString() ?? 'N/A')),
            DataCell(Text(admin['admin_username']?.toString() ?? 'N/A')),
            DataCell(Text(admin['created_at']?.toString() ?? 'N/A')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      onArchive: onArchive,
      enableRowSelection: true,
      onSelectionChanged: onSelectionChanged,
      includeNavigation: includeNavigation,
      onBackPressed: onBackPressed,
    );
  }

  static Widget createDriverTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
    VoidCallback? onBackPressed,
    VoidCallback? onArchive,
    ValueChanged<Map<String, dynamic>?>? onSelectionChanged,
  }) {
    return TablePreviewWidget(
      tableName: 'Driver',
      tableDescription: 'Driver accounts and vehicle assignments',
      tableIcon: Icons.person_outline,
      tableColor: Palette.lightSuccess,
      dataFetcher: dataFetcher,
      columns: const [
        DataColumn(label: Text('Driver ID')),
        DataColumn(label: Text('Vehicle ID')),
        DataColumn(label: Text('Full Name')),
        DataColumn(label: Text('Driver Number')),
        DataColumn(label: Text('Driver Password')),
        DataColumn(label: Text('License Number')),
        DataColumn(label: Text('Vehicle Plate')),
        DataColumn(label: Text('Current Location')),
        DataColumn(label: Text('Driving Status')),
        DataColumn(label: Text('Last Online')),
        DataColumn(label: Text('Created At')),
      ],
      rowBuilder: (data) => data.map((driver) {
        return DataRow(
          cells: [
            DataCell(Text(driver['driver_id']?.toString() ?? 'N/A')),
            DataCell(Text(driver['vehicle_id']?.toString() ?? 'N/A')),
            DataCell(Text(driver['full_name']?.toString() ?? 'N/A')),
            DataCell(Text(driver['driver_number']?.toString() ?? 'N/A')),
            DataCell(Text(driver['driver_password']?.toString() ?? 'N/A')),
            DataCell(Text(driver['driver_license_number']?.toString() ?? 'N/A')),
            DataCell(Text(driver['vehicleplate_number']?.toString() ?? 'N/A')),
            DataCell(Text(driver['current_location']?.toString() ?? 'N/A')),
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
      onArchive: onArchive,
      enableRowSelection: true,
      onSelectionChanged: onSelectionChanged,
      includeNavigation: includeNavigation,
      onBackPressed: onBackPressed,
    );
  }

  static Widget createPassengerTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
    VoidCallback? onBackPressed,
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
        DataColumn(label: Text('Updated At')),
        DataColumn(label: Text('Avatar URL')),
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
            DataCell(Text(passenger['updated_at']?.toString() ?? 'N/A')),
            DataCell(Text(passenger['avatar_url']?.toString() ?? 'N/A')),
            DataCell(Text(passenger['created_at']?.toString() ?? 'N/A')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      includeNavigation: includeNavigation,
      onBackPressed: onBackPressed,
    );
  }

  static Widget createVehicleTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
    VoidCallback? onBackPressed,
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
      onBackPressed: onBackPressed,
    );
  }

  static Widget createRouteTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
    VoidCallback? onBackPressed,
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
        DataColumn(label: Text('Origin Latitude')),
        DataColumn(label: Text('Origin Longitude')),
        DataColumn(label: Text('Destination Latitude')),
        DataColumn(label: Text('Destination Longitude')),
        DataColumn(label: Text('Intermediate Coordinates')),
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
            DataCell(Text(route['origin_lat']?.toString() ?? 'N/A')),
            DataCell(Text(route['origin_lng']?.toString() ?? 'N/A')),
            DataCell(Text(route['destination_lat']?.toString() ?? 'N/A')),
            DataCell(Text(route['destination_lng']?.toString() ?? 'N/A')),
            DataCell(Text(route['intermediate_coordinates']?.toString() ?? 'N/A')),
            DataCell(Text(route['created_at']?.toString() ?? 'N/A')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      includeNavigation: includeNavigation,
      onBackPressed: onBackPressed,
    );
  }

  static Widget createBookingsTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
    VoidCallback? onBackPressed,
    VoidCallback? onArchive,
    ValueChanged<Map<String, dynamic>?>? onSelectionChanged,
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
        DataColumn(label: Text('Fare')),
        DataColumn(label: Text('Pickup Address')),
        DataColumn(label: Text('Dropoff Address')),
        DataColumn(label: Text('Payment Method')),
        DataColumn(label: Text('Passenger Type')),
        DataColumn(label: Text('Seat Type')),
        DataColumn(label: Text('Ride Status')),
        DataColumn(label: Text('Rating')),
        DataColumn(label: Text('Review')),
        DataColumn(label: Text('Pickup Latitude')),
        DataColumn(label: Text('Pickup Longitude')),
        DataColumn(label: Text('Dropoff Latitude')),
        DataColumn(label: Text('Dropoff Longitude')),
        DataColumn(label: Text('Created At')),
      ],
      rowBuilder: (data) => data.map((booking) {
        return DataRow(
          cells: [
            DataCell(Text(booking['booking_id']?.toString() ?? 'N/A')),
            DataCell(Text(booking['passenger_id']?.toString() ?? 'N/A')),
            DataCell(Text(booking['driver_id']?.toString() ?? 'N/A')),
            DataCell(Text(booking['route_id']?.toString() ?? 'N/A')),
            DataCell(Text(booking['fare']?.toString() ?? 'N/A')),
            DataCell(Text(booking['pickup_address']?.toString() ?? 'N/A')),
            DataCell(Text(booking['dropoff_address']?.toString() ?? 'N/A')),
            DataCell(Text(booking['payment_method']?.toString() ?? 'N/A')),
            DataCell(Text(booking['passenger_type']?.toString() ?? 'N/A')),
            DataCell(Text(booking['seat_type']?.toString() ?? 'N/A')),
            DataCell(Text(booking['ride_status']?.toString() ?? 'N/A')),
            DataCell(Text(booking['rating']?.toString() ?? 'N/A')),
            DataCell(Text(booking['review']?.toString() ?? 'N/A')),
            DataCell(Text(booking['pickup_lat']?.toString() ?? 'N/A')),
            DataCell(Text(booking['pickup_long']?.toString() ?? 'N/A')),
            DataCell(Text(booking['dropoff_lat']?.toString() ?? 'N/A')),
            DataCell(Text(booking['dropoff_long']?.toString() ?? 'N/A')),
            DataCell(Text(booking['created_at']?.toString() ?? 'N/A')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      onArchive: onArchive,
      enableRowSelection: true,
      onSelectionChanged: onSelectionChanged,
      includeNavigation: includeNavigation,
      onBackPressed: onBackPressed,
    );
  }

  static Widget createAdminQuotaTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
    VoidCallback? onBackPressed,
  }) {
    return TablePreviewWidget(
      tableName: 'Admin Quotas',
      tableDescription: 'Configured quota targets per period (global or per-driver)',
      tableIcon: Icons.flag,
      tableColor: Palette.lightWarning,
      dataFetcher: dataFetcher,
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Driver ID')),
        DataColumn(label: Text('Target Amount')),
        DataColumn(label: Text('Period')),
        DataColumn(label: Text('Start At')),
        DataColumn(label: Text('End At')),
        DataColumn(label: Text('Is Active')),
        DataColumn(label: Text('Created By')),
        DataColumn(label: Text('Created At')),
        DataColumn(label: Text('Updated At')),
      ],
      rowBuilder: (data) => data.map((row) {
        return DataRow(
          cells: [
            DataCell(Text(row['id']?.toString() ?? 'N/A')),
            DataCell(Text(row['driver_id']?.toString() ?? '—')),
            DataCell(Text(row['target_amount']?.toString() ?? '0')),
            DataCell(Text(row['period']?.toString() ?? 'N/A')),
            DataCell(Text(row['start_at']?.toString() ?? '—')),
            DataCell(Text(row['end_at']?.toString() ?? '—')),
            DataCell(Text((row['is_active'] == true) ? 'true' : 'false')),
            DataCell(Text(row['created_by']?.toString() ?? 'N/A')),
            DataCell(Text(row['created_at']?.toString() ?? '—')),
            DataCell(Text(row['updated_at']?.toString() ?? '—')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      includeNavigation: includeNavigation,
      onBackPressed: onBackPressed,
    );
  }

  static Widget createDriverQuotasTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
    VoidCallback? onBackPressed,
  }) {
    return TablePreviewWidget(
      tableName: 'Driver Quotas',
      tableDescription: 'Per-driver quota aggregates and current progress',
      tableIcon: Icons.stacked_bar_chart,
      tableColor: Palette.lightSuccess,
      dataFetcher: dataFetcher,
      columns: const [
        DataColumn(label: Text('Quota ID')),
        DataColumn(label: Text('Driver ID')),
        DataColumn(label: Text('Quota Daily')),
        DataColumn(label: Text('Quota Weekly')),
        DataColumn(label: Text('Quota Monthly')),
        DataColumn(label: Text('Quota Total')),
        DataColumn(label: Text('Current Daily')),
        DataColumn(label: Text('Current Weekly')),
        DataColumn(label: Text('Current Monthly')),
        DataColumn(label: Text('Current Total')),
        DataColumn(label: Text('Last Reset At')),
        DataColumn(label: Text('Created At')),
        DataColumn(label: Text('Updated At')),
      ],
      rowBuilder: (data) => data.map((row) {
        return DataRow(
          cells: [
            DataCell(Text(row['quota_id']?.toString() ?? 'N/A')),
            DataCell(Text(row['driver_id']?.toString() ?? 'N/A')),
            DataCell(Text(row['quota_daily']?.toString() ?? '0')),
            DataCell(Text(row['quota_weekly']?.toString() ?? '0')),
            DataCell(Text(row['quota_monthly']?.toString() ?? '0')),
            DataCell(Text(row['quota_total']?.toString() ?? '0')),
            DataCell(Text(row['current_quota_daily']?.toString() ?? '—')),
            DataCell(Text(row['current_quota_weekly']?.toString() ?? '—')),
            DataCell(Text(row['current_quota_monthly']?.toString() ?? '—')),
            DataCell(Text(row['current_quota_total']?.toString() ?? '—')),
            DataCell(Text(row['last_reset_at']?.toString() ?? '—')),
            DataCell(Text(row['created_at']?.toString() ?? '—')),
            DataCell(Text(row['updated_at']?.toString() ?? '—')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      includeNavigation: includeNavigation,
      onBackPressed: onBackPressed,
    );
  }

  static Widget createDriverReviewsTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
    VoidCallback? onBackPressed,
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
      onBackPressed: onBackPressed,
    );
  }

  static Widget createDriverArchivesTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
    VoidCallback? onBackPressed,
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
        DataColumn(label: Text('Total Earnings')),
        DataColumn(label: Text('Total Bookings')),
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
            DataCell(Text(archive['total_earnings']?.toString() ?? 'N/A')),
            DataCell(Text(archive['total_bookings']?.toString() ?? 'N/A')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      includeNavigation: includeNavigation,
      onBackPressed: onBackPressed,
    );
  }

  static Widget createAdminArchivesTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
    VoidCallback? onBackPressed,
  }) {
    return TablePreviewWidget(
      tableName: 'Admin Archives',
      tableDescription: 'Historical admin data and records',
      tableIcon: Icons.archive,
      tableColor: Palette.lightTextSecondary,
      dataFetcher: dataFetcher,
      columns: const [
        DataColumn(label: Text('Archive ID')),
        DataColumn(label: Text('Admin ID')),
        DataColumn(label: Text('Full Name')),
        DataColumn(label: Text('Admin Number')),
        DataColumn(label: Text('Admin Password')),
        DataColumn(label: Text('Archived At')),
      ],
      rowBuilder: (data) => data.map((archive) {
        return DataRow(
          cells: [
            DataCell(Text(archive['archive_id']?.toString() ?? 'N/A')),
            DataCell(Text(archive['admin_id']?.toString() ?? 'N/A')),
            DataCell(Text(archive['first_name']?.toString() ?? 'N/A')),
            DataCell(Text(archive['last_name']?.toString() ?? 'N/A')),
            DataCell(Text(archive['admin_mobile_number']?.toString() ?? 'N/A')),
            DataCell(Text(archive['admin_password']?.toString() ?? 'N/A')),
            DataCell(Text(archive['archived_at']?.toString() ?? 'N/A')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      includeNavigation: includeNavigation,
      onBackPressed: onBackPressed,
    );
  }

  static Widget createAllowedStopsTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
    VoidCallback? onBackPressed,
  }) {
    return TablePreviewWidget(
      tableName: 'Allowed Stops',
      tableDescription: 'Stops allowed for each official route',
      tableIcon: Icons.location_on,
      tableColor: Palette.lightPrimary,
      dataFetcher: dataFetcher,
      columns: const [
        DataColumn(label: Text('Allowed Stop ID')),
        DataColumn(label: Text('Official Route ID')),
        DataColumn(label: Text('Stop Name')),
        DataColumn(label: Text('Stop Address')),
        DataColumn(label: Text('Stop Lat')),
        DataColumn(label: Text('Stop Lng')),
        DataColumn(label: Text('Stop Order')),
        DataColumn(label: Text('Is Active')),
        DataColumn(label: Text('Created At')),
      ],
      rowBuilder: (data) => data.map((row) {
        return DataRow(
          cells: [
            DataCell(Text(row['allowedstop_id']?.toString() ?? 'N/A')),
            DataCell(Text(row['officialroute_id']?.toString() ?? 'N/A')),
            DataCell(Text(row['stop_name']?.toString() ?? 'N/A')),
            DataCell(Text(row['stop_address']?.toString() ?? 'N/A')),
            DataCell(Text(row['stop_lat']?.toString() ?? 'N/A')),
            DataCell(Text(row['stop_lng']?.toString() ?? 'N/A')),
            DataCell(Text(row['stop_order']?.toString() ?? '—')),
            DataCell(Text((row['is_active'] == true) ? 'true' : 'false')),
            DataCell(Text(row['created_at']?.toString() ?? '—')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      includeNavigation: includeNavigation,
      onBackPressed: onBackPressed,
    );
  }

  static Widget createAiChatHistoryTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
    VoidCallback? onBackPressed,
  }) {
    return TablePreviewWidget(
      tableName: 'AI Chat History',
      tableDescription: 'Saved AI chat conversations and metadata',
      tableIcon: Icons.chat_bubble_outline,
      tableColor: Palette.lightInfo,
      dataFetcher: dataFetcher,
      columns: const [
        DataColumn(label: Text('History ID')),
        DataColumn(label: Text('Admin ID')),
        DataColumn(label: Text('Title')),
        DataColumn(label: Text('Messages')),
        DataColumn(label: Text('AI Messages')),
        DataColumn(label: Text('Created At')),
      ],
      rowBuilder: (data) => data.map((row) {
        return DataRow(
          cells: [
            DataCell(Text(row['history_id']?.toString() ?? 'N/A')),
            DataCell(Text(row['admin_id']?.toString() ?? '—')),
            DataCell(Text(row['title']?.toString() ?? 'N/A')),
            DataCell(Text(row['messages']?.toString() ?? '—')),
            DataCell(Text(row['ai_message']?.toString() ?? '—')),
            DataCell(Text(row['created_at']?.toString() ?? '—')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      includeNavigation: includeNavigation,
      onBackPressed: onBackPressed,
    );
  }

  static Widget createBookingArchivesTable({
    required Future<List<Map<String, dynamic>>> Function() dataFetcher,
    VoidCallback? onRefresh,
    VoidCallback? onFilterPressed,
    Widget? customActions,
    bool includeNavigation = true,
    VoidCallback? onBackPressed,
  }) {
    return TablePreviewWidget(
      tableName: 'Booking Archives',
      tableDescription: 'Archived historical booking records',
      tableIcon: Icons.inventory_2_outlined,
      tableColor: Palette.lightTextSecondary,
      dataFetcher: dataFetcher,
      columns: const [
        DataColumn(label: Text('Archive ID')),
        DataColumn(label: Text('Booking ID')),
        DataColumn(label: Text('Driver ID')),
        DataColumn(label: Text('Passenger ID')),
        DataColumn(label: Text('Route ID')),
        DataColumn(label: Text('Payment Method')),
        DataColumn(label: Text('Fare')),
        DataColumn(label: Text('Seat Type')),
        DataColumn(label: Text('Ride Status')),
        DataColumn(label: Text('Pickup Address')),
        DataColumn(label: Text('Pickup Lat')),
        DataColumn(label: Text('Pickup Lang')),
        DataColumn(label: Text('Dropoff Address')),
        DataColumn(label: Text('Dropoff Lat')),
        DataColumn(label: Text('Dropoff Lang')),
        DataColumn(label: Text('Start Time')),
        DataColumn(label: Text('End Time')),
        DataColumn(label: Text('Assigned At')),
        DataColumn(label: Text('Archived At')),
      ],
      rowBuilder: (data) => data.map((row) {
        return DataRow(
          cells: [
            DataCell(Text(row['booking_archives_id']?.toString() ?? 'N/A')),
            DataCell(Text(row['booking_id']?.toString() ?? 'N/A')),
            DataCell(Text(row['driver_id']?.toString() ?? 'N/A')),
            DataCell(Text(row['passenger_id']?.toString() ?? '—')),
            DataCell(Text(row['route_id']?.toString() ?? 'N/A')),
            DataCell(Text(row['payment_method']?.toString() ?? '—')),
            DataCell(Text(row['fare']?.toString() ?? '—')),
            DataCell(Text(row['seat_type']?.toString() ?? '—')),
            DataCell(Text(row['ride_status']?.toString() ?? '—')),
            DataCell(Text(row['pickup_address']?.toString() ?? '—')),
            DataCell(Text(row['pickup_lat']?.toString() ?? '—')),
            DataCell(Text(row['pickup_lang']?.toString() ?? '—')),
            DataCell(Text(row['dropoff_address']?.toString() ?? '—')),
            DataCell(Text(row['dropoff_lat']?.toString() ?? '—')),
            DataCell(Text(row['dropoff_lang']?.toString() ?? '—')),
            DataCell(Text(row['start_time']?.toString() ?? '—')),
            DataCell(Text(row['end_time']?.toString() ?? '—')),
            DataCell(Text(row['assigned_at']?.toString() ?? '—')),
            DataCell(Text(row['archived_at']?.toString() ?? '—')),
          ],
        );
      }).toList(),
      onRefresh: onRefresh,
      onFilterPressed: onFilterPressed,
      customActions: customActions,
      includeNavigation: includeNavigation,
      onBackPressed: onBackPressed,
    );
  }
}
