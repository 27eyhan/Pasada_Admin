import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:provider/provider.dart';

class EarningsBreakdownDialog extends StatelessWidget {
  final Map<String, dynamic> driver;
  final Map<String, dynamic>? breakdown;
  
  const EarningsBreakdownDialog({
    super.key,
    required this.driver,
    this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final double screenWidth = MediaQuery.of(context).size.width * 0.65;
    final double dialogWidth = screenWidth * 0.6;
    final double dialogHeight = screenWidth * 0.75;
    
    // Calculate column widths
    final double columnWidth = (dialogWidth - 80) / 2; // Account for padding and spacing
    
    final dailyEarnings = (driver['daily_earnings'] ?? 0.0) as double;
    final weeklyEarnings = (driver['weekly_earnings'] ?? 0.0) as double;
    final monthlyEarnings = (driver['monthly_earnings'] ?? 0.0) as double;
    final totalEarnings = (driver['total_fare'] ?? 0.0) as double;

    final quotaDaily = (driver['quota_daily'] ?? 0.0) as double;
    final quotaWeekly = (driver['quota_weekly'] ?? 0.0) as double;
    final quotaMonthly = (driver['quota_monthly'] ?? 0.0) as double;
    final quotaTotal = (driver['quota_total'] ?? 0.0) as double;
    
    final List weeklyBookings = breakdown?['weekly_bookings'] ?? [];
    final List monthlyBookings = breakdown?['monthly_bookings'] ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: isDark ? Palette.darkBorder : Palette.lightBorder, width: 1.5),
      ),
      elevation: 8.0,
      backgroundColor: isDark ? Palette.darkCard : Palette.lightCard,
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart, color: isDark ? Palette.darkText : Palette.lightText, size: 28),
                    SizedBox(width: 12.0),
                    Text(
                      "Earnings Report",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Palette.darkText : Palette.lightText,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Palette.darkBorder : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: isDark ? Palette.darkText : Palette.lightText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Divider(color: isDark ? Palette.darkDivider : Palette.lightDivider, thickness: 1.5),
            const SizedBox(height: 16.0),
            
            // Driver information
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Palette.darkSurface : Palette.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Palette.darkBorder : Palette.lightBorder),
              ),
              child: Text(
                "${driver['full_name']} (ID: ${driver['driver_id']})",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Palette.darkText : Palette.lightText,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            
            // Earnings Summary
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isDark ? Palette.darkSurface : Palette.lightSurface,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: isDark ? Palette.darkBorder : Palette.lightBorder),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildEarningsSummary('Daily', dailyEarnings, quotaDaily, isDark),
                  _buildVerticalDivider(isDark),
                  _buildEarningsSummary('Weekly', weeklyEarnings, quotaWeekly, isDark),
                  _buildVerticalDivider(isDark),
                  _buildEarningsSummary('Monthly', monthlyEarnings, quotaMonthly, isDark),
                  _buildVerticalDivider(isDark),
                  _buildEarningsSummary('All Time', totalEarnings, quotaTotal, isDark),
                ],
              ),
            ),
            
            const SizedBox(height: 24.0),
            
            // Bookings lists in two columns
            Expanded(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column - Weekly Bookings
                    SizedBox(
                      width: columnWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("This Week's Bookings", isDark),
                          const SizedBox(height: 8.0),
                          Expanded(
                            child: SingleChildScrollView(
                              child: _buildBookingsList(weeklyBookings, isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Spacing between columns
                    const SizedBox(width: 24.0),
                    
                    // Right column - Monthly Bookings
                    SizedBox(
                      width: columnWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("This Month's Bookings", isDark),
                          const SizedBox(height: 8.0),
                          Expanded(
                            child: SingleChildScrollView(
                              child: _buildBookingsList(monthlyBookings, isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16.0),
            
            // Bottom button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Palette.darkSurface : Palette.lightSurface,
                  foregroundColor: isDark ? Palette.darkText : Palette.lightText,
                  elevation: 4.0,
                  shadowColor: isDark ? Colors.black.withValues(alpha: 0.1) : Colors.grey.shade300,
                  side: BorderSide(color: isDark ? Palette.darkBorder : Palette.lightBorder, width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Close",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      height: 60.0,
      width: 1.0,
      color: isDark ? Palette.darkDivider : Palette.lightDivider,
    );
  }
  
  Widget _buildEarningsSummary(String period, double amount, double target, bool isDark) {
    return Column(
      children: [
        Text(
          period,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: isDark ? Palette.darkText : Palette.lightText,
          ),
        ),
        SizedBox(height: 8.0),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '₱${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: amount > 0 ? Palette.greenColor : (isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
                ),
              ),
              TextSpan(
                text: ' / ',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16.0,
                  color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                ),
              ),
              TextSpan(
                text: '₱${target.toStringAsFixed(0)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Palette.darkText : Palette.lightText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
        color: isDark ? Palette.darkText : Palette.lightText,
      ),
    );
  }
  
  Widget _buildBookingsList(List bookings, bool isDark) {
    
    if (bookings.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? Palette.darkSurface : Palette.lightSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? Palette.darkBorder : Palette.lightBorder),
        ),
        child: Text(
          'No bookings in this period',
          style: TextStyle(
            fontFamily: 'Inter',
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Palette.darkBorder : Palette.lightBorder),
      ),
      child: Column(
        children: bookings.map<Widget>((booking) {
          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: bookings.last != booking 
                  ? BorderSide(color: isDark ? Palette.darkDivider : Palette.lightDivider) 
                  : BorderSide.none,
              ),
            ),
            child: ListTile(
              dense: true,
              title: Text(
                'Date: ${booking['formatted_date']}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: isDark ? Palette.darkText : Palette.lightText,
                ),
              ),
              trailing: Text(
                '₱${booking['fare'].toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Palette.darkText : Palette.lightText,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}