import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/models/weather_model.dart';
import 'package:provider/provider.dart';

class WeatherDetailsModal extends StatelessWidget {
  final WeatherModel weather;

  const WeatherDetailsModal({
    super.key,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width > 800 ? 700 : MediaQuery.of(context).size.width * 0.95,
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: isDark ? Palette.darkSurface : Palette.lightSurface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isDark ? Palette.darkBorder : Palette.lightBorder,
            width: 1.0,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isMobile ? 24.0 : 32.0),
                decoration: BoxDecoration(
                  color: isDark ? Palette.darkCard : Palette.lightCard,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      weather.weatherIcon,
                      style: TextStyle(fontSize: isMobile ? 24 : 32),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            weather.location,
                            style: TextStyle(
                              color: isDark ? Palette.darkText : Palette.lightText,
                              fontSize: isMobile ? 20 : 24,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            weather.condition,
                            style: TextStyle(
                              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                              fontSize: isMobile ? 14 : 16,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Palette.darkText : Palette.lightText,
                        size: isMobile ? 20 : 24,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: EdgeInsets.all(isMobile ? 24.0 : 32.0),
                child: Column(
                  children: [
                    // Temperature
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${weather.temperature.round()}°C',
                          style: TextStyle(
                            color: isDark ? Palette.darkText : Palette.lightText,
                            fontSize: isMobile ? 40 : 64,
                            fontWeight: FontWeight.w300,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 24.0 : 32.0),
                    // Weather details grid - responsive
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = MediaQuery.of(context).size.width < 600;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: isMobile ? 1 : 2,
                          crossAxisSpacing: 20.0,
                          mainAxisSpacing: 20.0,
                          childAspectRatio: isMobile ? 3.5 : 2.2,
                          children: [
                            _buildDetailItem(
                              'Humidity',
                              '${weather.humidity.round()}%',
                              Icons.water_drop,
                              isDark,
                              context,
                            ),
                            _buildDetailItem(
                              'Wind Speed',
                              '${weather.windSpeed.round()} km/h',
                              Icons.air,
                              isDark,
                              context,
                            ),
                            _buildDetailItem(
                              'Pressure',
                              '${weather.pressure.round()} mb',
                              Icons.compress,
                              isDark,
                              context,
                            ),
                            _buildDetailItem(
                              'Visibility',
                              '${weather.visibility.round()} km',
                              Icons.visibility,
                              isDark,
                              context,
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: isMobile ? 24.0 : 32.0),
                    // Wind direction
                    Container(
                      padding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
                      decoration: BoxDecoration(
                        color: isDark ? Palette.darkCard : Palette.lightCard,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: isDark ? Palette.darkBorder : Palette.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.navigation,
                            color: isDark ? Palette.darkText : Palette.lightText,
                            size: isMobile ? 20 : 24,
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Text(
                              'Wind Direction: ${weather.windDirection}',
                              style: TextStyle(
                                color: isDark ? Palette.darkText : Palette.lightText,
                                fontSize: isMobile ? 14 : 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    // Last updated
                    Text(
                      'Last updated: ${weather.lastUpdated}',
                      style: TextStyle(
                        color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                        fontSize: isMobile ? 12 : 14,
                        fontFamily: 'Inter',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, bool isDark, BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isDark ? Palette.darkBorder : Palette.lightBorder,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isDark ? Palette.darkText : Palette.lightText,
            size: isMobile ? 20 : 24,
          ),
          SizedBox(height: isMobile ? 8.0 : 12.0),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Palette.darkText : Palette.lightText,
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: isMobile ? 4.0 : 6.0),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
              fontSize: isMobile ? 12 : 14,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
