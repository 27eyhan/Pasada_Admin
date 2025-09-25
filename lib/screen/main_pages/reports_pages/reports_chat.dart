import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:pasada_admin_application/widgets/responsive_dialog.dart';
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

    return ResponsiveDialog(
      title: "Earnings Report",
      titleIcon: Icons.bar_chart,
      child: ResponsiveDialogContent(
        children: [
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
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 16),
                fontWeight: FontWeight.w600,
                color: isDark ? Palette.darkText : Palette.lightText,
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
          
          // Earnings Summary
          Container(
            padding: EdgeInsets.all(ResponsiveHelper.getResponsiveCardPadding(context)),
            decoration: BoxDecoration(
              color: isDark ? Palette.darkSurface : Palette.lightSurface,
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context)),
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
            child: ResponsiveHelper.isMobile(context)
                ? _buildMobileEarningsSummary(dailyEarnings, weeklyEarnings, monthlyEarnings, totalEarnings, quotaDaily, quotaWeekly, quotaMonthly, quotaTotal, isDark)
                : _buildDesktopEarningsSummary(dailyEarnings, weeklyEarnings, monthlyEarnings, totalEarnings, quotaDaily, quotaWeekly, quotaMonthly, quotaTotal, isDark),
          ),
          
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
          
          // Bookings lists
          ResponsiveHelper.isMobile(context)
              ? _buildMobileBookingsLayout(weeklyBookings, monthlyBookings, isDark)
              : _buildDesktopBookingsLayout(weeklyBookings, monthlyBookings, isDark),
        ],
      ),
    );
  }

  // Mobile earnings summary layout
  Widget _buildMobileEarningsSummary(double dailyEarnings, double weeklyEarnings, double monthlyEarnings, double totalEarnings, double quotaDaily, double quotaWeekly, double quotaMonthly, double quotaTotal, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildEarningsSummary('Daily', dailyEarnings, quotaDaily, isDark)),
            SizedBox(width: 8),
            Expanded(child: _buildEarningsSummary('Weekly', weeklyEarnings, quotaWeekly, isDark)),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildEarningsSummary('Monthly', monthlyEarnings, quotaMonthly, isDark)),
            SizedBox(width: 8),
            Expanded(child: _buildEarningsSummary('All Time', totalEarnings, quotaTotal, isDark)),
          ],
        ),
      ],
    );
  }

  // Desktop earnings summary layout
  Widget _buildDesktopEarningsSummary(double dailyEarnings, double weeklyEarnings, double monthlyEarnings, double totalEarnings, double quotaDaily, double quotaWeekly, double quotaMonthly, double quotaTotal, bool isDark) {
    return Row(
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
    );
  }

  // Mobile bookings layout
  Widget _buildMobileBookingsLayout(List weeklyBookings, List monthlyBookings, bool isDark) {
    return Column(
      children: [
        _buildSectionHeader("This Week's Bookings", isDark),
        SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            child: _buildBookingsList(weeklyBookings, isDark),
          ),
        ),
        SizedBox(height: 16),
        _buildSectionHeader("This Month's Bookings", isDark),
        SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            child: _buildBookingsList(monthlyBookings, isDark),
          ),
        ),
      ],
    );
  }

  // Desktop bookings layout
  Widget _buildDesktopBookingsLayout(List weeklyBookings, List monthlyBookings, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("This Week's Bookings", isDark),
              SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildBookingsList(weeklyBookings, isDark),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("This Month's Bookings", isDark),
              SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildBookingsList(monthlyBookings, isDark),
                ),
              ),
            ],
          ),
        ),
      ],
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