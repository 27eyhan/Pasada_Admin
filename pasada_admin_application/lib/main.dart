import 'package:flutter/material.dart';
import 'package:pasada_admin_application/screen/main_navigation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pasada_admin_application/maps/google_maps_api.dart';
// Removed authentication flow
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  // Skip authentication; go directly to main

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

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

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
            initialRoute: '/main',
            routes: {
              '/main': (context) => MainNavigation(),
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
