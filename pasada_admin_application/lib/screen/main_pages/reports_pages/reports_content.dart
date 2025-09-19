import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/reports_chat.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:provider/provider.dart';

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
  
  // View mode: grid or list
  bool isGridView = true;

  @override
  void initState() {
    super.initState();
    fetchData();
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
      
      // Calculate total fares for each driver
      final driverFares = <int, double>{};
      final breakdownByDriver = <int, Map<String, dynamic>>{};
      double sumTotal = 0;
      
      // Get current date for weekly and monthly calculations
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);
      
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
              'weekly': 0.0,
              'monthly': 0.0,
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
              
              // Check if booking is within current week
              if (bookingDate.isAfter(startOfWeek) || 
                  bookingDate.isAtSameMomentAs(startOfWeek)) {
                breakdownByDriver[driverId]!['weekly'] = 
                    (breakdownByDriver[driverId]!['weekly'] as double) + fare;
                breakdownByDriver[driverId]!['weekly_bookings'].add(bookingDetail);
              }
              
              // Check if booking is within current month
              if (bookingDate.isAfter(startOfMonth) || 
                  bookingDate.isAtSameMomentAs(startOfMonth)) {
                breakdownByDriver[driverId]!['monthly'] = 
                    (breakdownByDriver[driverId]!['monthly'] as double) + fare;
                breakdownByDriver[driverId]!['monthly_bookings'].add(bookingDetail);
              }
            } catch (e) {
              print('Error parsing date: $e');
            }
          }
        }
      }
      
      // Combine driver info with their total fares
      final result = drivers.map((driver) {
        final driverId = driver['driver_id'];
        return {
          'driver_id': driverId,
          'full_name': driver['full_name'],
          'driver_number': driver['driver_number'],
          'vehicle_id': driver['vehicle_id'],
          'driving_status': driver['driving_status'],
          'total_fare': driverFares[driverId] ?? 0.0,
          'weekly_earnings': breakdownByDriver[driverId]?['weekly'] ?? 0.0,
          'monthly_earnings': breakdownByDriver[driverId]?['monthly'] ?? 0.0,
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
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
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
    final double screenWidth = MediaQuery.of(context)
        .size
        .width
        .clamp(600.0, double.infinity)
        .toDouble();
    final double horizontalPadding = screenWidth * 0.05;

    return Container(
      color: isDark ? Palette.darkSurface : Palette.lightSurface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double minBodyWidth = 900;
          final double effectiveWidth = constraints.maxWidth < minBodyWidth
              ? minBodyWidth
              : constraints.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: minBodyWidth),
              child: SizedBox(
                width: effectiveWidth,
                child: Column(
                  children: [
                    Expanded(
                      child: isLoading
                          ? Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 24.0,
                                  horizontal: horizontalPadding,
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: isDark
                                              ? Palette.darkSurface
                                              : Palette.lightSurface,
                                          child: Icon(
                                            Icons.bar_chart,
                                            color: isDark
                                                ? Palette.darkText
                                                : Palette.lightText,
                                          ),
                                        ),
                                        const SizedBox(width: 12.0),
                                        Text(
                                          "Reports",
                                          style: TextStyle(
                                            fontSize: 28.0,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Palette.darkText
                                                : Palette.lightText,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        const Spacer(),
                                      ],
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Palette.darkCard
                                                : Palette.lightCard,
                                            border: Border.all(
                                              color: isDark
                                                  ? Palette.darkBorder
                                                  : Palette.lightBorder,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.grid_view,
                                                  size: 18,
                                                  color: isGridView
                                                      ? (isDark
                                                          ? Palette
                                                              .darkText
                                                          : Palette
                                                              .lightText)
                                                      : (isDark
                                                          ? Palette
                                                              .darkTextSecondary
                                                          : Palette
                                                              .lightTextSecondary),
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    isGridView = true;
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.view_list,
                                                  size: 18,
                                                  color: !isGridView
                                                      ? (isDark
                                                          ? Palette
                                                              .darkText
                                                          : Palette
                                                              .lightText)
                                                      : (isDark
                                                          ? Palette
                                                              .darkTextSecondary
                                                          : Palette
                                                              .lightTextSecondary),
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    isGridView = false;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16.0),
                                    isGridView
                                        ? _buildGridView()
                                        : _buildListView(),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Grid view implementation
  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth >= 1200) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 800) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 24.0,
          mainAxisSpacing: 24.0,
          childAspectRatio: 2.2,
          children: driversWithFares.map((driver) {
            return _buildDriverEarningsCard(driver);
          }).toList(),
        );
      },
    );
  }
  
  // List view implementation
  Widget _buildListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: driversWithFares.length,
      itemBuilder: (context, index) {
        final driver = driversWithFares[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildDriverEarningsListItem(driver),
        );
      },
    );
  }
  
  // Driver earnings card for grid view
  Widget _buildDriverEarningsCard(Map<String, dynamic> driver) {
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
        borderRadius: BorderRadius.circular(15.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Palette.darkCard : Palette.lightCard,
            border: Border.all(
              color: isDark
                  ? Palette.darkBorder.withValues(alpha: 77)
                  : Palette.lightBorder.withValues(alpha: 77),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(15.0),
          ),
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 12.0),
          child: Stack(
            children: [
              // Status indicator dot
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              Row(
                children: [
                  // Enhanced avatar with gradient background
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
                      radius: 28,
                      backgroundColor: Colors.transparent,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${driver['full_name'] ?? 'Unknown Driver'}",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Palette.darkText : Palette.lightText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8.0),
                        _buildDriverInfoRow(Icons.badge_outlined, "ID: ${driver['driver_id']}"),
                        _buildDriverInfoRow(
                          isActive ? Icons.play_circle_outline : Icons.pause_circle_outline,
                          "Status: $status",
                          textColor: statusColor,
                        ),
                        _buildDriverInfoRow(
                          Icons.monetization_on, 
                          "Total: ₱${driver['total_fare'].toStringAsFixed(2)}", 
                          textColor: Palette.greenColor
                        ),
                      ],
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
                    
                    // Weekly earnings
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDriverInfoRow(
                            Icons.date_range,
                            "₱${driver['weekly_earnings'].toStringAsFixed(2)}",
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
                    
                    // Total earnings
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDriverInfoRow(
                            Icons.monetization_on,
                            "₱${driver['total_fare'].toStringAsFixed(2)}",
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
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor ?? (isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.0,
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
