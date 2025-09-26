import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:provider/provider.dart';

class MyDrawer extends StatefulWidget {
  final String? currentRoute;
  final Function(String, {Map<String, dynamic>? args})? onNavigate;
  final bool isCollapsed;
  final bool isMobile;

  const MyDrawer({
    super.key, 
    this.currentRoute, 
    this.onNavigate,
    this.isCollapsed = false,
    this.isMobile = false,
  });

  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> with TickerProviderStateMixin {
  bool _reportsExpanded = false;
  bool _isCollapsed = false;
  late AnimationController _collapseController;
  late Animation<double> _collapseAnimation;

  @override
  void initState() {
    super.initState();
    // On mobile, never collapse the drawer
    _isCollapsed = widget.isCollapsed && !widget.isMobile;
    _collapseController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _collapseAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _collapseController,
      curve: Curves.easeInOutCubic,
    ));
    
    if (_isCollapsed) {
      _collapseController.forward();
    }
  }

  @override
  void didUpdateWidget(MyDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update collapse state when widget updates
    if (oldWidget.isCollapsed != widget.isCollapsed && !widget.isMobile) {
      setState(() {
        _isCollapsed = widget.isCollapsed;
        if (_isCollapsed) {
          _collapseController.forward();
        } else {
          _collapseController.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _collapseController.dispose();
    super.dispose();
  }

  Widget _createDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required String routeName,
    required String currentRoute,
    bool hideIcon = false,
    EdgeInsetsGeometry? customPadding,
    bool isSubItem = false,
  }) {
    final bool selected = routeName == currentRoute;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSubItem ? 12.0 : 16.0, 
        vertical: (_isCollapsed && !widget.isMobile) ? 8.0 : 4.0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!selected) {
              if (widget.onNavigate != null) {
                widget.onNavigate!(routeName);
              } else {
                Navigator.pushReplacementNamed(context, routeName);
              }
              // Close mobile drawer after navigation
              if (widget.isMobile) {
                Navigator.of(context).pop();
              }
            }
          },
          borderRadius: BorderRadius.circular(12.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            height: (_isCollapsed && !widget.isMobile) ? 48.0 : null,
            padding: (_isCollapsed && !widget.isMobile)
                ? EdgeInsets.zero
                : (customPadding ?? EdgeInsets.symmetric(
                    horizontal: isSubItem ? 16.0 : 16.0, 
                    vertical: 12.0,
                  )),
            decoration: BoxDecoration(
              color: selected 
                  ? (isDark ? Palette.darkPrimary.withValues(alpha: 0.15) : Palette.lightPrimary.withValues(alpha: 0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12.0),
              border: selected 
                  ? Border.all(
                      color: isDark ? Palette.darkPrimary.withValues(alpha: 0.3) : Palette.lightPrimary.withValues(alpha: 0.3),
                      width: 1.0,
                    )
                  : null,
            ),
            child: (_isCollapsed && !widget.isMobile)
                ? Center(
                    child: Icon(
                      icon,
                      size: 20.0,
                      color: selected 
                          ? (isDark ? Palette.darkPrimary : Palette.lightPrimary)
                          : (isDark ? Palette.darkText : Palette.lightText),
                    ),
                  )
                : Row(
                    children: [
                      if (!hideIcon) ...[
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: selected 
                                ? (isDark ? Palette.darkPrimary : Palette.lightPrimary)
                                : (isDark ? Palette.darkSurface : Palette.lightSurface),
                            borderRadius: BorderRadius.circular(8.0),
                            boxShadow: selected 
                                ? [
                                    BoxShadow(
                                      color: (isDark ? Palette.darkPrimary : Palette.lightPrimary).withValues(alpha: 0.3),
                                      blurRadius: 8.0,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            icon,
                            size: 18.0,
                            color: selected 
                                ? Colors.white
                                : (isDark ? Palette.darkText : Palette.lightText),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                      ],
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: _isCollapsed ? 0.0 : 1.0,
                          child: Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: 14.0,
                              color: selected 
                                  ? (isDark ? Palette.darkPrimary : Palette.lightPrimary)
                                  : (isDark ? Palette.darkText : Palette.lightText),
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentRoute = widget.currentRoute ?? ModalRoute.of(context)?.settings.name ?? '';
    final bool reportsSelected =
        currentRoute == '/reports' || currentRoute == '/select_table';
    final bool expanded = reportsSelected ? true : _reportsExpanded;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return AnimatedBuilder(
      animation: _collapseAnimation,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          width: widget.isMobile 
              ? MediaQuery.of(context).size.width * 0.5
              : (_isCollapsed && !widget.isMobile ? 80.0 : 280.0),
          decoration: BoxDecoration(
            color: isDark ? Palette.darkSurface : Palette.lightSurface,
            border: Border(
              right: BorderSide(
                color: isDark ? Palette.darkBorder : Palette.lightBorder,
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
                blurRadius: 10.0,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Section
              Container(
                height: 80.0,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark 
                        ? [Palette.darkPrimary.withValues(alpha: 0.1), Palette.darkSurface]
                        : [Palette.lightPrimary.withValues(alpha: 0.05), Palette.lightSurface],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Palette.darkDivider : Palette.lightDivider,
                      width: 1.0,
                    ),
                  ),
                ),
                child: (_isCollapsed && !widget.isMobile)
                    ? Center(
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _isCollapsed = !_isCollapsed;
                              if (_isCollapsed) {
                                _collapseController.forward();
                              } else {
                                _collapseController.reverse();
                              }
                            });
                          },
                          icon: Icon(
                            Icons.chevron_right,
                            color: isDark ? Palette.darkText : Palette.lightText,
                          ),
                          tooltip: 'Expand sidebar',
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Image.asset(
                              isDark ? 'assets/pasadaLogoUpdated.png' : 'assets/pasadaLogoUpdated_Black.png',
                              height: 48.0,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  'PASADA',
                                  style: TextStyle(
                                    color: isDark ? Palette.darkText : Palette.lightText,
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                );
                              },
                            ),
                          ),
                          if (!widget.isMobile) ...[
                            const SizedBox(width: 8.0),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _isCollapsed = !_isCollapsed;
                                  if (_isCollapsed) {
                                    _collapseController.forward();
                                  } else {
                                    _collapseController.reverse();
                                  }
                                });
                              },
                              icon: Icon(
                                Icons.chevron_left,
                                color: isDark ? Palette.darkText : Palette.lightText,
                              ),
                              tooltip: 'Collapse sidebar',
                            ),
                          ],
                        ],
                      ),
              ),
              
              // Navigation Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  children: <Widget>[
                    // Standard drawer items.
                    _createDrawerItem(
                      context: context,
                      icon: Icons.dashboard_rounded,
                      text: 'Dashboard',
                      routeName: '/dashboard',
                      currentRoute: currentRoute,
                    ),
                    _createDrawerItem(
                      context: context,
                      icon: Icons.local_shipping_rounded,
                      text: 'Fleet',
                      routeName: '/fleet',
                      currentRoute: currentRoute,
                    ),
                    _createDrawerItem(
                      context: context,
                      icon: Icons.person_rounded,
                      text: 'Drivers',
                      routeName: '/drivers',
                      currentRoute: currentRoute,
                    ),
                    // --- Reports Section with dropdown ---
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 16.0, 
                        vertical: (_isCollapsed && !widget.isMobile) ? 8.0 : 4.0,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (!reportsSelected) {
                              setState(() {
                                _reportsExpanded = !_reportsExpanded;
                                // If collapsed and expanding reports, also expand the sidebar
                                if (_isCollapsed && !_reportsExpanded) {
                                  _isCollapsed = false;
                                  _collapseController.reverse();
                                }
                              });
                            }
                            // On mobile, if reports is selected, navigate to reports
                            if (widget.isMobile && reportsSelected) {
                              if (widget.onNavigate != null) {
                                widget.onNavigate!('/reports');
                              } else {
                                Navigator.pushReplacementNamed(context, '/reports');
                              }
                              Navigator.of(context).pop();
                            }
                          },
                          onDoubleTap: () {
                            setState(() {
                              _reportsExpanded = false;
                              // If collapsed, expand the sidebar when double-tapping
                              if (_isCollapsed) {
                                _isCollapsed = false;
                                _collapseController.reverse();
                              }
                            });
                            if (widget.onNavigate != null) {
                              widget.onNavigate!('/reports');
                            } else {
                              Navigator.pushReplacementNamed(context, '/reports');
                            }
                          },
                          borderRadius: BorderRadius.circular(12.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOutCubic,
                            height: (_isCollapsed && !widget.isMobile) ? 48.0 : null,
                            padding: (_isCollapsed && !widget.isMobile)
                                ? EdgeInsets.zero
                                : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            decoration: BoxDecoration(
                              color: reportsSelected 
                                  ? (isDark ? Palette.darkPrimary.withValues(alpha: 0.15) : Palette.lightPrimary.withValues(alpha: 0.1))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12.0),
                              border: reportsSelected 
                                  ? Border.all(
                                      color: isDark ? Palette.darkPrimary.withValues(alpha: 0.3) : Palette.lightPrimary.withValues(alpha: 0.3),
                                      width: 1.0,
                                    )
                                  : null,
                            ),
                            child: (_isCollapsed && !widget.isMobile)
                                ? Center(
                                    child: Icon(
                                      Icons.analytics_rounded,
                                      size: 20.0,
                                      color: reportsSelected 
                                          ? (isDark ? Palette.darkPrimary : Palette.lightPrimary)
                                          : (isDark ? Palette.darkText : Palette.lightText),
                                    ),
                                  )
                                : Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: reportsSelected 
                                              ? (isDark ? Palette.darkPrimary : Palette.lightPrimary)
                                              : (isDark ? Palette.darkSurface : Palette.lightSurface),
                                          borderRadius: BorderRadius.circular(8.0),
                                          boxShadow: reportsSelected 
                                              ? [
                                                  BoxShadow(
                                                    color: (isDark ? Palette.darkPrimary : Palette.lightPrimary).withValues(alpha: 0.3),
                                                    blurRadius: 8.0,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Icon(
                                          Icons.analytics_rounded,
                                          size: 18.0,
                                          color: reportsSelected 
                                              ? Colors.white
                                              : (isDark ? Palette.darkText : Palette.lightText),
                                        ),
                                      ),
                                      const SizedBox(width: 12.0),
                                      Expanded(
                                        child: AnimatedOpacity(
                                          duration: const Duration(milliseconds: 150),
                                          opacity: (_isCollapsed && !widget.isMobile) ? 0.0 : 1.0,
                                          child: Text(
                                            'Reports',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: reportsSelected 
                                                  ? (isDark ? Palette.darkPrimary : Palette.lightPrimary)
                                                  : (isDark ? Palette.darkText : Palette.lightText),
                                              fontWeight: reportsSelected ? FontWeight.w600 : FontWeight.w500,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      AnimatedOpacity(
                                        duration: const Duration(milliseconds: 150),
                                        opacity: (_isCollapsed && !widget.isMobile) ? 0.0 : 1.0,
                                        child: AnimatedRotation(
                                          turns: expanded ? 0.5 : 0.0,
                                          duration: const Duration(milliseconds: 150),
                                          child: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 20.0,
                                            color: isDark ? Palette.darkText : Palette.lightText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    if (expanded && !_isCollapsed)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutCubic,
                        margin: EdgeInsets.only(
                          left: widget.isMobile ? 16.0 : 24.0, 
                          right: 16.0, 
                          top: 8.0
                        ),
                        child: Column(
                          children: [
                            _createDrawerItem(
                              context: context,
                              icon: Icons.dataset_rounded,
                              text: 'Quota',
                              routeName: '/reports',
                              currentRoute: currentRoute,
                              isSubItem: true,
                            ),
                            _createDrawerItem(
                              context: context,
                              icon: Icons.table_chart_rounded,
                              text: 'Tables',
                              routeName: '/select_table',
                              currentRoute: currentRoute,
                              isSubItem: true,
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 8.0),
                    _createDrawerItem(
                      context: context,
                      icon: Icons.psychology_rounded,
                      text: 'AI Assistant',
                      routeName: '/ai_chat',
                      currentRoute: currentRoute,
                    ),
                    if (!_isCollapsed || widget.isMobile) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Divider(
                          color: isDark ? Palette.darkDivider : Palette.lightDivider,
                          thickness: 1.0,
                        ),
                      ),
                    ],
                    _createDrawerItem(
                      context: context,
                      icon: Icons.settings_rounded,
                      text: 'Settings',
                      routeName: '/settings',
                      currentRoute: currentRoute,
                    ),
                  ],
                ),
              ),
              
              // Add spacing when collapsed
              if (_isCollapsed) const SizedBox(height: 16.0),
              
              // Theme toggle at the bottom
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Palette.darkDivider : Palette.lightDivider,
                      width: 1.0,
                    ),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark 
                        ? [Palette.darkSurface, Palette.darkSurface.withValues(alpha: 0.8)]
                        : [Palette.lightSurface, Palette.lightSurface.withValues(alpha: 0.8)],
                  ),
                ),
                child: (_isCollapsed && !widget.isMobile)
                    ? Center(
                        child: GestureDetector(
                          onTap: () {
                            themeProvider.toggleTheme();
                          },
                          child: Container(
                            width: 40.0,
                            height: 40.0,
                            decoration: BoxDecoration(
                              color: isDark ? Palette.darkPrimary.withValues(alpha: 0.1) : Palette.lightPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Center(
                              child: Icon(
                                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                size: 20.0,
                                color: isDark ? Palette.darkPrimary : Palette.lightPrimary,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: isDark ? Palette.darkPrimary.withValues(alpha: 0.1) : Palette.lightPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Icon(
                              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              size: 18.0,
                              color: isDark ? Palette.darkPrimary : Palette.lightPrimary,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: (_isCollapsed && !widget.isMobile) ? 0.0 : 1.0,
                              child: Text(
                                isDark ? 'Dark Mode' : 'Light Mode',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: isDark ? Palette.darkText : Palette.lightText,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 150),
                            opacity: (_isCollapsed && !widget.isMobile) ? 0.0 : 1.0,
                            child: Transform.scale(
                              scale: 0.9,
                              child: Switch(
                                value: isDark,
                                onChanged: (value) {
                                  themeProvider.toggleTheme();
                                },
                                activeColor: Colors.white,
                                activeTrackColor: Palette.lightPrimary,
                                inactiveThumbColor: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                                inactiveTrackColor: isDark ? Palette.darkBorder : Palette.lightBorder,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
