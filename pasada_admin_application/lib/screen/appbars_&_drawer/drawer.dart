import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

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
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (!selected) {
          Navigator.pushReplacementNamed(context, routeName);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: selected ? Palette.greyColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ListTile(
          contentPadding:
              customPadding ?? const EdgeInsets.symmetric(horizontal: 8.0),
          leading: hideIcon
              ? const SizedBox(width: 0)
              : Icon(
                  icon,
                  color: selected ? Palette.greenColor : Palette.blackColor,
                ),
          title: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Palette.blackColor,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    final bool reportsSelected =
        currentRoute == '/reports' || currentRoute == '/select_table';
    final bool expanded = reportsSelected ? true : _reportsExpanded;

    return Drawer(
      child: Container(
        color: Palette.whiteColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Palette.whiteColor,
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pasada',
                    style: TextStyle(
                      color: Palette.blackColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
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
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/reports');
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color:
                      reportsSelected ? Palette.greyColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  leading: Icon(
                    Icons.bar_chart,
                    color: reportsSelected
                        ? Palette.greenColor
                        : Palette.blackColor,
                  ),
                  title: Text(
                    'Reports',
                    style: TextStyle(
                      fontSize: 16,
                      color: Palette.blackColor,
                      fontWeight:
                          reportsSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Icon(
                    expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: Palette.blackColor,
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
                      customPadding:
                          const EdgeInsets.symmetric(horizontal: 24.0),
                    ),
                    _createDrawerItem(
                      context: context,
                      icon: Icons.table_chart,
                      text: 'Tables',
                      routeName: '/select_table',
                      currentRoute: currentRoute,
                      customPadding:
                          const EdgeInsets.symmetric(horizontal: 24.0),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Divider(
                color: Palette.blackColor,
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
    );
  }
}
