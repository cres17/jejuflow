import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  static String get weather => dotenv.env['EXPO_PUBLIC_WEATHER_API_KEY'] ?? '';
  static String get tago => dotenv.env['EXPO_PUBLIC_TAGO_API_KEY'] ?? '';
  static String get tour => dotenv.env['EXPO_PUBLIC_TOUR_API_KEY'] ?? '';
  static String get maps => dotenv.env['EXPO_PUBLIC_GOOGLE_MAPS_KEY'] ?? '';
  static String get kakaoMap =>
      dotenv.env['EXPO_KAKAOMAP_KEY'] ??
      dotenv.env['EXPO_PUBLIC_KAKAOMAP_KEY'] ??
      dotenv.env['KAKAO_MAP_KEY'] ??
      '';

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
}
