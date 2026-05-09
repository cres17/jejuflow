import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show Color;
import '../constants/api_keys.dart';
import '../models/weather.dart' as model;
import '../models/spot.dart';
import 'cache_service.dart';
import '../utils/weather_utils.dart';
import '../utils/time_utils.dart';
import '../utils/weather_themes.dart';
import 'api_http.dart';

class WeatherService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
    responseType: ResponseType.json,
  ));

  static Future<model.WeatherData> fetchWeather(SpotRegion region) async {
    final cacheKey = 'weather:${region.name}';
    final cached = await CacheService.get<model.WeatherData>(
        cacheKey, CacheService.tenMin, _fromJson);
    if (cached != null) return cached;

    final grid = (region == SpotRegion.jejuCity)
        ? {'nx': 53, 'ny': 38}
        : {'nx': 52, 'ny': 33};
    final kmaTime = getKMABaseDateTime();

    try {
      // 媛?대뱶 ?섏튃: Decoding ?ㅻ? ?ъ슜?섏뿬 Uri ?앹꽦 (?쒖뒪?쒖씠 ??踰덈쭔 ?몄퐫?⑺븯?꾨줉 ??
      final uri = Uri.https('apis.data.go.kr',
          '/1360000/VilageFcstInfoService_2.0/getVilageFcst', {
        'serviceKey': ApiKeys.weatherServiceKey,
        'pageNo': '1',
        'numOfRows': '100',
        'dataType': 'JSON',
        'base_date': kmaTime['date'],
        'base_time': kmaTime['time'],
        'nx': grid['nx'].toString(),
        'ny': grid['ny'].toString(),
      });

      final res = await ApiHttp.getUri(_dio, uri);
      final body = res.data?['response']?['body'];
      final itemsWrapper = body?['items'];

      if (itemsWrapper is! Map) throw Exception('No items in response');

      final items = (itemsWrapper['item'] as List?) ?? [];
      final result = _parseItems(items, detectTimeOfDay());

      await CacheService.set(cacheKey, _toJson(result));
      return result;
    } catch (e) {
      debugPrint('Weather API Error: $e');
      return (await CacheService.getStale<model.WeatherData>(
              cacheKey, _fromJson)) ??
          _mockWeather(detectTimeOfDay());
    }
  }

  static model.WeatherData _parseItems(List items, model.TimeOfDay timeOfDay) {
    final target = '${DateTime.now().hour.toString().padLeft(2, '0')}00';
    String pty = '0', sky = '1';
    double wsd = 0;
    String? tmp;
    String? fallbackTmp;

    for (final item in items) {
      if (item['category'] == 'TMP' && fallbackTmp == null) {
        fallbackTmp = item['fcstValue'].toString();
      }
      if (item['fcstTime']?.toString() != target) continue;
      switch (item['category']) {
        case 'PTY':
          pty = item['fcstValue'].toString();
          break;
        case 'WSD':
          wsd = double.tryParse(item['fcstValue'].toString()) ?? 0;
          break;
        case 'TMP':
          tmp = item['fcstValue'].toString();
          break;
        case 'SKY':
          sky = item['fcstValue'].toString();
          break;
      }
    }

    tmp ??= fallbackTmp;
    final condition = classifyWeather(pty, wsd, sky);
    final theme = getWeatherTheme(condition, timeOfDay);
    return model.WeatherData(
      condition: condition,
      temperature: tmp != null ? '$tmp°C' : '--°C',
      wind: wsd,
      updatedAt: DateTime.now(),
      fromCache: false,
      bgColor: theme.bgColor,
      accentColor: theme.accentColor,
    );
  }

  static model.WeatherData _mockWeather(model.TimeOfDay timeOfDay) {
    final theme = getWeatherTheme(model.WeatherCondition.clear, timeOfDay);
    return model.WeatherData(
      condition: model.WeatherCondition.clear,
      temperature: '22°C',
      wind: 3.2,
      updatedAt: DateTime.now(),
      fromCache: false,
      bgColor: theme.bgColor,
      accentColor: theme.accentColor,
    );
  }

  static Map<String, dynamic> _toJson(model.WeatherData w) => {
        'conditionIndex': w.condition.index,
        'temperature': w.temperature,
        'wind': w.wind,
        'updatedAt': w.updatedAt.millisecondsSinceEpoch,
        'bgColorValue': w.bgColor.toARGB32(),
        'accentValue': w.accentColor.toARGB32(),
      };

  static model.WeatherData _fromJson(dynamic j) {
    final m = j as Map<String, dynamic>;
    return model.WeatherData(
      condition: model.WeatherCondition.values[m['conditionIndex']],
      temperature: m['temperature'],
      wind: (m['wind'] as num).toDouble(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updatedAt']),
      fromCache: true,
      bgColor: Color(m['bgColorValue']),
      accentColor: Color(m['accentValue']),
    );
  }
}
