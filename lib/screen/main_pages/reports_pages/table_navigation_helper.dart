import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/widgets/table_preview_helper.dart';
import 'package:pasada_admin_application/services/archive_service.dart';
import 'package:pasada_admin_application/services/pdf_export_service.dart';
import 'package:printing/printing.dart';
import 'package:pasada_admin_application/services/file_download_service.dart';

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
    'Admin Quotas': (onNavigateToPage) => _createAdminQuotaTable(onNavigateToPage),
    'Driver Quotas': (onNavigateToPage) => _createDriverQuotasTable(onNavigateToPage),
    'Allowed Stops': (onNavigateToPage) => _createAllowedStopsTable(onNavigateToPage),
    'AI Chat History': (onNavigateToPage) => _createAiChatHistoryTable(onNavigateToPage),
    'Booking Archives': (onNavigateToPage) => _createBookingArchivesTable(onNavigateToPage),
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
    Map<String, dynamic>? selected;
    return TablePreviewHelper.createAdminTable(
      dataFetcher: () async {
        final data = await _supabase.from('adminTable').select('*').eq('is_archived', false);
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        debugPrint('Admin table refreshed');
      },
      onSelectionChanged: (row) {
        selected = row;
      },
      onArchive: () async {
        final id = selected?['admin_id'];
        if (id is int) {
          final ok = await ArchiveService.archiveAdmin(adminId: id);
          return ok;
        } else if (id is String) {
          final parsed = int.tryParse(id);
          if (parsed != null) {
            final ok = await ArchiveService.archiveAdmin(adminId: parsed);
            return ok;
          }
        }
        return false;
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
    Map<String, dynamic>? selected;
    return TablePreviewHelper.createDriverTable(
      dataFetcher: () async {
        final data = await _supabase.from('driverTable').select('*').eq('is_archived', false);
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        debugPrint('Driver table refreshed');
      },
      onFilterPressed: () {
        debugPrint('Driver filter pressed');
      },
      onSelectionChanged: (row) {
        selected = row;
      },
      onArchive: () async {
        final id = selected?['driver_id'];
        if (id is int) {
          final ok = await ArchiveService.archiveDriver(driverId: id);
          return ok;
        } else if (id is String) {
          final parsed = int.tryParse(id);
          if (parsed != null) {
            final ok = await ArchiveService.archiveDriver(driverId: parsed);
            return ok;
          }
        }
        return false;
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
        debugPrint('Vehicle table refreshed');
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
        debugPrint('Passenger table refreshed');
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
        debugPrint('Route table refreshed');
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
    Map<String, dynamic>? selected;
    return TablePreviewHelper.createBookingsTable(
      dataFetcher: () async {
        final data = await _supabase.from('bookings').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        debugPrint('Bookings table refreshed');
      },
      onSelectionChanged: (row) {
        selected = row;
      },
      onArchive: () async {
        final id = selected?['booking_id'];
        if (id is int) {
          final ok = await ArchiveService.archiveBooking(bookingId: id);
          return ok;
        } else if (id is String) {
          final parsed = int.tryParse(id);
          if (parsed != null) {
            final ok = await ArchiveService.archiveBooking(bookingId: parsed);
            return ok;
          }
        }
        return false;
      },
      includeNavigation: false, // Don't include navigation when used within main navigation
      onBackPressed: () {
        if (onNavigateToPage != null) {
          onNavigateToPage('/select_table');
        }
      },
    );
  }

  static Widget _createAdminQuotaTable(Function(String, {Map<String, dynamic>? args})? onNavigateToPage) {
    return TablePreviewHelper.createAdminQuotaTable(
      dataFetcher: () async {
        final data = await _supabase.from('adminQuotaTable').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        debugPrint('Admin quotas table refreshed');
      },
      includeNavigation: false,
      onBackPressed: () {
        if (onNavigateToPage != null) {
          onNavigateToPage('/select_table');
        }
      },
    );
  }

  static Widget _createDriverQuotasTable(Function(String, {Map<String, dynamic>? args})? onNavigateToPage) {
    return TablePreviewHelper.createDriverQuotasTable(
      dataFetcher: () async {
        final data = await _supabase.from('driverQuotasTable').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        debugPrint('Driver quotas table refreshed');
      },
      includeNavigation: false,
      onBackPressed: () {
        if (onNavigateToPage != null) {
          onNavigateToPage('/select_table');
        }
      },
    );
  }

  static Widget _createAllowedStopsTable(Function(String, {Map<String, dynamic>? args})? onNavigateToPage) {
    return TablePreviewHelper.createAllowedStopsTable(
      dataFetcher: () async {
        final data = await _supabase.from('allowed_stops').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        debugPrint('Allowed stops table refreshed');
      },
      includeNavigation: false,
      onBackPressed: () {
        if (onNavigateToPage != null) {
          onNavigateToPage('/select_table');
        }
      },
    );
  }

  static Widget _createAiChatHistoryTable(Function(String, {Map<String, dynamic>? args})? onNavigateToPage) {
    return TablePreviewHelper.createAiChatHistoryTable(
      dataFetcher: () async {
        final data = await _supabase.from('aiChat_history').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        debugPrint('AI chat history table refreshed');
      },
      includeNavigation: false,
      onBackPressed: () {
        if (onNavigateToPage != null) {
          onNavigateToPage('/select_table');
        }
      },
    );
  }

  static Widget _createBookingArchivesTable(Function(String, {Map<String, dynamic>? args})? onNavigateToPage) {
    return TablePreviewHelper.createBookingArchivesTable(
      dataFetcher: () async {
        final data = await _supabase.from('booking_archives').select('*');
        return (data as List).cast<Map<String, dynamic>>();
      },
      onRefresh: () {
        debugPrint('Booking archives table refreshed');
      },
      includeNavigation: false,
      onBackPressed: () {
        if (onNavigateToPage != null) {
          onNavigateToPage('/select_table');
        }
      },
    );
  }

  static Widget _createDriverArchivesTable(Function(String, {Map<String, dynamic>? args})? onNavigateToPage) {
    Map<String, dynamic>? selected;
    return TablePreviewHelper.createDriverArchivesTable(
      dataFetcher: () async {
        final data = await _supabase.from('driverTable').select('*').eq('is_archived', true);
        return (data as List).cast<Map<String, dynamic>>();
      },
      onSelectionChanged: (row) { selected = row; },
      onRecover: () async {
        final id = selected?['driver_id'];
        if (id is int) {
          final res = await _supabase
              .from('driverTable')
              .update({'is_archived': false})
              .match({'driver_id': id})
              .select()
              .maybeSingle();
          return res != null;
        } else if (id is String) {
          final parsed = int.tryParse(id);
          if (parsed != null) {
            final res = await _supabase
                .from('driverTable')
                .update({'is_archived': false})
                .match({'driver_id': parsed})
                .select()
                .maybeSingle();
            return res != null;
          }
        }
        return false;
      },
      onDelete: (alsoDownloadPdf) async {
        final id = selected?['driver_id'];
        Map<String, dynamic>? record = selected;
        if (record == null && id != null) {
          final fetched = await _supabase.from('driverTable').select('*').eq('driver_id', id).maybeSingle();
          if (fetched is Map<String, dynamic>) record = fetched;
        }
        if (alsoDownloadPdf && record != null) {
          final bytes = await PdfExportService.generateRecordPdf(
            title: 'Driver Record',
            record: record,
            postScript: """This document is an official extract of the driver record deleted from the PASADA administrative system. It is provided solely for statutory retention, audit, and incident review purposes. Access to this file is restricted to authorized personnel only.\n\nHandling and retention:\n- Store in a secure, access-controlled repository.\n- Retain in accordance with PASADA data retention and local regulatory requirements.\n- Do not transmit externally without written authorization from Compliance and Data Protection.\n\nRestoration and follow-up:\n- This file cannot be used to reinstate the account. To restore access, a new driver record must be created, subject to current onboarding policies and approvals.\n- If this deletion was performed in error, contact IT Support and Compliance immediately to initiate corrective procedures.\n\nConfidentiality notice:\n- This document may contain personal and/or sensitive information. Unauthorized disclosure, copying, or distribution is strictly prohibited and may be unlawful.\n\nFor any questions regarding this record, contact PASADA Compliance or the Systems Administration team.""",
          );
          // Try printing (native) and direct browser download (web)
          try { await Printing.layoutPdf(onLayout: (_) async => bytes); } catch (_) {}
          await FileDownloadService.saveBytesAsFile(bytes: bytes, filename: 'driver_${record['driver_id']}.pdf');
        }
        if (id is int) {
          final res = await _supabase.from('driverTable').delete().eq('driver_id', id);
          return (res is List) || (res == null) ? true : true;
        } else if (id is String) {
          final parsed = int.tryParse(id);
          if (parsed != null) {
            final res = await _supabase.from('driverTable').delete().eq('driver_id', parsed);
            return (res is List) || (res == null) ? true : true;
          }
        }
        return false;
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
    Map<String, dynamic>? selected;
    return TablePreviewHelper.createAdminArchivesTable(
      dataFetcher: () async {
        final data = await _supabase.from('adminTable').select('*').eq('is_archived', true);
        return (data as List).cast<Map<String, dynamic>>();
      },
      onSelectionChanged: (row) { selected = row; },
      onRecover: () async {
        final id = selected?['admin_id'];
        if (id is int) {
          final res = await _supabase
              .from('adminTable')
              .update({'is_archived': false})
              .match({'admin_id': id})
              .select()
              .maybeSingle();
          return res != null;
        } else if (id is String) {
          final parsed = int.tryParse(id);
          if (parsed != null) {
            final res = await _supabase
                .from('adminTable')
                .update({'is_archived': false})
                .match({'admin_id': parsed})
                .select()
                .maybeSingle();
            return res != null;
          }
        }
        return false;
      },
      onDelete: (alsoDownloadPdf) async {
        final id = selected?['admin_id'];
        Map<String, dynamic>? record = selected;
        if (record == null && id != null) {
          final fetched = await _supabase.from('adminTable').select('*').eq('admin_id', id).maybeSingle();
          if (fetched is Map<String, dynamic>) record = fetched;
        }
        if (alsoDownloadPdf && record != null) {
          final bytes = await PdfExportService.generateRecordPdf(
            title: 'Admin Record',
            record: record,
            postScript: """This document is an official extract of the administrator account record deleted from the PASADA administrative system. It is issued for internal recordkeeping, audit support, and regulatory inquiries. Distribution is strictly limited to authorized PASADA personnel.\n\nHandling and retention:\n- File must be stored in a secure, access-controlled location.\n- Retain per PASADA information governance and applicable regulations.\n- Do not share externally without written authorization from Compliance and Data Protection.\n\nRestoration and follow-up:\n- This file does not restore system privileges. To re-introduce an administrator, a new admin profile must be created and approved under current access control policies.\n- If this deletion was unintentional, notify IT Security and Compliance immediately for review and remediation.\n\nConfidentiality notice:\n- Content may include personal data and sensitive operational details. Unauthorized disclosure or misuse is prohibited and may violate policy and law.\n\nFor questions regarding this record, contact PASADA Compliance or Systems Administration.""",
          );
          try { await Printing.layoutPdf(onLayout: (_) async => bytes); } catch (_) {}
          await FileDownloadService.saveBytesAsFile(bytes: bytes, filename: 'admin_${record['admin_id']}.pdf');
        }
        if (id is int) {
          final res = await _supabase.from('adminTable').delete().eq('admin_id', id);
          return (res is List) || (res == null) ? true : true;
        } else if (id is String) {
          final parsed = int.tryParse(id);
          if (parsed != null) {
            final res = await _supabase.from('adminTable').delete().eq('admin_id', parsed);
            return (res is List) || (res == null) ? true : true;
          }
        }
        return false;
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
