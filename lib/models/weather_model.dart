class WeatherModel {
  final String location;
  final double temperature;
  final String condition;
  final String icon;
  final double humidity;
  final double windSpeed;
  final String windDirection;
  final double pressure;
  final double visibility;
  final String lastUpdated;

  WeatherModel({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.pressure,
    required this.visibility,
    required this.lastUpdated,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final current = json['current'] ?? {};
    final location = json['location'] ?? {};
    
    return WeatherModel(
      location: location['name'] ?? 'Unknown',
      temperature: (current['temp_c'] ?? 0).toDouble(),
      condition: current['condition']?['text'] ?? 'Unknown',
      icon: current['condition']?['icon'] ?? '',
      humidity: (current['humidity'] ?? 0).toDouble(),
      windSpeed: (current['wind_kph'] ?? 0).toDouble(),
      windDirection: current['wind_dir'] ?? 'Unknown',
      pressure: (current['pressure_mb'] ?? 0).toDouble(),
      visibility: (current['vis_km'] ?? 0).toDouble(),
      lastUpdated: current['last_updated'] ?? '',
    );
  }

  // Helper method to check if weather conditions might affect analytics
  bool get isAffectingAnalytics {
    final conditionLower = condition.toLowerCase();
    return conditionLower.contains('rain') || 
           conditionLower.contains('thunder') || 
           conditionLower.contains('storm') ||
           conditionLower.contains('heavy rain') ||
           conditionLower.contains('thunderstorm');
  }

  // Get weather icon based on condition
  String get weatherIcon {
    final conditionLower = condition.toLowerCase();
    if (conditionLower.contains('sun') || conditionLower.contains('clear')) {
      return '☀️';
    } else if (conditionLower.contains('cloud')) {
      return '☁️';
    } else if (conditionLower.contains('rain')) {
      return '🌧️';
    } else if (conditionLower.contains('thunder') || conditionLower.contains('storm')) {
      return '⛈️';
    } else if (conditionLower.contains('snow')) {
      return '❄️';
    } else if (conditionLower.contains('fog') || conditionLower.contains('mist')) {
      return '🌫️';
    } else {
      return '🌤️';
    }
  }
}