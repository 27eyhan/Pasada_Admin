import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/global_table_screen.dart';
import 'package:provider/provider.dart';

class DataTablesContent extends StatefulWidget {
  final Function(String, {Map<String, dynamic>? args})? onNavigateToPage;
  final Map<String, dynamic>? initialArgs;

  const DataTablesContent({
    super.key, 
    this.onNavigateToPage,
    this.initialArgs,
  });

  @override
  _DataTablesContentState createState() => _DataTablesContentState();
}

class _DataTablesContentState extends State<DataTablesContent> {
  @override
  Widget build(BuildContext context) {
    // Check if we have a specific table to display
    final tableName = widget.initialArgs?['tableName'] as String?;
    
    if (tableName != null) {
      // Display the specific table using GlobalTableScreen
      return GlobalTableScreen(
        tableName: tableName,
        onNavigateToPage: widget.onNavigateToPage,
      );
    }
    
    // Default behavior - show placeholder or redirect to select table
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
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 24.0,
          horizontal: horizontalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark
                      ? Palette.darkSurface
                      : Palette.lightSurface,
                  child: Icon(
                    Icons.table_chart,
                    color: isDark
                        ? Palette.darkText
                        : Palette.lightText,
                  ),
                ),
                const SizedBox(width: 12.0),
                Text(
                  "Data Tables",
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
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_chart,
                      size: 64,
                      color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Select a Table to View",
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Palette.darkText : Palette.lightText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Choose a table from the selection to view its data",
                      style: TextStyle(
                        fontSize: 16.0,
                        color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (widget.onNavigateToPage != null) {
                          widget.onNavigateToPage!('/select_table');
                        }
                      },
                      child: Text('Go to Table Selection'),
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
}
