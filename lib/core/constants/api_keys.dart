import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  static String get weather => _value('EXPO_PUBLIC_WEATHER_API_KEY');
  static String get tago => _value('EXPO_PUBLIC_TAGO_API_KEY');
  static String get tour => _value('EXPO_PUBLIC_TOUR_API_KEY');
  static String get maps => _value('EXPO_PUBLIC_GOOGLE_MAPS_KEY');
  static String get kakaoMap => _firstValue([
        'EXPO_KAKAOMAP_KEY',
        'EXPO_PUBLIC_KAKAOMAP_KEY',
        'KAKAO_MAP_KEY',
      ]);

  static String get weatherServiceKey => _decoded(weather);
  static String get tagoServiceKey => _decoded(tago);
  static String get tourServiceKey => _decoded(tour);

  static const weatherBase =
      'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0';
  static const tagoBase = 'https://apis.data.go.kr/1613000';
  static const tourBase = 'https://apis.data.go.kr/B551011/KorService2';

  static String _decoded(String value) {
    final trimmed = value.trim();
    if (!trimmed.contains('%')) return trimmed;

    try {
      return Uri.decodeComponent(trimmed);
    } catch (_) {
      return trimmed;
    }
  }

  static String _value(String key) {
    final fromDefine = switch (key) {
      'EXPO_PUBLIC_WEATHER_API_KEY' =>
        const String.fromEnvironment('EXPO_PUBLIC_WEATHER_API_KEY'),
      'EXPO_PUBLIC_TAGO_API_KEY' =>
        const String.fromEnvironment('EXPO_PUBLIC_TAGO_API_KEY'),
      'EXPO_PUBLIC_TOUR_API_KEY' =>
        const String.fromEnvironment('EXPO_PUBLIC_TOUR_API_KEY'),
      'EXPO_PUBLIC_GOOGLE_MAPS_KEY' =>
        const String.fromEnvironment('EXPO_PUBLIC_GOOGLE_MAPS_KEY'),
      'EXPO_KAKAOMAP_KEY' => const String.fromEnvironment('EXPO_KAKAOMAP_KEY'),
      'EXPO_PUBLIC_KAKAOMAP_KEY' =>
        const String.fromEnvironment('EXPO_PUBLIC_KAKAOMAP_KEY'),
      'KAKAO_MAP_KEY' => const String.fromEnvironment('KAKAO_MAP_KEY'),
      _ => '',
    };
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.env[key] ?? '';
  }

  static String _firstValue(List<String> keys) {
    for (final key in keys) {
      final value = _value(key);
      if (value.isNotEmpty) return value;
    }
    return '';
  }
}
