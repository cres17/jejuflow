import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../constants/api_keys.dart';
import '../models/bus_arrival.dart';
import 'api_http.dart';
import 'cache_service.dart';

class TransitService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    responseType: ResponseType.json,
    headers: const {'Accept': 'application/json'},
    validateStatus: (status) => status != null && status < 600,
  ));

  static Future<List<BusArrival>> fetchArrivals(String stopId) async {
    final cacheKey = 'bus:$stopId';
    final cached = await CacheService.get<List<BusArrival>>(
      cacheKey,
      CacheService.minute,
      _arrivalsFromJson,
    );
    if (cached != null) return cached;
    try {
      final uri = Uri.https(
        'apis.data.go.kr',
        '/1613000/ArvlInfoInqireService/getSttnAcctoArvlPrearngeInfoList',
        {
          'serviceKey': ApiKeys.tagoServiceKey,
          'pageNo': '1',
          'numOfRows': '10',
          '_type': 'json',
          'cityCode': '39',
          'nodeId': stopId,
        },
      );

      final res = await ApiHttp.getUri(_dio, uri);
      if (res.statusCode != 200) {
        _logApiError('Transit arrival', res);
        return _staleArrivals(cacheKey);
      }

      final result = _items(res.data)
          .whereType<Map>()
          .map((e) => BusArrival.fromApi(Map<String, dynamic>.from(e)))
          .toList();

      await CacheService.set(cacheKey, _arrivalsToJson(result));
      return result;
    } catch (e) {
      debugPrint('Transit Arrival Error: $e');
      return _staleArrivals(cacheKey);
    }
  }

  static Future<RouteInfo?> fetchRouteInfo(String routeId) async {
    final cacheKey = 'route:$routeId';
    final cached = await CacheService.get<RouteInfo>(
      cacheKey,
      CacheService.day,
      _routeFromJson,
    );
    if (cached != null) return cached;
    try {
      final uri = Uri.https(
        'apis.data.go.kr',
        '/1613000/BusRouteInfoInqireService/getRouteInfoIem',
        {
          'serviceKey': ApiKeys.tagoServiceKey,
          'pageNo': '1',
          'numOfRows': '10',
          'cityCode': '39',
          'routeId': routeId,
          '_type': 'json',
        },
      );

      final res = await ApiHttp.getUri(_dio, uri);
      if (res.statusCode != 200) {
        _logApiError('Transit route', res);
        return CacheService.getStale<RouteInfo>(cacheKey, _routeFromJson);
      }

      final items = _items(res.data);
      if (items.isEmpty || items.first is! Map) return null;

      final item = Map<String, dynamic>.from(items.first as Map);
      final result = RouteInfo(
        routeId: item['routeid']?.toString() ?? routeId,
        routeNo: item['routeno']?.toString() ?? '-',
        startStop: item['startnodenm']?.toString() ?? '-',
        endStop: item['endnodenm']?.toString() ?? '-',
      );
      await CacheService.set(cacheKey, _routeToJson(result));
      return result;
    } catch (e) {
      debugPrint('Transit Route Error: $e');
      return CacheService.getStale<RouteInfo>(cacheKey, _routeFromJson);
    }
  }

  static List<dynamic> _items(dynamic data) {
    dynamic body;
    if (data is Map && data['response'] is Map) {
      body = (data['response'] as Map)['body'];
    }

    final itemsWrapper = body?['items'];
    if (itemsWrapper is! Map) return [];

    final raw = itemsWrapper['item'];
    if (raw == null || raw == '') return [];
    return raw is List ? raw : [raw];
  }

  static void _logApiError(String name, Response<dynamic> res) {
    dynamic header;
    if (res.data is Map && res.data['response'] is Map) {
      header = (res.data['response'] as Map)['header'];
    }
    debugPrint(
      '$name failed: HTTP ${res.statusCode}, '
      'code=${header?['resultCode']}, msg=${header?['resultMsg']}',
    );
  }

  static Future<List<BusArrival>> _staleArrivals(String cacheKey) async {
    return (await CacheService.getStale<List<BusArrival>>(
          cacheKey,
          _arrivalsFromJson,
        )) ??
        [];
  }

  static List<dynamic> _arrivalsToJson(List<BusArrival> list) {
    return list
        .map((a) => {
              'routeNo': a.routeNo,
              'destination': a.destination,
              'arrivalMinutes': a.arrivalMinutes,
              'remainingStops': a.remainingStops,
              'isLongWait': a.isLongWait,
            })
        .toList();
  }

  static List<BusArrival> _arrivalsFromJson(dynamic json) {
    return (json as List).map((e) {
      final m = e as Map<String, dynamic>;
      return BusArrival(
        routeNo: m['routeNo']?.toString() ?? '-',
        destination: m['destination']?.toString() ?? '-',
        arrivalMinutes: (m['arrivalMinutes'] as num?)?.toInt() ?? 0,
        remainingStops: (m['remainingStops'] as num?)?.toInt() ?? 0,
        isLongWait: m['isLongWait'] == true,
      );
    }).toList();
  }

  static Map<String, dynamic> _routeToJson(RouteInfo r) {
    return {
      'routeId': r.routeId,
      'routeNo': r.routeNo,
      'startStop': r.startStop,
      'endStop': r.endStop,
    };
  }

  static RouteInfo _routeFromJson(dynamic json) {
    final m = json as Map<String, dynamic>;
    return RouteInfo(
      routeId: m['routeId']?.toString() ?? '-',
      routeNo: m['routeNo']?.toString() ?? '-',
      startStop: m['startStop']?.toString() ?? '-',
      endStop: m['endStop']?.toString() ?? '-',
    );
  }
}
