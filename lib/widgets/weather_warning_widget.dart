import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/models/weather_model.dart';
import 'package:pasada_admin_application/services/weather_service.dart';
import 'package:provider/provider.dart';

class WeatherWarningWidget extends StatefulWidget {
  const WeatherWarningWidget({super.key});

  @override
  _WeatherWarningWidgetState createState() => _WeatherWarningWidgetState();
}

class _WeatherWarningWidgetState extends State<WeatherWarningWidget> {
  final WeatherService _weatherService = WeatherService();
  WeatherModel? _weather;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      final weather = await _weatherService.getCurrentWeather('Manila');
      if (mounted) {
        setState(() {
          _weather = weather;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Don't show warning if loading, no weather data, or weather doesn't affect analytics
    if (_isLoading || _weather == null || !_weather!.isAffectingAnalytics) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Palette.lightWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Palette.lightWarning,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Palette.lightWarning,
            size: 24,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather Alert',
                  style: TextStyle(
                    color: Palette.lightWarning,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Current weather conditions (${_weather!.condition}) may affect analytics accuracy. Please consider this when reviewing fleet performance data.',
                  style: TextStyle(
                    color: isDark ? Palette.darkText : Palette.lightText,
                    fontSize: 14.0,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
