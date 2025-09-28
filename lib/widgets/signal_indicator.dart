import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pasada_admin_application/services/connectivity_service.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';

class SignalIndicator extends StatelessWidget {
  const SignalIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivityService, child) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final isDark = themeProvider.isDarkMode;
        
        if (!connectivityService.isConnected) {
          return _buildSignalIcon(
            Icons.signal_wifi_off,
            Colors.red,
            'No Connection',
            isDark,
          );
        }
        
        if (connectivityService.isVerySlowConnection) {
          return _buildSignalIcon(
            Icons.signal_wifi_off,
            Colors.red,
            'Very Slow Connection',
            isDark,
          );
        }
        
        if (connectivityService.isSlowConnection) {
          return _buildSignalIcon(
            Icons.warning,
            Colors.orange,
            'Slow Connection',
            isDark,
          );
        }
        
        return _buildSignalIcon(
          Icons.signal_wifi_4_bar,
          Colors.green,
          'Good Connection',
          isDark,
        );
      },
    );
  }

  Widget _buildSignalIcon(IconData icon, Color color, String tooltip, bool isDark) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }
}

class CompactSignalIndicator extends StatelessWidget {
  const CompactSignalIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivityService, child) {
        if (!connectivityService.isConnected) {
          return Icon(Icons.signal_wifi_off, size: 14, color: Colors.red);
        }
        
        if (connectivityService.isVerySlowConnection) {
          return Icon(Icons.signal_wifi_off, size: 14, color: Colors.red);
        }
        
        if (connectivityService.isSlowConnection) {
          return Icon(Icons.warning, size: 14, color: Colors.orange);
        }
        
        return Icon(Icons.signal_wifi_4_bar, size: 14, color: Colors.green);
      },
    );
  }
}
