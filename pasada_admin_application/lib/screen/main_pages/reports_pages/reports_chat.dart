import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';

class EarningsBreakdownDialog extends StatelessWidget {
  final Map<String, dynamic> driver;
  final Map<String, dynamic>? breakdown;
  
  const EarningsBreakdownDialog({
    Key? key,
    required this.driver,
    this.breakdown,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width * 0.65;
    final double dialogWidth = screenWidth * 0.6;
    final double dialogHeight = screenWidth * 0.75;
    
    // Calculate column widths
    final double columnWidth = (dialogWidth - 80) / 2; // Account for padding and spacing
    
    final weeklyEarnings = driver['weekly_earnings'] ?? 0.0;
    final monthlyEarnings = driver['monthly_earnings'] ?? 0.0;
    final totalEarnings = driver['total_fare'] ?? 0.0;
    
    final List weeklyBookings = breakdown?['weekly_bookings'] ?? [];
    final List monthlyBookings = breakdown?['monthly_bookings'] ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Palette.blackColor.withAlpha(100), width: 1.5),
      ),
      elevation: 8.0,
      backgroundColor: Palette.whiteColor,
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
                    Icon(Icons.bar_chart, color: Palette.blackColor, size: 28),
                    SizedBox(width: 12.0),
                    Text(
                      "Earnings Report",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Palette.blackColor,
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
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: Palette.blackColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Divider(color: Palette.blackColor.withAlpha(50), thickness: 1.5),
            const SizedBox(height: 16.0),
            
            // Driver information
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Palette.blackColor.withAlpha(10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Palette.blackColor.withAlpha(50)),
              ),
              child: Text(
                "${driver['full_name']} (ID: ${driver['driver_id']})",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Palette.blackColor,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            
            // Earnings Summary
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(30),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildEarningsSummary('Weekly', weeklyEarnings),
                  _buildVerticalDivider(),
                  _buildEarningsSummary('Monthly', monthlyEarnings),
                  _buildVerticalDivider(),
                  _buildEarningsSummary('All Time', totalEarnings),
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
                    Container(
                      width: columnWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("This Week's Bookings"),
                          const SizedBox(height: 8.0),
                          Expanded(
                            child: SingleChildScrollView(
                              child: _buildBookingsList(weeklyBookings),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Spacing between columns
                    const SizedBox(width: 24.0),
                    
                    // Right column - Monthly Bookings
                    Container(
                      width: columnWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("This Month's Bookings"),
                          const SizedBox(height: 8.0),
                          Expanded(
                            child: SingleChildScrollView(
                              child: _buildBookingsList(monthlyBookings),
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
                  backgroundColor: Palette.whiteColor,
                  foregroundColor: Palette.blackColor,
                  elevation: 4.0,
                  shadowColor: Colors.grey.shade300,
                  side: BorderSide(color: Colors.grey.shade400, width: 1.0),
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
  
  Widget _buildVerticalDivider() {
    return Container(
      height: 60.0,
      width: 1.0,
      color: Colors.grey[300],
    );
  }
  
  Widget _buildEarningsSummary(String period, double amount) {
    return Column(
      children: [
        Text(
          period,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Palette.blackColor,
          ),
        ),
        SizedBox(height: 8.0),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: amount > 0 ? Palette.greenColor : Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
        color: Palette.blackColor,
      ),
    );
  }
  
  Widget _buildBookingsList(List bookings) {
    if (bookings.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Text(
          'No bookings in this period',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: bookings.map<Widget>((booking) {
          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: bookings.last != booking 
                  ? BorderSide(color: Colors.grey[200]!) 
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
                ),
              ),
              trailing: Text(
                '₱${booking['fare'].toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}