import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:provider/provider.dart';

class SelectTableContent extends StatefulWidget {
  final Function(String, {Map<String, dynamic>? args})? onNavigateToPage;

  const SelectTableContent({super.key, this.onNavigateToPage});

  @override
  _SelectTableContentState createState() => _SelectTableContentState();
}

class _SelectTableContentState extends State<SelectTableContent> {
  // Static list of table names with icons and descriptions
  final List<Map<String, dynamic>> tableData = [
    {
      'name': 'Admin',
      'icon': Icons.admin_panel_settings,
      'description': 'Administrator accounts and permissions',
      'color': Palette.lightPrimary,
    },
    {
      'name': 'Passenger',
      'icon': Icons.person,
      'description': 'Passenger information and profiles',
      'color': Palette.lightInfo,
    },
    {
      'name': 'Driver',
      'icon': Icons.person_outline,
      'description': 'Driver accounts and vehicle assignments',
      'color': Palette.lightSuccess,
    },
    {
      'name': 'Vehicle',
      'icon': Icons.directions_bus,
      'description': 'Fleet vehicles and specifications',
      'color': Palette.lightSecondary,
    },
    {
      'name': 'Route',
      'icon': Icons.route,
      'description': 'Transportation routes and stops',
      'color': Palette.lightPrimary,
    },
    {
      'name': 'Bookings',
      'icon': Icons.book_online,
      'description': 'Passenger booking records and history',
      'color': Palette.lightInfo,
    },
    {
      'name': 'Driver Archives',
      'icon': Icons.archive,
      'description': 'Historical driver data and records',
      'color': Palette.lightTextSecondary,
    },
    {
      'name': 'Admin Archives',
      'icon': Icons.archive,
      'description': 'Historical admin data and records',
      'color': Palette.lightTextSecondary,
    },
  ];

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
                  "Select Table",
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
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 24.0,
                  mainAxisSpacing: 24.0,
                  childAspectRatio: 1.2,
                ),
                itemCount: tableData.length,
                itemBuilder: (context, index) {
                  final table = tableData[index];
                  return _buildTableCard(table, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCard(Map<String, dynamic> table, bool isDark) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {
          // Navigate to the specific table view
          if (widget.onNavigateToPage != null) {
            widget.onNavigateToPage!('/data_tables', args: {'tableName': table['name']});
          }
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: table['color'].withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  table['icon'],
                  size: 32.0,
                  color: table['color'],
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                table['name'],
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Palette.darkText : Palette.lightText,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              Text(
                table['description'],
                style: TextStyle(
                  fontSize: 12.0,
                  color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
