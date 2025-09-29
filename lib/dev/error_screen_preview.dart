import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/widgets/error_screen.dart';

void main() {
  runApp(const ErrorScreenPreviewApp());
}

class ErrorScreenPreviewApp extends StatelessWidget {
  const ErrorScreenPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Error Screen Preview',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Palette.greenColor),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: Palette.greenColor, brightness: Brightness.dark),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      themeMode: ThemeMode.system,
      home: const _PreviewHome(),
    );
  }
}

class _PreviewHome extends StatelessWidget {
  const _PreviewHome();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Palette.darkSurface : Palette.lightSurface,
      appBar: AppBar(
        title: const Text('Error Screen Preview'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PreviewButton(
                  label: '400 - Bad Request',
                  onTap: () => _open(context, ErrorScreen.badRequest(onRetry: () => Navigator.of(context).pop())),
                ),
                const SizedBox(height: 10),
                _PreviewButton(
                  label: '401 - Authentication Required',
                  onTap: () => _open(context, ErrorScreen.authRequired(onLogin: () => Navigator.of(context).pop())),
                ),
                const SizedBox(height: 10),
                _PreviewButton(
                  label: '403 - Access Denied',
                  onTap: () => _open(context, ErrorScreen.forbidden(onBack: () => Navigator.of(context).pop())),
                ),
                const SizedBox(height: 10),
                _PreviewButton(
                  label: '502 - Bad Gateway',
                  onTap: () => _open(context, ErrorScreen.badGateway(onRetry: () => Navigator.of(context).pop())),
                ),
                const SizedBox(height: 10),
                _PreviewButton(
                  label: '503 - Service Unavailable',
                  onTap: () => _open(context, ErrorScreen.serviceUnavailable(onRetry: () => Navigator.of(context).pop())),
                ),
                const SizedBox(height: 20),
                Text(
                  'Note: 404 and 500 use message-only handling in the app (no screen).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic));
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation.drive(tween), child: child),
          );
        },
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PreviewButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        foregroundColor: Colors.white,
        backgroundColor: Palette.greenColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.open_in_new, size: 18, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}


