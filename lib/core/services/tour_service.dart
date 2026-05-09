import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../constants/api_keys.dart';
import '../models/place.dart';
import 'api_http.dart';
import 'cache_service.dart';

class TourPhoto {
  final String originUrl, thumbUrl;
  const TourPhoto({required this.originUrl, required this.thumbUrl});
}

class SpotInfoEN {
  final String overview, addr, tel, homepage, restdate, usetime, usefee;
  const SpotInfoEN({
    required this.overview,
    required this.addr,
    required this.tel,
    required this.homepage,
    required this.restdate,
    required this.usetime,
    required this.usefee,
  });
}

/// detailIntro2 응답 — 음식점/카페(39)와 관광지(12) 공통 필드만 저장
class SpotIntroInfo {
  /// 음식점/카페: opentimefood (영업시간)
  /// 관광지: usetimefestival or opentime (영업시간)
  final String openTime;

  /// 음식점/카페: restdatefood (휴무일)
  /// 관광지: restdate2
  final String restDate;

  /// 음식점/카페: firstmenu / treatmenu (대표 메뉴)
  final String menu;

  /// 관광지: usefee (이용요금, contentTypeId=12 전용)
  final String useFee;

  const SpotIntroInfo({
    this.openTime = '',
    this.restDate = '',
    this.menu = '',
    this.useFee = '',
  });

  bool get hasOpenTime => openTime.isNotEmpty;
  bool get hasMenu => menu.isNotEmpty;
}

class RelatedSpot {
  final String contentId, title, imageUrl;
  const RelatedSpot({
    required this.contentId,
    required this.title,
    required this.imageUrl,
  });
}

