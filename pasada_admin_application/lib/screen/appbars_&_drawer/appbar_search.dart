import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/services/auth_service.dart';
import 'package:provider/provider.dart';

typedef FilterCallback = void Function();
typedef SettingsTabCallback = void Function(int tabIndex);

class AppBarSearch extends StatefulWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;
  final FilterCallback? onFilterPressed;
  final SettingsTabCallback? onSettingsTabRequested;

  const AppBarSearch({
    super.key, 
    this.onFilterPressed,
    this.onSettingsTabRequested,
  }) : preferredSize = const Size.fromHeight(55.0);

  @override
  _AppBarSearchState createState() => _AppBarSearchState();
}

class _AppBarSearchState extends State<AppBarSearch> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return PreferredSize(
      preferredSize: widget.preferredSize,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Palette.darkSurface : Palette.lightSurface,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Palette.darkBorder : Palette.lightBorder,
              width: 1.0,
            ),
          ),
        ),
        padding: const EdgeInsets.only(
            top: 8.0, left: 8.0, bottom: 8.0, right: 26.0),
        child: Row(
          children: [
            const Spacer(),
            // Filter button removed
            // Profile button styled like "Docs" link
            TextButton(
              onPressed: () {
                _showProfileMenu(context);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                foregroundColor: isDark ? Palette.darkText : Palette.lightText,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_circle, size: 18.0, color: isDark ? Palette.darkText : Palette.lightText),
                  const SizedBox(width: 6.0),
                  Text(
                    'Profile',
                    style: TextStyle(
                      color: isDark ? Palette.darkText : Palette.lightText,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 220,
        55,
        15,
        0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 4.0,
      color: isDark ? Palette.darkSurface : Palette.lightSurface,
      constraints: const BoxConstraints(
        minWidth: 160.0,
        maxWidth: 200.0,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'profile',
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Profile', style: TextStyle(fontSize: 14.0)),
        ),
        PopupMenuItem<String>(
          height: 1,
          padding: EdgeInsets.zero,
          enabled: false,
          child: Divider(color: isDark ? Palette.darkDivider : Palette.lightDivider, height: 1),
        ),
        PopupMenuItem<String>(
          value: 'notification',
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Notification', style: TextStyle(fontSize: 14.0)),
        ),
        PopupMenuItem<String>(
          height: 1,
          padding: EdgeInsets.zero,
          enabled: false,
          child: Divider(color: isDark ? Palette.darkDivider : Palette.lightDivider, height: 1),
        ),
        PopupMenuItem<String>(
          value: 'security',
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Security', style: TextStyle(fontSize: 14.0)),
        ),
        PopupMenuItem<String>(
          height: 1,
          padding: EdgeInsets.zero,
          enabled: false,
          child: Divider(color: isDark ? Palette.darkDivider : Palette.lightDivider, height: 1),
        ),
        PopupMenuItem<String>(
          value: 'updates',
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Updates', style: TextStyle(fontSize: 14.0)),
        ),
        PopupMenuItem<String>(
          height: 1,
          padding: EdgeInsets.zero,
          enabled: false,
          child: Divider(color: isDark ? Palette.darkDivider : Palette.lightDivider, height: 1),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Logout', style: TextStyle(color: Palette.lightError, fontSize: 14.0)),
        ),
      ],
    ).then((String? result) async {
      if (result != null) {
        switch (result) {
          case 'profile':
            // Navigate to settings with profile tab (index 0)
            if (widget.onSettingsTabRequested != null) {
              widget.onSettingsTabRequested!(0);
            } else {
              // Fallback: navigate to settings page with profile tab
              Navigator.pushNamed(context, '/settings', arguments: {'tabIndex': 0});
            }
            break;
          case 'notification':
            // Navigate to settings with notifications tab (index 1)
            if (widget.onSettingsTabRequested != null) {
              widget.onSettingsTabRequested!(1);
            } else {
              // Fallback: navigate to settings page with notifications tab
              Navigator.pushNamed(context, '/settings', arguments: {'tabIndex': 1});
            }
            break;
            case 'security':
              // Navigate to settings with security tab (index 3)
              if (widget.onSettingsTabRequested != null) {
                widget.onSettingsTabRequested!(3);
              }
              break;
            case 'updates':
              // Navigate to settings with updates tab (index 2)
              if (widget.onSettingsTabRequested != null) {
                widget.onSettingsTabRequested!(2);
              }
              break;
          case 'logout':
            try { await AuthService().clearSession(); } catch (_) {}
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (Route<dynamic> route) => false,
              );
            }
            break;
        }
      }
    });
  }
}
