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
    // Deactivate previous quotas for this scope (driver or global)
    final updateQuery = supabase
        .from(tableName)
        .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
        .eq('is_active', true);
    if (driverId == null) {
      updateQuery.isFilter('driver_id', null);
    } else {
      updateQuery.eq('driver_id', driverId);
    }
    await updateQuery;

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
      await supabase.from(tableName).insert(rows);
    }
  }

  // Compute totals for all drivers per period.
  // Logic: If there are any per-driver quotas for a period, sum only those.
  // Otherwise, multiply the global quota for that period by driversCount.
  static Future<QuotaTargets> fetchSummedTargets(
    SupabaseClient supabase, {
    required int driversCount,
  }) async {
    try {
      final response = await supabase
          .from(tableName)
          .select('period, target_amount, driver_id, is_active')
          .eq('is_active', true);

      final List rawList = response as List;

      double perDriverDaily = 0, perDriverWeekly = 0, perDriverMonthly = 0, perDriverTotal = 0;
      double globalDaily = 0, globalWeekly = 0, globalMonthly = 0, globalTotal = 0;
      bool hasPerDriverDaily = false, hasPerDriverWeekly = false, hasPerDriverMonthly = false, hasPerDriverTotal = false;

      for (final row in rawList.cast<Map<String, dynamic>>()) {
        final isPerDriver = row['driver_id'] != null;
        final period = (row['period'] ?? '').toString().toLowerCase();
        final amount = double.tryParse(row['target_amount']?.toString() ?? '0') ?? 0;
        switch (period) {
          case 'daily':
            if (isPerDriver) {
              hasPerDriverDaily = true;
              perDriverDaily += amount;
            } else {
              globalDaily += amount;
            }
            break;
          case 'weekly':
            if (isPerDriver) {
              hasPerDriverWeekly = true;
              perDriverWeekly += amount;
            } else {
              globalWeekly += amount;
            }
            break;
          case 'monthly':
            if (isPerDriver) {
              hasPerDriverMonthly = true;
              perDriverMonthly += amount;
            } else {
              globalMonthly += amount;
            }
            break;
          case 'overall':
          case 'total':
            if (isPerDriver) {
              hasPerDriverTotal = true;
              perDriverTotal += amount;
            } else {
              globalTotal += amount;
            }
            break;
          default:
            break;
        }
      }

      final daily = hasPerDriverDaily ? perDriverDaily : (globalDaily * driversCount);
      final weekly = hasPerDriverWeekly ? perDriverWeekly : (globalWeekly * driversCount);
      final monthly = hasPerDriverMonthly ? perDriverMonthly : (globalMonthly * driversCount);
      final total = hasPerDriverTotal ? perDriverTotal : (globalTotal * driversCount);

      return QuotaTargets(daily: daily, weekly: weekly, monthly: monthly, total: total);
    } catch (e) {
      debugPrint('QuotaService.fetchSummedTargets error: $e');
      return const QuotaTargets(daily: 0, weekly: 0, monthly: 0, total: 0);
    }
  }
}


