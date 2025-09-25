import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/widgets/responsive_layout.dart';
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

    return Container(
      color: isDark ? Palette.darkSurface : Palette.lightSurface,
      child: ResponsiveLayout(
        minWidth: 900,
        child: ResponsivePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add placeholder content here if needed
              Center(
                child: Text(
                  'Select a table to view data',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: isDark ? Palette.darkText : Palette.lightText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
