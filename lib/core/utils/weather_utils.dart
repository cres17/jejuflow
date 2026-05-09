import '../models/weather.dart';

WeatherCondition classifyWeather(String pty, double wsd, String sky) {
  final isRain = ['1', '2', '3', '4'].contains(pty);
  if (isRain && wsd >= 14) return WeatherCondition.storm;
  if (isRain)              return WeatherCondition.rain;
  if (wsd >= 14)           return WeatherCondition.windy;
  if (sky == '4')          return WeatherCondition.cloudy;
  return WeatherCondition.clear;
}

TimeOfDay detectTimeOfDay() {
  final h = DateTime.now().hour;
  if (h >= 5  && h < 10) return TimeOfDay.morning;
  if (h >= 10 && h < 13) return TimeOfDay.noon;
  if (h >= 13 && h < 18) return TimeOfDay.afternoon;
  if (h >= 18 && h < 22) return TimeOfDay.evening;
  return TimeOfDay.night;
}
