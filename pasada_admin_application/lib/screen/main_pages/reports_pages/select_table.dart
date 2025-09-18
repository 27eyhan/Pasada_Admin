import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:pasada_admin_application/widgets/table_preview_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

class SelectTable extends StatefulWidget {
  const SelectTable({super.key});

  @override
  _SelectTableState createState() => _SelectTableState();
}

class _SelectTableState extends State<SelectTable> {
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
      'name': 'Driver Reviews',
      'icon': Icons.star_rate,
      'description': 'Driver ratings and customer feedback',
      'color': Palette.lightWarning,
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
      'description': 'Ride bookings and transaction history',
      'color': Palette.lightInfo,
    },
    {
      'name': 'Driver Archives',
      'icon': Icons.archive,
      'description': 'Historical driver data and records',
      'color': Palette.lightTextSecondary,
    },
  ];

  // View mode: grid or list
  bool isGridView = true;

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
    
    return Scaffold(
      backgroundColor: isDark ? Palette.darkSurface : Palette.lightSurface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          const double minBodyWidth = 900;
          final double effectiveWidth = constraints.maxWidth < minBodyWidth
              ? minBodyWidth
              : constraints.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: minBodyWidth),
              child: SizedBox(
                width: effectiveWidth,
                child: Row(
        children: [
          // Fixed width sidebar drawer
          SizedBox(
            width: 280, // Fixed width for the sidebar
            child: MyDrawer(),
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                // App bar in the main content area
                AppBarSearch(),
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 24.0,
                                  horizontal: horizontalPadding,
                                ),
                      child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header section
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
                                          "Database Tables",
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

                                    // Stats container
                                    Container(
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
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _buildCompactMetric(
                                              'Total Tables',
                                              tableData.length,
                                              isDark ? Palette.darkText : Palette.lightText,
                                            ),
                                          ),
                                          _buildVerticalSeparator(isDark),
                                          Expanded(
                                            child: _buildCompactMetric(
                                              'Active Tables',
                                              tableData.length,
                                              Palette.lightSuccess,
                                            ),
                                          ),
                                          _buildVerticalSeparator(isDark),
                                          Expanded(
                                            child: _buildCompactMetric(
                                              'Archived Tables',
                                              1,
                                              isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24.0),

                                    // View toggle buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: isDark ? Palette.darkCard : Palette.lightCard,
                                            border: Border.all(
                                              color: isDark ? Palette.darkBorder : Palette.lightBorder,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.grid_view,
                                                  size: 18,
                                                  color: isGridView
                                                      ? (isDark ? Palette.darkText : Palette.lightText)
                                                      : (isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    isGridView = true;
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.view_list,
                                                  size: 18,
                                                  color: !isGridView
                                                      ? (isDark ? Palette.darkText : Palette.lightText)
                                                      : (isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    isGridView = false;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16.0),

                                    // Table list with conditional rendering based on view mode
                                    isGridView ? _buildGridView() : _buildListView(),
                                  ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Grid view implementation
  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth >= 1200) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 800) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24.0,
            mainAxisSpacing: 24.0,
            childAspectRatio: 1.4,
          ),
          itemCount: tableData.length,
          itemBuilder: (context, index) {
            final table = tableData[index];
            return _buildTableCard(table);
          },
        );
      },
    );
  }

  // List view implementation
  Widget _buildListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tableData.length,
      itemBuilder: (context, index) {
        final table = tableData[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildTableListItem(table),
        );
      },
    );
  }

  // Table card for grid view
  Widget _buildTableCard(Map<String, dynamic> table) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final String tableName = table['name'];
    final IconData icon = table['icon'];
    final String description = table['description'];
    final Color color = table['color'];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => _navigateToTable(tableName),
        borderRadius: BorderRadius.circular(15.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Palette.darkCard : Palette.lightCard,
            border: Border.all(
                color: isDark 
                    ? Palette.darkBorder.withValues(alpha: 77)
                    : Palette.lightBorder.withValues(alpha: 77), 
                width: 1.0),
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.05),
                spreadRadius: 1,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with colored background
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 16.0),
              
              // Table name
              Text(
                tableName,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Palette.darkText : Palette.lightText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8.0),
              
              // Description
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.0,
                  color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12.0),
              
              // Arrow indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // List item for the list view
  Widget _buildTableListItem(Map<String, dynamic> table) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final String tableName = table['name'];
    final IconData icon = table['icon'];
    final String description = table['description'];
    final Color color = table['color'];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => _navigateToTable(tableName),
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Palette.darkCard : Palette.lightCard,
            border: Border.all(
                color: isDark 
                    ? Palette.darkBorder.withValues(alpha: 77)
                    : Palette.lightBorder.withValues(alpha: 77), 
                width: 1.0),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.05),
                spreadRadius: 1,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          child: Row(
            children: [
              // Icon with colored background
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(width: 16.0),
              
              // Table info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tableName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Palette.darkText : Palette.lightText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.0,
                        color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Arrow indicator
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation method
  void _navigateToTable(String tableName) {
    final supabase = Supabase.instance.client;
    
    switch (tableName) {
      case 'Admin':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TablePreviewHelper.createAdminTable(
              dataFetcher: () async {
                final data = await supabase.from('adminTable').select('*');
                return (data as List).cast<Map<String, dynamic>>();
              },
            ),
          ),
        );
        break;
      case 'Driver':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TablePreviewHelper.createDriverTable(
              dataFetcher: () async {
                final data = await supabase.from('driverTable').select('*');
                return (data as List).cast<Map<String, dynamic>>();
              },
            ),
          ),
        );
        break;
      case 'Passenger':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TablePreviewHelper.createPassengerTable(
              dataFetcher: () async {
                final data = await supabase.from('passenger').select('*');
                return (data as List).cast<Map<String, dynamic>>();
              },
            ),
          ),
        );
        break;
      case 'Driver Reviews':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TablePreviewHelper.createDriverReviewsTable(
              dataFetcher: () async {
                final data = await supabase.from('driverReviews').select('*');
                return (data as List).cast<Map<String, dynamic>>();
              },
            ),
          ),
        );
        break;
      case 'Vehicle':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TablePreviewHelper.createVehicleTable(
              dataFetcher: () async {
                final data = await supabase.from('vehicleTable').select('*');
                return (data as List).cast<Map<String, dynamic>>();
              },
            ),
          ),
        );
        break;
      case 'Route':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TablePreviewHelper.createRouteTable(
              dataFetcher: () async {
                final data = await supabase.from('official_routes').select('*');
                return (data as List).cast<Map<String, dynamic>>();
              },
            ),
          ),
        );
        break;
      case 'Bookings':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TablePreviewHelper.createBookingsTable(
              dataFetcher: () async {
                final data = await supabase.from('bookings').select('*');
                return (data as List).cast<Map<String, dynamic>>();
              },
            ),
          ),
        );
        break;
      case 'Driver Archives':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TablePreviewHelper.createDriverArchivesTable(
              dataFetcher: () async {
                final data = await supabase.from('driverArchives').select('*');
                return (data as List).cast<Map<String, dynamic>>();
              },
            ),
          ),
        );
        break;
      default:
        Navigator.pushNamed(context, '/data_tables', arguments: tableName);
        break;
    }
  }

  // Compact metric item: uppercase label above value (consistent with other pages)
  Widget _buildCompactMetric(String label, int value, Color valueColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.0,
            letterSpacing: 0.6,
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
          value.toString(),
                style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22.0,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // Vertical separator for status metrics
  Widget _buildVerticalSeparator(bool isDark) {
    return Container(
      height: 40.0,
      width: 1.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: isDark ? Palette.darkDivider : Palette.lightDivider,
        borderRadius: BorderRadius.circular(0.5),
      ),
    );
  }
}
