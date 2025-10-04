import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:pasada_admin_application/widgets/responsive_layout.dart';
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
      'name': 'Admin Quotas',
      'icon': Icons.flag,
      'description': 'Configured quota targets per period (global or per-driver)',
      'color': Palette.lightWarning,
    },
    {
      'name': 'Driver Quotas',
      'icon': Icons.stacked_bar_chart,
      'description': 'Per-driver quota aggregates and current progress',
      'color': Palette.lightSuccess,
    },
    {
      'name': 'Allowed Stops',
      'icon': Icons.location_on,
      'description': 'Stops allowed for each official route',
      'color': Palette.lightPrimary,
    },
    {
      'name': 'AI Chat History',
      'icon': Icons.chat_bubble_outline,
      'description': 'Saved AI chat conversations and metadata',
      'color': Palette.lightInfo,
    },
    {
      'name': 'Booking Archives',
      'icon': Icons.inventory_2_outlined,
      'description': 'Archived historical booking records',
      'color': Palette.lightTextSecondary,
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
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Container(
      color: isDark ? Palette.darkSurface : Palette.lightSurface,
      child: ResponsiveLayout(
        minWidth: 900,
        child: ResponsivePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: ResponsiveHelper.getResponsiveAvatarRadius(context),
                    backgroundColor: isDark
                        ? Palette.darkSurface
                        : Palette.lightSurface,
                    child: Icon(
                      Icons.table_chart,
                      color: isDark
                          ? Palette.darkText
                          : Palette.lightText,
                      size: ResponsiveHelper.getResponsiveIconSize(context),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  ResponsiveText(
                    "Select Table",
                    mobileFontSize: 24.0,
                    tabletFontSize: 26.0,
                    desktopFontSize: 28.0,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Palette.darkText : Palette.lightText,
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 24.0),
              Expanded(
                child: ResponsiveGrid(
                  mobileColumns: 1,
                  tabletColumns: 2,
                  desktopColumns: 3,
                  largeDesktopColumns: 4,
                  crossAxisSpacing: isMobile ? 12.0 : 24.0,
                  mainAxisSpacing: isMobile ? 12.0 : 24.0,
                  childAspectRatio: isMobile
                      ? 2.0
                      : (isTablet ? 1.6 : 1.2),
                  children: tableData.map((table) => _buildTableCard(table, isDark)).toList(),
                ),
              ),
            ],
          ),
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
