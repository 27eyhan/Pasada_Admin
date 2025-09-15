import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/appbar_search.dart';
import 'package:pasada_admin_application/screen/appbars_&_drawer/drawer.dart';
import 'package:provider/provider.dart';
import 'package:pasada_admin_application/screen/settings_pages/profile_content.dart';
import 'package:pasada_admin_application/screen/settings_pages/notifications_content.dart';
import 'package:pasada_admin_application/screen/settings_pages/updates_content.dart';
import 'package:pasada_admin_application/screen/settings_pages/security_content.dart';

class Settings extends StatefulWidget {
  final int? initialTabIndex;
  
  const Settings({super.key, this.initialTabIndex});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Set initial tab if provided
    if (widget.initialTabIndex != null) {
      _selectedTabIndex = widget.initialTabIndex!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabController.animateTo(_selectedTabIndex);
      });
    }
    
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Method to switch to specific tab
  void switchToTab(int tabIndex) {
    if (tabIndex >= 0 && tabIndex < _tabController.length) {
      _tabController.animateTo(tabIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context)
        .size
        .width
        .clamp(600.0, double.infinity)
        .toDouble();
    final double horizontalPadding = screenWidth * 0.15;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Palette.darkSurface : Palette.lightSurface,
      body: Row(
        children: [
          // Fixed width sidebar drawer
          Container(
            width: 280,
            child: MyDrawer(),
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                // App bar in the main content area
                AppBarSearch(onSettingsTabRequested: switchToTab),
                // Main content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 24.0, 
                      horizontal: horizontalPadding
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Title
                        Text(
                          "Settings",
                          style: TextStyle(
                            fontSize: 26.0,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Palette.darkText : Palette.lightText,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: 32.0),
                        
                        // Tab Navigation
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Palette.darkCard : Palette.lightCard,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: isDark ? Palette.darkBorder : Palette.lightBorder,
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: Palette.greenColor,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: Colors.white,
                            unselectedLabelColor: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                            dividerColor: Colors.transparent,
                            labelStyle: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                            unselectedLabelStyle: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Inter',
                            ),
                            tabs: [
                              Tab(text: "Profile"),
                              Tab(text: "Notifications"),
                              Tab(text: "Real-Time Updates"),
                              Tab(text: "Security"),
                            ],
                          ),
                        ),
                        SizedBox(height: 24.0),
                        
                        // Tab Content - Fixed height container
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildProfileTab(isDark),
                              _buildNotificationsTab(isDark),
                              _buildUpdatesTab(isDark),
                              _buildSecurityTab(isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(bool isDark) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: isDark ? Palette.darkCard : Palette.lightCard,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isDark ? Palette.darkBorder : Palette.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                ? Colors.black.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_circle,
                  size: 28,
                  color: Palette.greenColor,
                ),
                SizedBox(width: 12.0),
                Text(
                  "Profile",
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Palette.darkText : Palette.lightText,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            Text(
              "Manage your account information and preferences",
              style: TextStyle(
                fontSize: 14.0,
                color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 24.0),
            
            // Profile content
            ProfileContent(isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab(bool isDark) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: isDark ? Palette.darkCard : Palette.lightCard,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isDark ? Palette.darkBorder : Palette.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                ? Colors.black.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  size: 28,
                  color: Palette.greenColor,
                ),
                SizedBox(width: 12.0),
                Text(
                  "Notifications",
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Palette.darkText : Palette.lightText,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            Text(
              "Configure your notification preferences and settings",
              style: TextStyle(
                fontSize: 14.0,
                color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 24.0),
            
            // Notifications content
            NotificationsContent(isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdatesTab(bool isDark) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: isDark ? Palette.darkCard : Palette.lightCard,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isDark ? Palette.darkBorder : Palette.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                ? Colors.black.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.update,
                  size: 28,
                  color: Palette.greenColor,
                ),
                SizedBox(width: 12.0),
                Text(
                  "Real-Time Updates",
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Palette.darkText : Palette.lightText,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            Text(
              "Manage real-time update preferences and frequency",
              style: TextStyle(
                fontSize: 14.0,
                color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 24.0),
            
            // Updates content
            UpdatesContent(isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTab(bool isDark) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: isDark ? Palette.darkCard : Palette.lightCard,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isDark ? Palette.darkBorder : Palette.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                ? Colors.black.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  size: 28,
                  color: Palette.greenColor,
                ),
                SizedBox(width: 12.0),
                Text(
                  "Security",
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Palette.darkText : Palette.lightText,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            Text(
              "Manage your account security and privacy settings",
              style: TextStyle(
                fontSize: 14.0,
                color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                fontFamily: 'Inter',
                  ),
            ),
            SizedBox(height: 24.0),
            
            // Security content
            SecurityContent(isDark: isDark),
          ],
        ),
      ),
    );
  }
}
