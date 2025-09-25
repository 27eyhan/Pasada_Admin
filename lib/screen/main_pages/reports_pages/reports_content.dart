import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:pasada_admin_application/widgets/responsive_layout.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/reports_chat.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:pasada_admin_application/services/quota_service.dart';
import 'package:pasada_admin_application/widgets/quota/quota_bento_grid.dart';
import 'package:pasada_admin_application/widgets/quota/quota_edit_dialog.dart';
import 'package:pasada_admin_application/widgets/quota/quota_update_dialog.dart';

class ReportsContent extends StatefulWidget {
  final Function(String, {Map<String, dynamic>? args})? onNavigateToPage;

  const ReportsContent({super.key, this.onNavigateToPage});

  @override
  _ReportsContentState createState() => _ReportsContentState();
}

class _ReportsContentState extends State<ReportsContent> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> driversWithFares = [];
  Map<int, Map<String, dynamic>> driverEarningsBreakdown = {};
  bool isLoading = true;
  
  // Summary statistics
  int totalDrivers = 0;
  double totalEarnings = 0;
  // Aggregated earnings by period
  double dailyEarnings = 0;
  double weeklyEarnings = 0;
  double monthlyEarnings = 0;

  // Quota targets (loaded from adminQuotaTable; defaults to zero)
  double dailyQuotaTarget = 0; // ₱
  double weeklyQuotaTarget = 0; // ₱
  double monthlyQuotaTarget = 0; // ₱
  double overallQuotaTarget = 0; // ₱
  

  @override
  void initState() {
    super.initState();
    fetchData();
    _fetchQuotaTargets();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Fetch drivers data
      final driversResponse = await supabase.from('driverTable').select('driver_id, full_name, driver_number, vehicle_id, driving_status');
      final List driversData = driversResponse as List;
      final drivers = driversData.cast<Map<String, dynamic>>();
      
      // Fetch bookings data with assigned_at field
      final bookingsResponse = await supabase.from('bookings').select('driver_id, fare, assigned_at');
      final List bookingsData = bookingsResponse as List;
      final bookings = bookingsData.cast<Map<String, dynamic>>();
      
      // Fetch precomputed per-driver quotas
      final quotasResponse = await supabase
          .from('driverQuotasTable')
          .select('driver_id, quota_daily, quota_weekly, quota_monthly, quota_total');
      final Map<int, Map<String, double>> driverQuotas = {};
      for (final row in (quotasResponse as List).cast<Map<String, dynamic>>()) {
        final did = row['driver_id'];
        if (did == null) continue;
        driverQuotas[did is int ? did : int.tryParse(did.toString()) ?? -1] = {
          'daily': double.tryParse(row['quota_daily']?.toString() ?? '0') ?? 0,
          'weekly': double.tryParse(row['quota_weekly']?.toString() ?? '0') ?? 0,
          'monthly': double.tryParse(row['quota_monthly']?.toString() ?? '0') ?? 0,
          'total': double.tryParse(row['quota_total']?.toString() ?? '0') ?? 0,
        };
      }

      // Calculate total fares for each driver
      final driverFares = <int, double>{};
      final breakdownByDriver = <int, Map<String, dynamic>>{};
      double sumTotal = 0;
      
      // Get current date for daily, weekly and monthly calculations
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);
      double dailySum = 0;
      double weeklySum = 0;
      double monthlySum = 0;
      
      for (var booking in bookings) {
        final driverId = booking['driver_id'];
        if (driverId != null) {
          final fare = double.tryParse(booking['fare']?.toString() ?? '0') ?? 0;
          
          // Update total fare
          driverFares[driverId] = (driverFares[driverId] ?? 0) + fare;
          sumTotal += fare;
          
          // Initialize breakdown map if needed
          if (!breakdownByDriver.containsKey(driverId)) {
            breakdownByDriver[driverId] = {
              'daily': 0.0,
              'weekly': 0.0,
              'monthly': 0.0,
              'daily_bookings': [],
              'weekly_bookings': [],
              'monthly_bookings': [],
              'all_bookings': [],
            };
          }
          
          // Add booking to all bookings list
          var assignedAt = booking['assigned_at'];
          DateTime? bookingDate;
          
          if (assignedAt != null) {
            try {
              bookingDate = DateTime.parse(assignedAt.toString());
              
              // Store booking details
              final bookingDetail = {
                'fare': fare,
                'date': bookingDate,
                'formatted_date': DateFormat('MMM dd, yyyy').format(bookingDate),
              };
              
              breakdownByDriver[driverId]!['all_bookings'].add(bookingDetail);
              
              // Aggregate totals by period (daily)
              if (bookingDate.isAfter(startOfDay) ||
                  bookingDate.isAtSameMomentAs(startOfDay)) {
                dailySum += fare;
                breakdownByDriver[driverId]!['daily'] =
                    (breakdownByDriver[driverId]!['daily'] as double) + fare;
                breakdownByDriver[driverId]!['daily_bookings'].add(bookingDetail);
              }

              // Check if booking is within current week
              if (bookingDate.isAfter(startOfWeek) || 
                  bookingDate.isAtSameMomentAs(startOfWeek)) {
                breakdownByDriver[driverId]!['weekly'] = 
                    (breakdownByDriver[driverId]!['weekly'] as double) + fare;
                breakdownByDriver[driverId]!['weekly_bookings'].add(bookingDetail);
                weeklySum += fare;
              }
              
              // Check if booking is within current month
              if (bookingDate.isAfter(startOfMonth) || 
                  bookingDate.isAtSameMomentAs(startOfMonth)) {
                breakdownByDriver[driverId]!['monthly'] = 
                    (breakdownByDriver[driverId]!['monthly'] as double) + fare;
                breakdownByDriver[driverId]!['monthly_bookings'].add(bookingDetail);
                monthlySum += fare;
              }
            } catch (e) {
              debugPrint('Error parsing date: $e');
            }
          }
        }
      }
      
      // Combine driver info with their total fares
      final result = drivers.map((driver) {
        final driverId = driver['driver_id'];
        final quotas = driverQuotas[driverId is int ? driverId : int.tryParse(driverId.toString()) ?? -1] ?? {'daily': 0, 'weekly': 0, 'monthly': 0, 'total': 0};
        return {
          'driver_id': driverId,
          'full_name': driver['full_name'],
          'driver_number': driver['driver_number'],
          'vehicle_id': driver['vehicle_id'],
          'driving_status': driver['driving_status'],
          'total_fare': driverFares[driverId] ?? 0.0,
          'daily_earnings': breakdownByDriver[driverId]?['daily'] ?? 0.0,
          'weekly_earnings': breakdownByDriver[driverId]?['weekly'] ?? 0.0,
          'monthly_earnings': breakdownByDriver[driverId]?['monthly'] ?? 0.0,
          'quota_daily': quotas['daily'] ?? 0.0,
          'quota_weekly': quotas['weekly'] ?? 0.0,
          'quota_monthly': quotas['monthly'] ?? 0.0,
          'quota_total': quotas['total'] ?? 0.0,
        };
      }).toList();
      
      // Sort the drivers by driver_id in numerical order
      result.sort((a, b) {
        final idA = a['driver_id'] is int ? a['driver_id'] : int.tryParse(a['driver_id'].toString()) ?? 0;
        final idB = b['driver_id'] is int ? b['driver_id'] : int.tryParse(b['driver_id'].toString()) ?? 0;
        return idA.compareTo(idB);
      });
      
      setState(() {
        driversWithFares = result;
        driverEarningsBreakdown = breakdownByDriver;
        totalDrivers = result.length;
        totalEarnings = sumTotal;
        dailyEarnings = dailySum;
        weeklyEarnings = weeklySum;
        monthlyEarnings = monthlySum;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchQuotaTargets() async {
    // Prefer server-computed per-driver quota sums for accuracy
    final targets = await QuotaService.fetchFleetTotalsFromDriverQuotas(supabase);
    if (!mounted) return;
    setState(() {
      dailyQuotaTarget = targets.daily;
      weeklyQuotaTarget = targets.weekly;
      monthlyQuotaTarget = targets.monthly;
      overallQuotaTarget = targets.total;
    });
  }

  void _showEarningsBreakdown(Map<String, dynamic> driver) {
    final driverId = driver['driver_id'];
    final breakdown = driverEarningsBreakdown[driverId];
    
    if (breakdown == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No earnings data available for this driver'))
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EarningsBreakdownDialog(
          driver: driver,
          breakdown: breakdown,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      color: isDark ? Palette.darkSurface : Palette.lightSurface,
      child: ResponsiveLayout(
        minWidth: 900,
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: ResponsivePadding(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: ResponsiveHelper.getResponsiveAvatarRadius(context),
                                  backgroundColor: isDark
                                      ? Palette.darkSurface
                                      : Palette.lightSurface,
                                  child: Icon(
                                    Icons.bar_chart,
                                    color: isDark
                                        ? Palette.darkText
                                        : Palette.lightText,
                                    size: ResponsiveHelper.getResponsiveIconSize(context),
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                ResponsiveText(
                                  "Reports",
                                  mobileFontSize: 24.0,
                                  tabletFontSize: 26.0,
                                  desktopFontSize: 28.0,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Palette.darkText : Palette.lightText,
                                ),
                                const Spacer(),
                              ],
                            ),
                            const SizedBox(height: 24.0),
                            // Quota Bento Grid + edit
                            QuotaBentoGrid(
                              dailyEarnings: dailyEarnings,
                              weeklyEarnings: weeklyEarnings,
                              monthlyEarnings: monthlyEarnings,
                              totalEarnings: totalEarnings,
                              dailyTarget: dailyQuotaTarget,
                              weeklyTarget: weeklyQuotaTarget,
                              monthlyTarget: monthlyQuotaTarget,
                              totalTarget: overallQuotaTarget,
                              onEdit: _openEditQuotaDialog,
                              onRefresh: _refreshQuotas,
                              onUpdate: _openUpdateQuotaDialog,
                            ),
                            const SizedBox(height: 24.0),
                            // Status metrics container with separators
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? Palette.darkCard : Palette.lightCard,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: isDark ? Palette.darkBorder : Palette.lightBorder,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withValues(alpha: 0.08)
                                        : Colors.grey.withValues(alpha: 0.08),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildCompactMetric(
                                      'Total Drivers',
                                      totalDrivers,
                                      isDark
                                          ? Palette.darkText
                                          : Palette.lightText,
                                    ),
                                  ),
                                  _buildVerticalSeparator(isDark),
                                  Expanded(
                                    child: _buildCompactMetric(
                                      'Total Earnings',
                                      totalEarnings.toInt(),
                                      isDark
                                          ? Palette.darkText
                                          : Palette.lightText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24.0),
                            const SizedBox(height: 16.0),
                            _buildListView(),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
                ),
              ),
  
    );
  }
  
  // Removed inline Quota grid/card widgets in favor of dedicated widget

  void _openEditQuotaDialog() async {
    // Prepare driver list for selector
    final drivers = driversWithFares
        .map((d) => {
              'driver_id': d['driver_id'],
              'full_name': d['full_name'] ?? 'Driver ${d['driver_id']}',
            })
        .toList();

    await showQuotaEditDialog(
      context: context,
      dailyInitial: dailyQuotaTarget,
      weeklyInitial: weeklyQuotaTarget,
      monthlyInitial: monthlyQuotaTarget,
      drivers: drivers,
      initialDriverId: null,
      onSave: ({required double daily, required double weekly, required double monthly, required double total, int? driverId}) async {
        await _saveQuotaTargets(daily: daily, weekly: weekly, monthly: monthly, total: total, driverId: driverId);
      },
    );
  }
  void _openUpdateQuotaDialog() async {
    final drivers = driversWithFares
        .map((d) => {
              'driver_id': d['driver_id'],
              'full_name': d['full_name'] ?? 'Driver ${d['driver_id']}',
            })
        .toList();

    await showQuotaUpdateDialog(
      context: context,
      dailyInitial: dailyQuotaTarget,
      weeklyInitial: weeklyQuotaTarget,
      monthlyInitial: monthlyQuotaTarget,
      drivers: drivers,
      initialDriverId: null,
      onSave: ({required double daily, required double weekly, required double monthly, required double total, int? driverId}) async {
        await _saveQuotaTargets(daily: daily, weekly: weekly, monthly: monthly, total: total, driverId: driverId);
      },
    );
  }

  // Removed: inline number field (moved to quota_edit_dialog.dart)

  Future<void> _refreshQuotas() async {
    await _fetchQuotaTargets();
    if (mounted) setState(() {});
  }

  Future<void> _saveQuotaTargets({
    required double daily,
    required double weekly,
    required double monthly,
    required double total,
    int? driverId,
  }) async {
    try {
      debugPrint('[ReportsContent._saveQuotaTargets] saving for driverId=$driverId daily=$daily weekly=$weekly monthly=$monthly total=$total');
      await QuotaService.saveGlobalQuotaTargets(
        supabase,
        daily: daily,
        weekly: weekly,
        monthly: monthly,
        total: total,
        createdByAdminId: null,
        driverId: driverId,
      );

      await _fetchQuotaTargets();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error saving quota targets: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save quotas')), 
        );
      }
    }
  }

  
  // List view implementation
  Widget _buildListView() {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: driversWithFares.length,
      itemBuilder: (context, index) {
        final driver = driversWithFares[index];
        return Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 12.0 : 16.0),
          child: isMobile 
              ? _buildMobileDriverListItem(driver)
              : _buildDriverEarningsListItem(driver),
        );
      },
    );
  }
  




  // Mobile-optimized list item
  Widget _buildMobileDriverListItem(Map<String, dynamic> driver) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final status = driver['driving_status'] ?? 'Offline';
    final isActive = status.toLowerCase() == 'online' || 
                     status.toLowerCase() == 'driving' || 
                     status.toLowerCase() == 'idling' || 
                     status.toLowerCase() == 'active';
    final statusColor = isActive ? Colors.green : Colors.red;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => _showEarningsBreakdown(driver),
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Palette.darkCard : Palette.lightCard,
            border: Border.all(
              color: isDark
                  ? Palette.darkBorder.withValues(alpha: 77)
                  : Palette.lightBorder.withValues(alpha: 77),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Header row
              Row(
                children: [
                  // Avatar with status
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isDark 
                                ? [Colors.grey.shade600, Colors.grey.shade800]
                                : [Colors.grey.shade400, Colors.grey.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.transparent,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${driver['full_name'] ?? 'Unknown Driver'}",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Palette.darkText : Palette.lightText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          "ID: ${driver['driver_id']} • $status",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.0,
                            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              // Metrics in a 2x2 grid
              Row(
                children: [
                  Expanded(
                    child: _buildMobileMetricItem(
                      "Daily",
                      "₱${(driver['daily_earnings'] as double).toStringAsFixed(0)}",
                      "₱${(driver['quota_daily'] as double).toStringAsFixed(0)}",
                      Icons.today,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildMobileMetricItem(
                      "Weekly",
                      "₱${(driver['weekly_earnings'] as double).toStringAsFixed(0)}",
                      "₱${(driver['quota_weekly'] as double).toStringAsFixed(0)}",
                      Icons.date_range,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: _buildMobileMetricItem(
                      "Monthly",
                      "₱${(driver['monthly_earnings'] as double).toStringAsFixed(0)}",
                      "₱${(driver['quota_monthly'] as double).toStringAsFixed(0)}",
                      Icons.calendar_month,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildMobileMetricItem(
                      "Total",
                      "₱${(driver['total_fare'] as double).toStringAsFixed(0)}",
                      "₱${(driver['quota_total'] as double).toStringAsFixed(0)}",
                      Icons.monetization_on,
                      isDark,
                      isHighlighted: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mobile metric item for list view
  Widget _buildMobileMetricItem(String label, String current, String target, IconData icon, bool isDark, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: isHighlighted 
            ? (isDark ? Palette.darkSurface : Palette.lightSurface)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6.0),
        border: isHighlighted 
            ? Border.all(color: Palette.greenColor.withValues(alpha: 0.3), width: 1.0)
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: isHighlighted ? Palette.greenColor : (isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.0,
                    color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2.0),
          Text(
            current,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.0,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Palette.greenColor : (isDark ? Palette.darkText : Palette.lightText),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            "/ $target",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9.0,
              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  // Driver earnings list item for list view
  Widget _buildDriverEarningsListItem(Map<String, dynamic> driver) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final status = driver['driving_status'] ?? 'Offline';
    final isActive = status.toLowerCase() == 'online' || 
                     status.toLowerCase() == 'driving' || 
                     status.toLowerCase() == 'idling' || 
                     status.toLowerCase() == 'active';
    final statusColor = isActive ? Colors.green : Colors.red;
    final statusIcon = isActive ? Icons.play_circle_outline : Icons.pause_circle_outline;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => _showEarningsBreakdown(driver),
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Palette.darkCard : Palette.lightCard,
            border: Border.all(
              color: isDark
                  ? Palette.darkBorder.withValues(alpha: 77)
                  : Palette.lightBorder.withValues(alpha: 77),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              // Avatar with status indicator
              Stack(
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDark 
                            ? [Colors.grey.shade600, Colors.grey.shade800]
                            : [Colors.grey.shade400, Colors.grey.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.transparent,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  
                  // Status indicator
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 16.0),
              
              // Driver info
              Expanded(
                child: Row(
                  children: [
                    // Name and ID
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${driver['full_name'] ?? 'Unknown Driver'}",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Palette.darkText : Palette.lightText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            "ID: ${driver['driver_id']}",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.0,
                              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDriverInfoRow(
                            statusIcon,
                            status,
                            textColor: statusColor,
                          ),
                        ],
                      ),
                    ),
                    
                    // Daily earnings (Current / Target)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDriverInfoRow(
                            Icons.today,
                            "₱${(driver['daily_earnings'] as double).toStringAsFixed(2)} / ₱${(driver['quota_daily'] as double).toStringAsFixed(0)}",
                            textColor: Palette.greenColor,
                          ),
                          Text(
                            "Daily",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.0,
                              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Weekly earnings (Current / Target)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDriverInfoRow(
                            Icons.date_range,
                            "₱${(driver['weekly_earnings'] as double).toStringAsFixed(2)} / ₱${(driver['quota_weekly'] as double).toStringAsFixed(0)}",
                            textColor: Palette.greenColor,
                          ),
                          Text(
                            "Weekly",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.0,
                              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Monthly earnings (Current / Target)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDriverInfoRow(
                            Icons.calendar_month,
                            "₱${(driver['monthly_earnings'] as double).toStringAsFixed(2)} / ₱${(driver['quota_monthly'] as double).toStringAsFixed(0)}",
                            textColor: Palette.greenColor,
                          ),
                          Text(
                            "Monthly",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.0,
                              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Total earnings (Current / Target)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDriverInfoRow(
                            Icons.monetization_on,
                            "₱${(driver['total_fare'] as double).toStringAsFixed(2)} / ₱${(driver['quota_total'] as double).toStringAsFixed(0)}",
                            textColor: Palette.greenColor,
                          ),
                          Text(
                            "Total",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.0,
                              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for driver info rows with icons
  Widget _buildDriverInfoRow(IconData icon, String text, {Color? textColor}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 12,
            color: textColor ?? (isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
          ),
          SizedBox(width: 3),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.0,
                color: textColor ?? (isDark ? Palette.darkText : Palette.lightText),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Compact metric item: uppercase label above value (Fleet-like)
  Widget _buildCompactMetric(String label, int value, Color valueColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.0,
            letterSpacing: 0.6,
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          value.toString(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22.0,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // Vertical separator for status metrics
  Widget _buildVerticalSeparator(bool isDark) {
    return Container(
      height: 40.0,
      width: 1.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: isDark ? Palette.darkDivider : Palette.lightDivider,
        borderRadius: BorderRadius.circular(0.5),
      ),
    );
  }

}