class TourService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    responseType: ResponseType.json,
    headers: const {'Accept': 'application/json'},
    validateStatus: (status) => status != null && status < 600,
  ));

  static String get _tourKey {
    return ApiKeys.tourServiceKey;
  }

  static Future<Response<dynamic>> _get(
    String path,
    Map<String, String> params,
  ) {
    final uri = Uri.https('apis.data.go.kr', path, {
      'serviceKey': _tourKey,
      'MobileOS': 'ETC',
      'MobileApp': 'JejuFlow',
      '_type': 'json',
      ...params,
    });
    return ApiHttp.getUri(_dio, uri);
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

  static Future<List<TourPlace>> fetchPlaces(
    PlaceType type, {
    int pageNo = 1,
    int numOfRows = 20,
    String arrange = 'C',
    String language = 'ko',
  }) async {
    final sourceLanguage = _sourceLanguage(language);
    final cacheKey =
        'tour:places:$sourceLanguage:${type.name}:$pageNo:$numOfRows:$arrange';
    final cached = await CacheService.get<List<TourPlace>>(
      cacheKey,
      CacheService.month,
      _placesFromJson,
    );
    if (cached != null) return cached;
    try {
      final contentTypeId = switch (type) {
        PlaceType.tourist => _touristContentTypeId(sourceLanguage),
        PlaceType.restaurant => _foodContentTypeId(sourceLanguage),
        PlaceType.cafe => _foodContentTypeId(sourceLanguage),
      };
      final params = {
        'pageNo': pageNo.toString(),
        'numOfRows': numOfRows.toString(),
        'areaCode': '39',
        'arrange': arrange,
      };
      if (contentTypeId.isNotEmpty) {
        params['contentTypeId'] = contentTypeId;
      }

      final res = await _get(
          '/B551011/${_serviceName(sourceLanguage)}/areaBasedList2', params);

      if (res.statusCode != 200) {
        _logApiError('Tour areaBasedList2', res);
        return [];
      }

      final result = _items(res.data)
          .whereType<Map>()
          .map((e) => TourPlace.fromApi(Map<String, dynamic>.from(e)))
          .where((place) => _isPlaceTypeMatch(place, type, sourceLanguage))
          .toList();
      if (result.isNotEmpty) {
        await CacheService.set(cacheKey, _placesToJson(result));
      }
      return result;
    } catch (e) {
      debugPrint('Tour places error: $e');
      return await CacheService.getStale<List<TourPlace>>(
            cacheKey,
            _placesFromJson,
          ) ??
          [];
    }
  }

  static Future<List<TourPhoto>> fetchPhotos(String contentId) async {
    if (contentId.isEmpty) return [];
    try {
      final res = await _get('/B551011/KorService2/detailImage2', {
        'contentId': contentId,
        'imageYN': 'Y',
        'numOfRows': '5',
        'pageNo': '1',
      });

      if (res.statusCode != 200) {
        _logApiError('Tour detailImage2', res);
        return [];
      }

      return _items(res.data)
          .whereType<Map>()
          .map((e) {
            final item = Map<String, dynamic>.from(e);
            final origin =
                _httpsImageUrl(item['originimgurl']?.toString() ?? '');
            final thumb =
                _httpsImageUrl(item['smallimageurl']?.toString() ?? origin);
            return TourPhoto(originUrl: origin, thumbUrl: thumb);
          })
          .where((photo) => photo.originUrl.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Tour photos error: $e');
      return [];
    }
  }

  static Future<List<TourPlace>> fetchAllPlaces(
    PlaceType type, {
    int numOfRows = 100,
    int maxPages = 8,
    String arrange = 'A',
    String language = 'ko',
  }) async {
    final sourceLanguage = _sourceLanguage(language);
    final cacheKey =
        'tour:all:$sourceLanguage:${type.name}:$numOfRows:$maxPages:$arrange';
    final cached = await CacheService.get<List<TourPlace>>(
      cacheKey,
      CacheService.month,
      _placesFromJson,
    );
    if (cached != null) return cached;
    final all = <TourPlace>[];
    final seen = <String>{};
    for (var page = 1; page <= maxPages; page++) {
      final places = await fetchPlaces(
        type,
        pageNo: page,
        numOfRows: numOfRows,
        arrange: arrange,
        language: sourceLanguage,
      );
      if (places.isEmpty) break;
      for (final place in places) {
        if (place.contentId.isEmpty || !seen.add(place.contentId)) continue;
        all.add(place);
      }
      if (places.length < numOfRows) break;
    }
    if (all.isNotEmpty) {
      await CacheService.set(cacheKey, _placesToJson(all));
    }
    return all;
  }

  static Future<SpotInfoEN?> fetchInfoEN(
    String contentId, {
    String language = 'en',
  }) async {
    if (contentId.isEmpty) return null;
    final sourceLanguage = _sourceLanguage(language);
    final cacheKey = 'tour:info:$sourceLanguage:$contentId';
    final cached = await CacheService.get<SpotInfoEN>(
      cacheKey,
      CacheService.month,
      _spotInfoFromJson,
    );
    if (cached != null) return cached;
    try {
      final serviceName = _serviceName(sourceLanguage);
      final res = await _get('/B551011/$serviceName/detailCommon2', {
        'contentId': contentId,
        'overviewYN': 'Y',
        'addrinfoYN': 'Y',
        'defaultYN': 'Y',
      });

      final items = _items(res.data);
      if (res.statusCode != 200 || items.isEmpty || items.first is! Map) {
        if (res.statusCode != 200) {
          _logApiError('$serviceName detailCommon2', res);
        }
        return null;
      }

      final item = Map<String, dynamic>.from(items.first as Map);
      final result = SpotInfoEN(
        overview: item['overview']?.toString() ?? '',
        addr: item['addr1']?.toString() ?? '',
        tel: item['tel']?.toString() ?? '',
        homepage: item['homepage']?.toString() ?? '',
        restdate: item['restdate']?.toString() ?? '',
        usetime: item['usetime']?.toString() ?? '',
        usefee: item['usefee']?.toString() ?? '',
      );
      await CacheService.set(cacheKey, _spotInfoToJson(result));
      return result;
    } catch (e) {
      debugPrint('Tour info error: $e');
      return CacheService.getStale<SpotInfoEN>(
        cacheKey,
        _spotInfoFromJson,
      );
    }
  }

  /// detailIntro2: 음식점/카페(39), 관광지(12) 모두 지원
  static Future<SpotIntroInfo?> fetchIntro(
    String contentId,
    String contentTypeId,
  ) async {
    if (contentId.isEmpty) return null;
    final cacheKey = 'tour:intro:$contentId:$contentTypeId';
    final cached = await CacheService.get<SpotIntroInfo>(
      cacheKey,
      CacheService.month,
      _introFromJson,
    );
    if (cached != null) return cached;
    try {
      final res = await _get('/B551011/KorService2/detailIntro2', {
        'contentId': contentId,
        'contentTypeId': contentTypeId,
      });

      final items = _items(res.data);
      if (res.statusCode != 200 || items.isEmpty || items.first is! Map) {
        if (res.statusCode != 200) _logApiError('detailIntro2', res);
        return null;
      }

      final item = Map<String, dynamic>.from(items.first as Map);

      SpotIntroInfo result;
      if (contentTypeId == '39') {
        // 음식점/카페
        final openRaw = item['opentimefood']?.toString() ?? '';
        final restRaw = item['restdatefood']?.toString() ?? '';
        final menu1 = item['firstmenu']?.toString() ?? '';
        final menu2 = item['treatmenu']?.toString() ?? '';
        result = SpotIntroInfo(
          openTime: openRaw,
          restDate: restRaw,
          menu: menu1.isNotEmpty ? menu1 : menu2,
        );
      } else {
        // 관광지 (12) 및 기타
        final openRaw = (item['usetimefestival']?.toString() ??
                item['opentime']?.toString() ??
                item['usetime']?.toString() ??
                '')
            .toString();
        final restRaw = item['restdate2']?.toString() ??
            item['restdateholiday']?.toString() ??
            '';
        final fee = item['usefee']?.toString() ?? '';
        result = SpotIntroInfo(
          openTime: openRaw,
          restDate: restRaw,
          useFee: fee,
        );
      }

      await CacheService.set(cacheKey, _introToJson(result));
      return result;
    } catch (e) {
      debugPrint('detailIntro2 error: $e');
      return CacheService.getStale<SpotIntroInfo>(cacheKey, _introFromJson);
    }
  }

  static Future<List<RelatedSpot>> fetchRelated(String contentId) async {
    try {
      final res = await _get(
        '/B551011/TourSpotsDataLabService1/getRltdTuristSpotsInfo',
        {
          'contentId': contentId,
          'areaCode': '39',
          'numOfRows': '10',
          'pageNo': '1',
        },
      );

      if (res.statusCode != 200) {
        _logApiError('Tour related spots', res);
        return [];
      }

      return _items(res.data).whereType<Map>().map((e) {
        final item = Map<String, dynamic>.from(e);
        return RelatedSpot(
          contentId: item['rltdContentId']?.toString() ?? '',
          title: item['rltdTitle']?.toString() ?? '',
          imageUrl: _httpsImageUrl(item['rltdFirstImage']?.toString() ?? ''),
        );
      }).toList();
    } catch (e) {
      debugPrint('Tour related spots error: $e');
      return [];
    }
  }

  static Future<int?> fetchCrowdIndex(String contentId) async {
    try {
      final res = await _get('/B551011/DataLabService1/areaBasedList1', {
        'contentId': contentId,
        'numOfRows': '1',
        'pageNo': '1',
      });

      final items = _items(res.data);
      if (res.statusCode != 200 || items.isEmpty || items.first is! Map) {
        if (res.statusCode != 200) _logApiError('Tour crowd index', res);
        return null;
      }

      final item = Map<String, dynamic>.from(items.first as Map);
      return int.tryParse(item['concentrationIndex']?.toString() ?? '');
    } catch (e) {
      debugPrint('Tour crowd index error: $e');
      return null;
    }
  }

  static Future<List<TourPlace>> fetchWeatherSpots({
    required bool isBadWeather,
    int numOfRows = 20,
    String language = 'ko',
  }) {
    return fetchPlaces(
      PlaceType.tourist,
      numOfRows: numOfRows,
      language: language,
    );
  }
}

String _serviceName(String language) {
  return 'KorService2';
}

String _sourceLanguage(String language) {
  return 'ko';
}

String _touristContentTypeId(String language) {
  return '12';
}

String _foodContentTypeId(String language) {
  return '39';
}

bool _isPlaceTypeMatch(TourPlace place, PlaceType type, String language) {
  return true;
}

List<Map<String, dynamic>> _placesToJson(List<TourPlace> places) {
  return places.map((place) => place.toJson()).toList();
}

List<TourPlace> _placesFromJson(dynamic json) {
  final list = json as List;
  return list
      .whereType<Map>()
      .map((place) => TourPlace.fromCached(Map<String, dynamic>.from(place)))
      .toList();
}

Map<String, dynamic> _spotInfoToJson(SpotInfoEN info) {
  return {
    'overview': info.overview,
    'addr': info.addr,
    'tel': info.tel,
    'homepage': info.homepage,
    'restdate': info.restdate,
    'usetime': info.usetime,
    'usefee': info.usefee,
  };
}

SpotInfoEN _spotInfoFromJson(dynamic json) {
  final map = Map<String, dynamic>.from(json as Map);
  return SpotInfoEN(
    overview: map['overview']?.toString() ?? '',
    addr: map['addr']?.toString() ?? '',
    tel: map['tel']?.toString() ?? '',
    homepage: map['homepage']?.toString() ?? '',
    restdate: map['restdate']?.toString() ?? '',
    usetime: map['usetime']?.toString() ?? '',
    usefee: map['usefee']?.toString() ?? '',
  );
}

Map<String, dynamic> _introToJson(SpotIntroInfo info) => {
      'openTime': info.openTime,
      'restDate': info.restDate,
      'menu': info.menu,
      'useFee': info.useFee,
    };

SpotIntroInfo _introFromJson(dynamic json) {
  final map = Map<String, dynamic>.from(json as Map);
  return SpotIntroInfo(
    openTime: map['openTime']?.toString() ?? '',
    restDate: map['restDate']?.toString() ?? '',
    menu: map['menu']?.toString() ?? '',
    useFee: map['useFee']?.toString() ?? '',
  );
}

String _httpsImageUrl(String url) {
  if (url.startsWith('http://tong.visitkorea.or.kr/')) {
    return url.replaceFirst('http://', 'https://');
  }
  return url;
}
