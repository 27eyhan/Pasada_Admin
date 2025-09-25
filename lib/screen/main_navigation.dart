import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:pasada_admin_application/screen/main_pages/dashboard_pages/dashboard_content.dart';
import 'package:pasada_admin_application/screen/main_pages/fleet_pages/fleet_content.dart';
import 'package:pasada_admin_application/screen/main_pages/drivers_pages/drivers_content.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/reports_content.dart';
import 'package:pasada_admin_application/screen/main_pages/ai_chat_content.dart';
import 'package:pasada_admin_application/screen/settings_pages/settings_content.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/data_tables_content.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/select_table_content.dart';
import 'package:provider/provider.dart';

class MainNavigation extends StatefulWidget {
  final String initialPage;
  final Map<String, dynamic>? initialArgs;

  const MainNavigation({
    super.key,
    this.initialPage = '/dashboard',
    this.initialArgs,
  });

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  String _currentPage = '/dashboard';
  Map<String, dynamic>? _currentArgs;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Navigation methods
  void navigateToPage(String pageName, {Map<String, dynamic>? args}) {
    setState(() {
      _currentPage = pageName;
      _currentArgs = args;
    });
  }

  // Get current page content
  Widget _getCurrentPageContent() {
    switch (_currentPage) {
      case '/dashboard':
        return DashboardContent(
          driverLocationArgs: _currentArgs,
          onNavigateToPage: navigateToPage,
        );
      case '/fleet':
        return FleetContent(onNavigateToPage: navigateToPage);
      case '/drivers':
        return DriversContent(onNavigateToPage: navigateToPage);
      case '/reports':
        return ReportsContent(onNavigateToPage: navigateToPage);
      case '/ai_chat':
        return AiChatContent(onNavigateToPage: navigateToPage);
      case '/settings':
        return SettingsContent(
          initialTabIndex: _currentArgs?['tabIndex'],
          onNavigateToPage: navigateToPage,
        );
      case '/data_tables':
        return DataTablesContent(
          onNavigateToPage: navigateToPage,
          initialArgs: _currentArgs,
        );
      case '/select_table':
        return SelectTableContent(onNavigateToPage: navigateToPage);
      default:
        return DashboardContent(
          driverLocationArgs: _currentArgs,
          onNavigateToPage: navigateToPage,
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _currentArgs = widget.initialArgs;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? Palette.darkBackground : Palette.lightBackground,
      body: Row(
        children: [
          // Responsive sidebar drawer
          if (!isMobile) ...[
            MyDrawer(
              currentRoute: _currentPage,
              onNavigate: navigateToPage,
              isCollapsed: isTablet,
            ),
          ],
          // Main content area
          Expanded(
            child: Column(
              children: [
                // App bar in the main content area
                AppBarSearch(
                  onFilterPressed: () {
                    // Handle filter based on current page
                    if (_currentPage == '/dashboard') {
                      // Dashboard filter logic
                    } else if (_currentPage == '/fleet') {
                      // Fleet filter logic
                    } else if (_currentPage == '/drivers') {
                      // Drivers filter logic
                    }
                  },
                  onSettingsTabRequested: (tabIndex) {
                    navigateToPage('/settings', args: {'tabIndex': tabIndex});
                  },
                  showMobileMenu: isMobile,
                  onMobileMenuPressed: () {
                    _showMobileDrawer(context);
                  },
                ),
                // Page content
                Expanded(
                  child: _getCurrentPageContent(),
                ),
              ],
            ),
          ),
        ],
      ),
      // Mobile drawer
      drawer: isMobile ? MyDrawer(
        currentRoute: _currentPage,
        onNavigate: navigateToPage,
        isMobile: true,
      ) : null,
    );
  }

  void _showMobileDrawer(BuildContext context) {
    if (_scaffoldKey.currentState != null) {
      _scaffoldKey.currentState!.openDrawer();
    }
  }
}
