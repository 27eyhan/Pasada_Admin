import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:pasada_admin_application/widgets/responsive_dialog.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:provider/provider.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';

/// Example implementation showing how to use ResponsiveDialog
/// This demonstrates the responsive layout patterns for dialogs
class ResponsiveDialogExample extends StatelessWidget {
  const ResponsiveDialogExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Responsive Dialog Examples'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _showEarningsReportDialog(context),
              child: const Text('Show Earnings Report Dialog'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showDriverInfoDialog(context),
              child: const Text('Show Driver Info Dialog'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showFleetDetailsDialog(context),
              child: const Text('Show Fleet Details Dialog'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEarningsReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: "Earnings Report",
        titleIcon: Icons.bar_chart,
        child: ResponsiveDialogContent(
          children: [
            _buildExampleContent(context, "Earnings Report Content"),
            const SizedBox(height: 16),
            _buildExampleDataGrid(context),
          ],
        ),
      ),
    );
  }

  void _showDriverInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: "Driver Information",
        titleIcon: Icons.person,
        child: ResponsiveDialogContent(
          children: [
            _buildExampleContent(context, "Driver Information Content"),
            const SizedBox(height: 16),
            _buildExampleForm(context),
          ],
        ),
      ),
    );
  }

  void _showFleetDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: "Fleet Details",
        titleIcon: Icons.directions_bus,
        child: ResponsiveDialogContent(
          children: [
            _buildExampleContent(context, "Fleet Details Content"),
            const SizedBox(height: 16),
            _buildExampleCards(context),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleContent(BuildContext context, String title) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveCardPadding(context)),
      decoration: BoxDecoration(
        color: isDark ? Palette.darkSurface : Palette.lightSurface,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context)),
        border: Border.all(
          color: isDark ? Palette.darkBorder : Palette.lightBorder,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSize(
            context,
            mobile: 16,
            tablet: 18,
            desktop: 20,
          ),
          fontWeight: FontWeight.bold,
          color: isDark ? Palette.darkText : Palette.lightText,
        ),
      ),
    );
  }

  Widget _buildExampleDataGrid(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveCardPadding(context)),
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context)),
        border: Border.all(
          color: isDark ? Palette.darkBorder : Palette.lightBorder,
        ),
      ),
      child: ResponsiveHelper.isMobile(context)
          ? _buildMobileDataGrid(isDark)
          : _buildDesktopDataGrid(isDark),
    );
  }

  Widget _buildMobileDataGrid(bool isDark) {
    return Column(
      children: [
        _buildDataRow("Daily Earnings", "₱1,250.00", isDark),
        const SizedBox(height: 8),
        _buildDataRow("Weekly Earnings", "₱8,750.00", isDark),
        const SizedBox(height: 8),
        _buildDataRow("Monthly Earnings", "₱35,000.00", isDark),
      ],
    );
  }

  Widget _buildDesktopDataGrid(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildDataColumn("Daily", "₱1,250.00", isDark),
        _buildDataColumn("Weekly", "₱8,750.00", isDark),
        _buildDataColumn("Monthly", "₱35,000.00", isDark),
      ],
    );
  }

  Widget _buildDataRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Palette.darkText : Palette.lightText,
          ),
        ),
      ],
    );
  }

  Widget _buildDataColumn(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Palette.darkText : Palette.lightText,
          ),
        ),
      ],
    );
  }

  Widget _buildExampleForm(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveCardPadding(context)),
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context)),
        border: Border.all(
          color: isDark ? Palette.darkBorder : Palette.lightBorder,
        ),
      ),
      child: ResponsiveHelper.isMobile(context)
          ? _buildMobileForm(isDark)
          : _buildDesktopForm(isDark),
    );
  }

  Widget _buildMobileForm(bool isDark) {
    return Column(
      children: [
        _buildFormField("Name", "John Doe", isDark),
        const SizedBox(height: 12),
        _buildFormField("Email", "john@example.com", isDark),
        const SizedBox(height: 12),
        _buildFormField("Phone", "+1234567890", isDark),
      ],
    );
  }

  Widget _buildDesktopForm(bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildFormField("Name", "John Doe", isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildFormField("Email", "john@example.com", isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildFormField("Phone", "+1234567890", isDark)),
      ],
    );
  }

  Widget _buildFormField(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Palette.darkText : Palette.lightText,
          ),
        ),
      ],
    );
  }

  Widget _buildExampleCards(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return ResponsiveHelper.isMobile(context)
        ? _buildMobileCards(isDark)
        : _buildDesktopCards(isDark);
  }

  Widget _buildMobileCards(bool isDark) {
    return Column(
      children: [
        _buildInfoCard("Vehicle Info", "Plate: ABC-123", isDark),
        const SizedBox(height: 12),
        _buildInfoCard("Driver Info", "John Doe", isDark),
      ],
    );
  }

  Widget _buildDesktopCards(bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildInfoCard("Vehicle Info", "Plate: ABC-123", isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildInfoCard("Driver Info", "John Doe", isDark)),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, bool isDark) {
    return Builder(
      builder: (context) => Container(
        padding: EdgeInsets.all(ResponsiveHelper.getResponsiveCardPadding(context)),
        decoration: BoxDecoration(
          color: isDark ? Palette.darkCard : Palette.lightCard,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context)),
          border: Border.all(
            color: isDark ? Palette.darkBorder : Palette.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Palette.darkText : Palette.lightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Palette.darkText : Palette.lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
