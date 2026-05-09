import 'package:flutter/widgets.dart';
import '../models/weather.dart';

class WeatherTheme {
  final Color bgColor;
  final Color accentColor;
  const WeatherTheme({required this.bgColor, required this.accentColor});
}

const _themes = <String, List<int>>{
  'clear-morning':    [0xFF0F2A12, 0xFF2A7A4A],
  'clear-noon':       [0xFF003A58, 0xFF1876A8],
  'clear-afternoon':  [0xFF182808, 0xFF2A7A4A],
  'clear-evening':    [0xFF281408, 0xFFB86820],
  'clear-night':      [0xFF080818, 0xFF3848A8],
  'cloudy-morning':   [0xFF181820, 0xFF8888B0],
  'cloudy-noon':      [0xFF181C28, 0xFF6888B0],
  'cloudy-afternoon': [0xFF1C1818, 0xFF9890A8],
  'cloudy-evening':   [0xFF181018, 0xFF9878B0],
  'cloudy-night':     [0xFF0A0A14, 0xFF5858A0],
  'rain-morning':     [0xFF0A1020, 0xFF4878C0],
  'rain-noon':        [0xFF0C1428, 0xFF3870B0],
  'rain-afternoon':   [0xFF0E1224, 0xFF4068A8],
  'rain-evening':     [0xFF0C0818, 0xFF6858A8],
  'rain-night':       [0xFF080810, 0xFF404088],
  'windy-morning':    [0xFF0A2020, 0xFF00A898],
  'windy-noon':       [0xFF081E1C, 0xFF009888],
  'windy-afternoon':  [0xFF0E1C18, 0xFF40A880],
  'windy-evening':    [0xFF0A1410, 0xFF389878],
  'windy-night':      [0xFF06100C, 0xFF287858],
  'storm-morning':    [0xFF180808, 0xFFD83030],
  'storm-noon':       [0xFF160A08, 0xFFC82828],
  'storm-afternoon':  [0xFF140808, 0xFFC02020],
  'storm-evening':    [0xFF100608, 0xFFA82030],
  'storm-night':      [0xFF0C0408, 0xFF881828],
};

WeatherTheme getWeatherTheme(WeatherCondition condition, TimeOfDay timeOfDay) {
  final key  = '${condition.name}-${timeOfDay.name}';
  final vals = _themes[key] ?? _themes['clear-morning']!;
  return WeatherTheme(bgColor: Color(vals[0]), accentColor: Color(vals[1]));
}
