import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:provider/provider.dart';

class MyDrawer extends StatefulWidget {
  final String? currentRoute;
  final Function(String, {Map<String, dynamic>? args})? onNavigate;

  const MyDrawer({super.key, this.currentRoute, this.onNavigate});

  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  bool _reportsExpanded = false;

  Widget _createDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required String routeName,
    required String currentRoute,
    bool hideIcon = false,
    EdgeInsetsGeometry? customPadding,
  }) {
    final bool selected = routeName == currentRoute;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return InkWell(
      onTap: () {
        if (!selected) {
          if (widget.onNavigate != null) {
            widget.onNavigate!(routeName);
          } else {
            Navigator.pushReplacementNamed(context, routeName);
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
        decoration: BoxDecoration(
          color: selected 
              ? (isDark ? Palette.darkBorder : Palette.lightBorder)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: ListTile(
          contentPadding:
              customPadding ?? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          leading: hideIcon
              ? const SizedBox(width: 0)
              : Icon(
                  icon,
                  size: 18.0,
                  color: isDark ? Palette.darkText : Palette.lightText,
                ),
          title: Text(
            text,
            style: TextStyle(
              fontSize: 14.0,
              color: isDark ? Palette.darkText : Palette.lightText,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Palette.darkSurface : Palette.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? Palette.darkBorder : Palette.lightBorder,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                Container(
                  height: 55.0, 
                  color: isDark ? Palette.darkSurface : Palette.lightSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      isDark ? 'assets/pasadaLogoUpdated.png' : 'assets/pasadaLogoUpdated_Black.png',
                      height: 42.0,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          'PASADA',
                          style: TextStyle(
                            color: isDark ? Palette.darkText : Palette.lightText,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                // Standard drawer items.
                _createDrawerItem(
                  context: context,
                  icon: Icons.dashboard,
                  text: 'Dashboard',
                  routeName: '/dashboard',
                  currentRoute: currentRoute,
                ),
                _createDrawerItem(
                  context: context,
                  icon: Icons.local_shipping,
                  text: 'Fleet',
                  routeName: '/fleet',
                  currentRoute: currentRoute,
                ),
                _createDrawerItem(
                  context: context,
                  icon: Icons.person,
                  text: 'Drivers',
                  routeName: '/drivers',
                  currentRoute: currentRoute,
                ),
                // --- Reports ListTile with dropdown ---
                GestureDetector(
                  onTap: () {
                    // Only allow toggling if no Reports route is selected.
                    if (!reportsSelected) {
                      setState(() {
                        _reportsExpanded = !_reportsExpanded;
                      });
                    }
                  },
                  onDoubleTap: () {
                    // Double tap immediately navigates to the default '/reports' (Quota).
                    setState(() {
                      _reportsExpanded = false;
                    });
                    if (widget.onNavigate != null) {
                      widget.onNavigate!('/reports');
                    } else {
                      Navigator.pushReplacementNamed(context, '/reports');
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.0),
                    decoration: BoxDecoration(
                      color: reportsSelected 
                          ? (isDark ? Palette.darkBorder : Palette.lightBorder)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      leading: Icon(
                        Icons.bar_chart,
                        size: 18.0,
                        color: isDark ? Palette.darkText : Palette.lightText,
                      ),
                      title: Text(
                        'Reports',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: isDark ? Palette.darkText : Palette.lightText,
                          fontWeight: reportsSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: Icon(
                        expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        size: 18.0,
                        color: isDark ? Palette.darkText : Palette.lightText,
                      ),
                    ),
                  ),
                ),
                if (expanded)
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0),
                    child: Column(
                      children: [
                        _createDrawerItem(
                          context: context,
                          icon: Icons.dataset,
                          text: 'Quota',
                          routeName: '/reports',
                          currentRoute: currentRoute,
                          customPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
                        ),
                        _createDrawerItem(
                          context: context,
                          icon: Icons.table_chart,
                          text: 'Tables',
                          routeName: '/select_table',
                          currentRoute: currentRoute,
                          customPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
                        ),
                      ],
                    ),
                  ),
                _createDrawerItem(
                  context: context,
                  icon: Icons.assistant,
                  text: 'AI Assistant',
                  routeName: '/ai_chat',
                  currentRoute: currentRoute,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Divider(
                    color: isDark ? Palette.darkDivider : Palette.lightDivider,
                    thickness: 1.0,
                  ),
                ),
                _createDrawerItem(
                  context: context,
                  icon: Icons.settings,
                  text: 'Settings',
                  routeName: '/settings',
                  currentRoute: currentRoute,
                ),
              ],
            ),
          ),
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
            ),
            child: Row(
              children: [
                                 Icon(
                   isDark ? Icons.dark_mode : Icons.light_mode,
                   size: 16.0,
                   color: isDark ? Palette.darkText : Palette.lightText,
                 ),
                const SizedBox(width: 12.0),
                Expanded(
                                     child: Text(
                     isDark ? 'Dark Mode' : 'Light Mode',
                     style: TextStyle(
                       fontSize: 14.0,
                       color: isDark ? Palette.darkText : Palette.lightText,
                       fontWeight: FontWeight.w500,
                     ),
                   ),
                ),
                                 Transform.scale(
                   scale: 0.8,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
