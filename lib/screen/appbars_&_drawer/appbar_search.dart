import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/widgets/weather_widget.dart';
import 'package:pasada_admin_application/widgets/signal_indicator.dart';
import 'package:provider/provider.dart';

typedef FilterCallback = void Function();
typedef SettingsTabCallback = void Function(int tabIndex);

class AppBarSearch extends StatefulWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;
  final FilterCallback? onFilterPressed;
  final SettingsTabCallback? onSettingsTabRequested;
  final bool showMobileMenu;
  final VoidCallback? onMobileMenuPressed;

  const AppBarSearch({
    super.key, 
    this.onFilterPressed,
    this.onSettingsTabRequested,
    this.showMobileMenu = false,
    this.onMobileMenuPressed,
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
            // Mobile menu button
            if (widget.showMobileMenu) ...[
              IconButton(
                onPressed: widget.onMobileMenuPressed,
                icon: Icon(
                  Icons.menu,
                  color: isDark ? Palette.darkText : Palette.lightText,
                ),
                tooltip: 'Menu',
              ),
              const SizedBox(width: 8.0),
            ],
            // Weather widget
            const WeatherWidget(),
            const SizedBox(width: 16.0),
            const Spacer(),
            // Signal indicator
            const SignalIndicator(),
            const SizedBox(width: 8.0),
            // Profile button styled like "Docs" link
            TextButton(
              onPressed: () {
                if (widget.onSettingsTabRequested != null) {
                  widget.onSettingsTabRequested!(0);
                } else {
                  Navigator.pushNamed(context, '/settings', arguments: {'tabIndex': 0});
                }
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

  // Dropdown removed; Profile button now redirects directly to Settings (Profile tab)
}
