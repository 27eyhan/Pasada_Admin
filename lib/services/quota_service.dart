import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuotaTargets {
  final double daily;
  final double weekly;
  final double monthly;
  final double total;

  const QuotaTargets({
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.total,
  });

  QuotaTargets copyWith({double? daily, double? weekly, double? monthly, double? total}) {
    return QuotaTargets(
      daily: daily ?? this.daily,
      weekly: weekly ?? this.weekly,
      monthly: monthly ?? this.monthly,
      total: total ?? this.total,
    );
  }
}

class QuotaService {
  static const String tableName = 'adminQuotaTable';
  static const String driverQuotasTable = 'driverQuotasTable';

  static Future<QuotaTargets> fetchGlobalQuotaTargets(SupabaseClient supabase) async {
    try {
      final now = DateTime.now();
      final response = await supabase
          .from(tableName)
          .select('period, target_amount, driver_id, start_at, end_at, is_active')
          .eq('is_active', true);

      final List rawList = response as List;
      double dailySum = 0;
      double weeklySum = 0;
      double monthlySum = 0;
      double totalSum = 0;

      for (final row in rawList.cast<Map<String, dynamic>>()) {
        // Sum across ALL active quotas (global and per-driver)

        DateTime? startAt;
        DateTime? endAt;
        final startAtVal = row['start_at'];
        final endAtVal = row['end_at'];
        try { if (startAtVal != null) startAt = DateTime.parse(startAtVal.toString()); } catch (_) {}
        try { if (endAtVal != null) endAt = DateTime.parse(endAtVal.toString()); } catch (_) {}
        final withinWindow = (startAt == null || !now.isBefore(startAt)) && (endAt == null || !now.isAfter(endAt));
        if (!withinWindow) continue;

        final period = (row['period'] ?? '').toString().toLowerCase();
        final amount = double.tryParse(row['target_amount']?.toString() ?? '0') ?? 0;
        switch (period) {
          case 'daily':
            dailySum += amount;
            break;
          case 'weekly':
            weeklySum += amount;
            break;
          case 'monthly':
            monthlySum += amount;
            break;
          case 'total':
          case 'overall':
            totalSum += amount;
            break;
          default:
            break;
        }
      }

      return QuotaTargets(daily: dailySum, weekly: weeklySum, monthly: monthlySum, total: totalSum);
    } catch (e) {
      debugPrint('QuotaService.fetchGlobalQuotaTargets error: $e');
      return const QuotaTargets(daily: 0, weekly: 0, monthly: 0, total: 0);
    }
  }

  static Future<void> saveGlobalQuotaTargets(
    SupabaseClient supabase, {
    required double daily,
    required double weekly,
    required double monthly,
    required double total,
    required int? createdByAdminId,
    int? driverId,
  }) async {
    debugPrint('[QuotaService.saveGlobalQuotaTargets] driverId=$driverId daily=$daily weekly=$weekly monthly=$monthly total=$total');
    // Deactivate previous quotas for this scope (driver or global)
    final updateQuery = supabase
        .from(tableName)
        .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
        .eq('is_active', true);
    // If RLS restricts updates to rows created by the same admin, include that filter
    if (createdByAdminId != null) {
      updateQuery.eq('created_by', createdByAdminId);
    }
    if (driverId == null) {
      // Use generic filter with 'is' operator for NULL
      updateQuery.filter('driver_id', 'is', null);
    } else {
      updateQuery.eq('driver_id', driverId);
    }
    try {
      final res = await updateQuery;
      if (kDebugMode) {
        debugPrint('[QuotaService.saveGlobalQuotaTargets] deactivated rows result: $res');
      }
    } catch (e) {
      debugPrint('[QuotaService.saveGlobalQuotaTargets] deactivate error: $e');
    }

    final nowIso = DateTime.now().toIso8601String();
    final rows = <Map<String, dynamic>>[];
    void addRow(double value, String period) {
      if (value <= 0) return;
      rows.add({
        'driver_id': driverId,
        'target_amount': value,
        'period': period,
        'is_active': true,
        'created_by': createdByAdminId,
        'created_at': nowIso,
        'updated_at': nowIso,
      });
    }

    addRow(daily, 'daily');
    addRow(weekly, 'weekly');
    addRow(monthly, 'monthly');
    addRow(total, 'total');

    if (rows.isNotEmpty) {
      try {
        final insertRes = await supabase.from(tableName).insert(rows);
        if (kDebugMode) {
          debugPrint('[QuotaService.saveGlobalQuotaTargets] inserted ${rows.length} rows: $insertRes');
        }
      } catch (e) {
        debugPrint('[QuotaService.saveGlobalQuotaTargets] insert error: $e');
      }
    }

    // Trigger server-side aggregation into driverQuotasTable
    if (driverId != null) {
      // Recompute for the specific driver
      try {
        final rpcRes = await supabase.rpc('update_driver_quotas', params: {'p_driver_id': driverId});
        if (kDebugMode) debugPrint('[QuotaService.saveGlobalQuotaTargets] rpc update_driver_quotas result: $rpcRes');
      } catch (e) {
        debugPrint('[QuotaService.saveGlobalQuotaTargets] rpc update_driver_quotas error: $e');
      }
    } else {
      // Global quotas changed: recompute for all drivers
      try {
        final idsRes = await supabase.from('driverTable').select('driver_id');
        final List idsList = idsRes as List;
        for (final row in idsList.cast<Map<String, dynamic>>()) {
          final did = row['driver_id'];
          if (did == null) continue;
          try {
            await supabase.rpc('update_driver_quotas', params: {'p_driver_id': did});
          } catch (e) {
            debugPrint('[QuotaService.saveGlobalQuotaTargets] rpc update_driver_quotas error for driver $did: $e');
          }
        }
        if (kDebugMode) debugPrint('[QuotaService.saveGlobalQuotaTargets] recomputed quotas for ${idsList.length} drivers');
      } catch (e) {
        debugPrint('[QuotaService.saveGlobalQuotaTargets] fetch driver ids error: $e');
      }
    }
  }

