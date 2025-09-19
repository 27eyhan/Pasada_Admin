import 'package:flutter/material.dart';
import 'package:pasada_admin_application/screen/main_navigation.dart';
import 'package:pasada_admin_application/screen/login_set_up/login_signup.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pasada_admin_application/maps/google_maps_api.dart';
import 'package:pasada_admin_application/services/auth_service.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  // Initialize AuthService and load admin ID
  final authService = AuthService();
  await authService.loadAdminID();

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

  runApp(MainApp(initialRoute: authService.currentAdminID != null ? '/main' : '/login'));
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
              '/main': (context) => MainNavigation(),
              '/login': (context) => LoginSignup(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/main') {
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
