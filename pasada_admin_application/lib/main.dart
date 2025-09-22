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
    return child;
  }
}

// Login screen is provided by LoginSignup
