import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/table_navigation_helper.dart';
import 'package:provider/provider.dart';

class GlobalTableScreen extends StatefulWidget {
  final String tableName;
  final Function(String, {Map<String, dynamic>? args})? onNavigateToPage;

  const GlobalTableScreen({
    super.key,
    required this.tableName,
    this.onNavigateToPage,
  });

  @override
  _GlobalTableScreenState createState() => _GlobalTableScreenState();
}

class _GlobalTableScreenState extends State<GlobalTableScreen> {
  @override
  Widget build(BuildContext context) {
    // Get the table widget using the centralized system
    final tableWidget = TableNavigationHelper.getTableWidget(widget.tableName);

    // If table widget exists, return it directly (TablePreviewWidget handles its own layout)
    if (tableWidget != null) {
      return tableWidget;
    }

    // Fallback for tables not found
    return _buildTableNotFound();
  }

  // Build widget when table is not found
  Widget _buildTableNotFound() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Palette.darkSurface : Palette.lightSurface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Table Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Palette.darkText : Palette.lightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The requested table "${widget.tableName}" could not be found.',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (widget.onNavigateToPage != null) {
                  widget.onNavigateToPage!('/select_table');
                }
              },
              child: Text('Go Back to Table Selection'),
            ),
          ],
        ),
      ),
    );
  }
}