  // Sum per-driver quotas by period (ignores global rows).
  static Future<QuotaTargets> fetchDriverSumTargets(
    SupabaseClient supabase,
  ) async {
    try {
      final response = await supabase
          .from(tableName)
          .select('period, target_amount, driver_id, is_active')
          .eq('is_active', true);

      final List rawList = response as List;

      double perDriverDaily = 0, perDriverWeekly = 0, perDriverMonthly = 0, perDriverTotal = 0;

      int countedRows = 0;
      for (final row in rawList.cast<Map<String, dynamic>>()) {
        final isPerDriver = row['driver_id'] != null;
        final period = (row['period'] ?? '').toString().toLowerCase();
        final amount = double.tryParse(row['target_amount']?.toString() ?? '0') ?? 0;
        if (!isPerDriver) continue; // ignore global rows in sums
        countedRows++;
        switch (period) {
          case 'daily':
            perDriverDaily += amount;
            break;
          case 'weekly':
            perDriverWeekly += amount;
            break;
          case 'monthly':
            perDriverMonthly += amount;
            break;
          case 'overall':
          case 'total':
            perDriverTotal += amount;
            break;
          default:
            break;
        }
      }

      if (kDebugMode) {
        debugPrint('[QuotaService.fetchDriverSumTargets] active per-driver rows counted: $countedRows');
        debugPrint('[QuotaService.fetchDriverSumTargets] sums daily=$perDriverDaily weekly=$perDriverWeekly monthly=$perDriverMonthly total=$perDriverTotal');
      }
      return QuotaTargets(daily: perDriverDaily, weekly: perDriverWeekly, monthly: perDriverMonthly, total: perDriverTotal);
    } catch (e) {
      debugPrint('QuotaService.fetchDriverSumTargets error: $e');
      return const QuotaTargets(daily: 0, weekly: 0, monthly: 0, total: 0);
    }
  }

  // Fleet totals by summing precomputed per-driver quotas (from driverQuotasTable)
  static Future<QuotaTargets> fetchFleetTotalsFromDriverQuotas(
    SupabaseClient supabase,
  ) async {
    try {
      final response = await supabase
          .from(driverQuotasTable)
          .select('quota_daily, quota_weekly, quota_monthly, quota_total');
      final List rawList = response as List;
      double daily = 0, weekly = 0, monthly = 0, total = 0;
      for (final row in rawList.cast<Map<String, dynamic>>()) {
        daily += double.tryParse(row['quota_daily']?.toString() ?? '0') ?? 0;
        weekly += double.tryParse(row['quota_weekly']?.toString() ?? '0') ?? 0;
        monthly += double.tryParse(row['quota_monthly']?.toString() ?? '0') ?? 0;
        total += double.tryParse(row['quota_total']?.toString() ?? '0') ?? 0;
      }
      if (kDebugMode) {
        debugPrint('[QuotaService.fetchFleetTotalsFromDriverQuotas] sums daily=$daily weekly=$weekly monthly=$monthly total=$total rows=${rawList.length}');
      }
      return QuotaTargets(daily: daily, weekly: weekly, monthly: monthly, total: total);
    } catch (e) {
      debugPrint('QuotaService.fetchFleetTotalsFromDriverQuotas error: $e');
      return const QuotaTargets(daily: 0, weekly: 0, monthly: 0, total: 0);
    }
  }
}


