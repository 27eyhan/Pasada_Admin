import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/models/weather_model.dart';
import 'package:pasada_admin_application/services/weather_service.dart';
import 'package:pasada_admin_application/screen/weather_details_modal.dart';
import 'package:provider/provider.dart';

class WeatherWidget extends StatefulWidget {
  final String city;
  
  const WeatherWidget({
    super.key,
    this.city = 'Manila', // Default to Manila
  });

  @override
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final WeatherService _weatherService = WeatherService();
  WeatherModel? _weather;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weather = await _weatherService.getCurrentWeather(widget.city);
      if (mounted) {
        setState(() {
          _weather = weather;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showWeatherDetails() {
    if (_weather != null) {
      showDialog(
        context: context,
        builder: (context) => WeatherDetailsModal(weather: _weather!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return GestureDetector(
      onTap: _weather != null ? _showWeatherDetails : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8.0 : 12.0, 
          vertical: isMobile ? 6.0 : 8.0,
        ),
        decoration: BoxDecoration(
          color: isDark ? Palette.darkCard : Palette.lightCard,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isDark ? Palette.darkBorder : Palette.lightBorder,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading) ...[
              SizedBox(
                width: isMobile ? 14 : 20,
                height: isMobile ? 14 : 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Palette.darkText : Palette.lightText,
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 6.0 : 8.0),
              Text(
                isMobile ? 'Loading...' : 'Loading weather...',
                style: TextStyle(
                  color: isDark ? Palette.darkText : Palette.lightText,
                  fontSize: isMobile ? 12.0 : 14.0,
                  fontFamily: 'Inter',
                ),
              ),
            ] else if (_error != null) ...[
              Icon(
                Icons.error_outline,
                size: isMobile ? 14 : 20,
                color: Palette.lightError,
              ),
              SizedBox(width: isMobile ? 6.0 : 8.0),
              Text(
                isMobile ? 'Error' : 'Weather unavailable',
                style: TextStyle(
                  color: Palette.lightError,
                  fontSize: isMobile ? 12.0 : 14.0,
                  fontFamily: 'Inter',
                ),
              ),
            ] else if (_weather != null) ...[
              Text(
                _weather!.weatherIcon,
                style: TextStyle(fontSize: isMobile ? 18 : 24),
              ),
              SizedBox(width: isMobile ? 6.0 : 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_weather!.temperature.round()}°C',
                    style: TextStyle(
                      color: isDark ? Palette.darkText : Palette.lightText,
                      fontSize: isMobile ? 14.0 : 20.0,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                  if (!isMobile) ...[
                    Text(
                      _weather!.condition,
                      style: TextStyle(
                        color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                        fontSize: 12.0,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
