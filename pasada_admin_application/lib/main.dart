import 'package:flutter/material.dart';
import 'package:pasada_admin_application/screen/main_pages/dashboard_pages/dashboard.dart';
import 'package:pasada_admin_application/screen/login_set_up/login_signup.dart';
import 'package:pasada_admin_application/screen/main_pages/fleet_pages/fleet.dart';
import 'package:pasada_admin_application/screen/main_pages/drivers_pages/drivers.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/reports.dart';
import 'package:pasada_admin_application/screen/main_pages/ai_chat.dart';
import 'package:pasada_admin_application/screen/settings_pages/settings.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/data_tables.dart';
import 'package:pasada_admin_application/screen/main_pages/reports_pages/select_table.dart';
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

  runApp(MainApp(initialRoute: authService.currentAdminID != null ? '/dashboard' : '/login'));
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
              '/dashboard': (context) => Dashboard(),
              '/login': (context) => LoginSignup(),
              '/fleet': (context) => Fleet(),
              '/drivers': (context) => Drivers(),
              '/reports': (context) => Reports(),
              '/ai_chat': (context) => AiChat(),
              '/settings': (context) => Settings(),
              '/data_tables': (context) => DataTables(),
              '/select_table': (context) => SelectTable(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/dashboard') {
                final args = settings.arguments as Map<String, dynamic>?;
                if (args != null) {
                  return MaterialPageRoute(
                    builder: (context) => Dashboard(driverLocationArgs: args),
                  );
                }
              }
              
              // Handle settings with specific tab index
              if (settings.name == '/settings') {
                final args = settings.arguments as Map<String, dynamic>?;
                if (args != null && args.containsKey('tabIndex')) {
                  final tabIndex = args['tabIndex'] as int;
                  return MaterialPageRoute(
                    builder: (context) => Settings(initialTabIndex: tabIndex),
                  );
                }
              }
              
              return null;
            },
          );
        },
      ),
    );
  }
}
