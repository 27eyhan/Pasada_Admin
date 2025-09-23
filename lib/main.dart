import 'package:flutter/material.dart';
import 'package:pasada_admin_application/screen/main_navigation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pasada_admin_application/maps/google_maps_api.dart';
import 'package:pasada_admin_application/services/auth_service.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:pasada_admin_application/screen/login_set_up/login_signup.dart';
import 'dart:async';
import 'package:pasada_admin_application/config/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  // Load session and gate navigation
  final authService = AuthService();
  await authService.loadSession();

  await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
      storageOptions: const StorageClientOptions(
        retryAttempts: 10,
      ));

  // Initialize Google Maps API for web platform
  if (kIsWeb) {
    GoogleMapsApiInitializer.initialize();
  }

  runApp(MainApp(initialRoute: authService.isSessionValid ? '/main' : '/'));
}

class MainApp extends StatelessWidget {
  final String initialRoute;
  const MainApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Pasada',
            theme: themeProvider.currentTheme,
            initialRoute: initialRoute,
            routes: {
              '/': (context) => const LoginSignup(),
              '/login': (context) => const LoginSignup(),
              '/main': (context) => AuthGuard(child: MainNavigation()),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/main') {
                // Route-level guard for deep links
                final auth = AuthService();
                if (!auth.isSessionValid) {
                  return MaterialPageRoute(builder: (_) => const LoginSignup());
                }
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => MainNavigation(
                    initialPage: args?['page'] ?? '/dashboard',
                    initialArgs: args,
                  ),
                );
              }
              
              return null;
            },
          );
        },
      ),
    );
  }
}

class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    if (!auth.isSessionValid) {
      // Replace current route with login/root to ensure base URL
      // Using addPostFrameCallback to avoid build-time navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      });
      return const SizedBox.shrink();
    }
    return SessionWatcher(child: child);
  }
}

class SessionWatcher extends StatefulWidget {
  final Widget child;
  const SessionWatcher({super.key, required this.child});

  @override
  State<SessionWatcher> createState() => _SessionWatcherState();
}

class _SessionWatcherState extends State<SessionWatcher> {
  Timer? _timer;
  DateTime _lastActivity = DateTime.now();

  void _bumpActivity() {
    _lastActivity = DateTime.now();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final auth = AuthService();
      final enabled = auth.sessionTimeoutEnabled;
      final minutes = auth.sessionTimeoutMinutes;
      if (!enabled) return;
      final idleFor = DateTime.now().difference(_lastActivity);
      if (idleFor.inMinutes >= minutes) {
        _timer?.cancel();
        // Show dialog then logout
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? Palette.darkSurface : Palette.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
                side: BorderSide(
                  color: isDark ? Palette.darkBorder : Palette.lightBorder,
                  width: 1.0,
                ),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Palette.darkCard : Palette.lightCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? Palette.darkBorder : Palette.lightBorder),
                    ),
                    child: Icon(Icons.lock_clock, color: Palette.greenColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Session Ended',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Palette.darkText : Palette.lightText,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: Text(
                  'You have been logged out due to inactivity.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    foregroundColor: Colors.white,
                    backgroundColor: Palette.greenColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            );
          },
        );
        await AuthService().clearSession();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _bumpActivity(),
      onPointerMove: (_) => _bumpActivity(),
      onPointerUp: (_) => _bumpActivity(),
      child: widget.child,
    );
  }
}

// Login screen is provided by LoginSignup
