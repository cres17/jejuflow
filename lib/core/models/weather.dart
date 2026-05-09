import 'package:flutter/material.dart';

enum WeatherCondition { clear, cloudy, rain, windy, storm }
enum TimeOfDay { morning, noon, afternoon, evening, night }

class WeatherData {
  final WeatherCondition condition;
  final String? temperature;
  final double wind;
  final DateTime updatedAt;
  final bool fromCache;
  final Color bgColor;
  final Color accentColor;

  const WeatherData({
    required this.condition,
    required this.temperature,
    required this.wind,
    required this.updatedAt,
    required this.fromCache,
    required this.bgColor,
    required this.accentColor,
  });

  bool get isBad =>
      condition == WeatherCondition.rain ||
      condition == WeatherCondition.windy ||
      condition == WeatherCondition.storm;

  IconData get iconData {
    switch (condition) {
      case WeatherCondition.clear:
        return Icons.wb_sunny_rounded;
      case WeatherCondition.cloudy:
        return Icons.cloud_rounded;
      case WeatherCondition.rain:
        return Icons.grain_rounded;
      case WeatherCondition.windy:
        return Icons.air_rounded;
      case WeatherCondition.storm:
        return Icons.thunderstorm_rounded;
    }
  }

  String get label {
    switch (condition) {
      case WeatherCondition.clear:
        return 'Clear';
      case WeatherCondition.cloudy:
        return 'Cloudy';
      case WeatherCondition.rain:
        return 'Rain';
      case WeatherCondition.windy:
        return 'Strong Wind';
      case WeatherCondition.storm:
        return 'Storm';
    }
  }

  String get advice {
    switch (condition) {
      case WeatherCondition.clear:
        return 'Perfect for outdoor spots today.';
      case WeatherCondition.cloudy:
        return 'Comfortable for indoor and outdoor plans.';
      case WeatherCondition.rain:
        return 'Rain today. Indoor spots are recommended.';
      case WeatherCondition.windy:
        return 'Coastal spots may be risky. Stay inland.';
      case WeatherCondition.storm:
        return 'Stay indoors. Outdoor activities are paused.';
    }
  }

  String? get warning {
    switch (condition) {
      case WeatherCondition.rain:
        return 'Slippery paths at outdoor spots';
      case WeatherCondition.windy:
        return 'Wind advisory. Coastal areas may be unsafe';
      case WeatherCondition.storm:
        return 'Storm warning. Outdoor activities suspended';
      default:
        return null;
    }
  }

  String get updatedAgo {
    final d = DateTime.now().difference(updatedAt).inSeconds;
    if (d < 10) return 'just now';
    if (d < 60) return '${d}s ago';
    if (d < 3600) return '${d ~/ 60}m ago';
    return '${d ~/ 3600}h ago';
  }
}
