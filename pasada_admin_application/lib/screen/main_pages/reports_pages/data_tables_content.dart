import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:provider/provider.dart';

class DataTablesContent extends StatefulWidget {
  final Function(String, {Map<String, dynamic>? args})? onNavigateToPage;

  const DataTablesContent({super.key, this.onNavigateToPage});

  @override
  _DataTablesContentState createState() => _DataTablesContentState();
}

class _DataTablesContentState extends State<DataTablesContent> {
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
                child: Text(
                  "Data Tables content will be implemented here",
                  style: TextStyle(
                    fontSize: 16.0,
                    color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
