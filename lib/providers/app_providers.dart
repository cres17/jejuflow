import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'dart:math' as math;
import '../core/models/spot.dart';
import '../core/models/weather.dart';
import '../core/models/bus_arrival.dart';
import '../core/models/saved_route.dart';
import '../core/models/crowd_data.dart';
import '../core/models/place.dart';
import '../core/constants/colors.dart';
import '../core/constants/spot_data.dart';
import '../core/services/weather_service.dart';
import '../core/services/transit_service.dart';
import '../core/services/tour_service.dart';
import '../core/services/color_extract_service.dart';
import '../core/utils/location_utils.dart';
import '../core/utils/weather_utils.dart';

// ???1 Tab Index (for cross-tab navigation) ??????????????????????
final tabIndexProvider = StateProvider<int>((ref) => 0);

final routeDraftProvider = StateProvider<List<Spot>>((ref) => []);
// spotId -> scheduled DateTime set when user swipes up to add
final routeDraftScheduleProvider =
    StateProvider<Map<String, DateTime>>((ref) => {});
final skippedSpotIdsProvider = StateProvider<Set<String>>((ref) => {});
final appOpenSeedProvider =
    StateProvider<int>((ref) => DateTime.now().millisecondsSinceEpoch);

// Browse filter state – survives navigation back from spot detail
class BrowseFilter {
  final String kind;
  final String tourismStyle;
  final String oreum;
  final String foodStyle;
  final String cafeStyle;
  final String query;
  const BrowseFilter({
    this.kind = 'spots',
    this.tourismStyle = 'all',
    this.oreum = 'all',
    this.foodStyle = 'all',
    this.cafeStyle = 'all',
    this.query = '',
  });
  BrowseFilter copyWith({
    String? kind,
    String? tourismStyle,
    String? oreum,
    String? foodStyle,
    String? cafeStyle,
    String? query,
  }) =>
      BrowseFilter(
        kind: kind ?? this.kind,
        tourismStyle: tourismStyle ?? this.tourismStyle,
        oreum: oreum ?? this.oreum,
        foodStyle: foodStyle ?? this.foodStyle,
        cafeStyle: cafeStyle ?? this.cafeStyle,
        query: query ?? this.query,
      );
}

final browseFilterProvider =
    StateProvider<BrowseFilter>((ref) => const BrowseFilter());

enum AppLanguage { ko, en, ja, zh }

AppLanguage _languageFromCode(String? code) {
  return AppLanguage.values.firstWhere(
    (language) => language.name == code,
    orElse: () => AppLanguage.en,
  );
}

final appLanguageProvider = StateProvider<AppLanguage>((ref) {
  return _languageFromCode(Hive.box<String>('cache').get('app:language'));
});

final languageSelectedProvider = StateProvider<bool>((ref) {
  return Hive.box<String>('cache').get('app:languageSelected') == 'true';
});

Future<void> persistAppLanguage(WidgetRef ref, AppLanguage language) async {
  ref.read(appLanguageProvider.notifier).state = language;
  ref.read(languageSelectedProvider.notifier).state = true;
  final box = Hive.box<String>('cache');
  await box.put('app:language', language.name);
  await box.put('app:languageSelected', 'true');
}

String tr(AppLanguage lang, String key) {
  const values = {
    'now': {
      AppLanguage.ko: '지금',
      AppLanguage.en: 'Now',
      AppLanguage.ja: '今',
      AppLanguage.zh: '现在'
    },
    'move': {
      AppLanguage.ko: '탐색',
      AppLanguage.en: 'Move',
      AppLanguage.ja: '探す',
      AppLanguage.zh: '移动'
    },
    'routes': {
      AppLanguage.ko: '일정',
      AppLanguage.en: 'Routes',
      AppLanguage.ja: '日程',
      AppLanguage.zh: '行程'
    },
    'settings': {
      AppLanguage.ko: '설정',
      AppLanguage.en: 'Settings',
      AppLanguage.ja: '設定',
      AppLanguage.zh: '设置'
    },
    'todayFlow': {
      AppLanguage.ko: '오늘의 추천',
      AppLanguage.en: "Today's flow",
      AppLanguage.ja: '今日のおすすめ',
      AppLanguage.zh: '今日推荐'
    },
    'dragHint': {
      AppLanguage.ko: '위로 올려 추가, 아래로 내려 넘기기',
      AppLanguage.en: 'Drag up to add. Drag down to skip.',
      AppLanguage.ja: '上へドラッグで追加、下へドラッグでスキップ',
      AppLanguage.zh: '向上拖动添加，向下拖动跳过'
    },
    'addQuestion': {
      AppLanguage.ko: '이 장소를 일정에 추가할까요?',
      AppLanguage.en: 'Add this spot to your route?',
      AppLanguage.ja: 'この場所を日程に追加しますか？',
      AppLanguage.zh: '要把这个地点加入行程吗？'
    },
    'cancel': {
      AppLanguage.ko: '취소',
      AppLanguage.en: 'Cancel',
      AppLanguage.ja: 'キャンセル',
      AppLanguage.zh: '取消'
    },
    'add': {
      AppLanguage.ko: '추가',
      AppLanguage.en: 'Add',
      AppLanguage.ja: '追加',
      AppLanguage.zh: '添加'
    },
    'savedTrips': {
      AppLanguage.ko: '저장된 일정',
      AppLanguage.en: 'Saved Trips',
      AppLanguage.ja: '保存した日程',
      AppLanguage.zh: '已保存行程'
    },
    'planNewTrip': {
      AppLanguage.ko: '새 일정 만들기',
      AppLanguage.en: 'Plan New Trip',
      AppLanguage.ja: '新しい日程を作成',
      AppLanguage.zh: '创建新行程'
    },
    'selectDate': {
      AppLanguage.ko: '날짜 선택',
      AppLanguage.en: 'Select Date',
      AppLanguage.ja: '日付を選択',
      AppLanguage.zh: '选择日期'
    },
    'selectTime': {
      AppLanguage.ko: '시간 선택',
      AppLanguage.en: 'Select Time',
      AppLanguage.ja: '時間を選択',
      AppLanguage.zh: '选择时间'
    },
    'scheduleFor': {
      AppLanguage.ko: '일정 시간 설정',
      AppLanguage.en: 'Schedule for',
      AppLanguage.ja: '予定日時',
      AppLanguage.zh: '安排时间'
    },
    'skip': {
      AppLanguage.ko: '건너뛰기',
      AppLanguage.en: 'Skip',
      AppLanguage.ja: 'スキップ',
      AppLanguage.zh: '跳过'
    },
  };
  return values[key]?[lang] ?? values[key]?[AppLanguage.en] ?? key;
}

// ??? Region ????????????????????????????????????????????????????
final regionProvider = StateProvider<SpotRegion>((ref) => SpotRegion.jejuCity);

// ??? App Init ??????????????????????????????????????????????????
final appInitProvider = FutureProvider<void>((ref) async {
  final region = await detectRegion();
  ref.read(regionProvider.notifier).state = region;
  await ref.read(weatherProvider(region).future);
  await ref.read(savedRoutesProvider.notifier).load();
  final languageCode = tourLanguageCode(ref.read(appLanguageProvider));
  unawaited(Future.wait([
    TourService.fetchAllPlaces(
      PlaceType.tourist,
      numOfRows: 100,
      maxPages: 100,
      arrange: 'A',
      language: languageCode,
    ),
    TourService.fetchAllPlaces(
      PlaceType.restaurant,
      numOfRows: 100,
      maxPages: 100,
      arrange: 'A',
      language: languageCode,
    ),
  ]));
});

// ??? Weather ???????????????????????????????????????????????????
final weatherProvider =
    FutureProvider.family<WeatherData, SpotRegion>((ref, region) async {
  return WeatherService.fetchWeather(region);
});

final currentWeatherProvider = Provider<AsyncValue<WeatherData>>((ref) {
  final region = ref.watch(regionProvider);
  return ref.watch(weatherProvider(region));
});

// ??? Bus Arrivals ??????????????????????????????????????????????
final busArrivalsProvider =
    FutureProvider.family<List<BusArrival>, String>((ref, stopId) async {
  return TransitService.fetchArrivals(stopId);
});

// ??? Filtered Spots ????????????????????????????????????????????
final filteredSpotsProvider = Provider<List<Spot>>((ref) {
  final region = ref.watch(regionProvider);
  final weather = ref.watch(currentWeatherProvider).valueOrNull;
  final isBad = weather?.isBad ?? false;

  final local = kSpots
      .where((s) => s.region == region)
      .where((s) => isBad ? s.isIndoor : true)
      .toList();

  if (!isBad || local.length >= 3) return local;

  final backups = kSpots
      .where((s) => s.region != region)
      .where((s) => s.isIndoor)
      .where((s) => !local.any((existing) => existing.id == s.id));
  return [...local, ...backups];
});

// ??? Selected Spot (Move tab) ??????????????????????????????????
final selectedSpotProvider = StateProvider<Spot?>((ref) => null);

// ??? Spot Photos ???????????????????????????????????????????????
final spotPhotosProvider =
    FutureProvider.family<List<TourPhoto>, String>((ref, contentId) async {
  return TourService.fetchPhotos(contentId);
});

final spotPhotoUrlProvider = Provider.family<String?, String>((ref, spotId) {
  final spot = kSpotById[spotId];
  if (spot == null) return null;
  if (spot.contentId.isEmpty) return null;
  final photos = ref.watch(spotPhotosProvider(spot.contentId));
  return photos.valueOrNull?.firstOrNull?.originUrl;
});

// ??? Extracted Theme ???????????????????????????????????????????
final spotThemeProvider =
    FutureProvider.family<ExtractedTheme?, String>((ref, spotId) async {
  final photoUrl = ref.watch(spotPhotoUrlProvider(spotId));
  if (photoUrl == null || photoUrl.isEmpty) return null;
  return ColorExtractService.extract(spotId, photoUrl);
});

// ??? Spot Info EN ??????????????????????????????????????????????
final spotInfoProvider =
    FutureProvider.family<SpotInfoEN?, (String, String)>((ref, args) async {
  final (contentId, language) = args;
  if (contentId.isEmpty) return null;
  return TourService.fetchInfoEN(contentId, language: language);
});

// ??? Related Spots ?????????????????????????????????????????????
final relatedSpotsProvider =
    FutureProvider.family<List<RelatedSpot>, String>((ref, contentId) async {
  return TourService.fetchRelated(contentId);
});
// Spot Intro (detailIntro2: 음식점/카페 39, 관광지 12)
final spotIntroProvider =
    FutureProvider.family<SpotIntroInfo?, (String, String)>((ref, args) async {
  final (contentId, contentTypeId) = args;
  if (contentId.isEmpty) return null;
  return TourService.fetchIntro(contentId, contentTypeId);
});

// ??? Crowd Level ???????????????????????????????????????????????
final crowdProvider =
    FutureProvider.family<CrowdData?, String>((ref, contentId) async {
  final idx = await TourService.fetchCrowdIndex(contentId);
  if (idx == null) return null;
  return CrowdData(
      level: CrowdData.classify(idx), index: idx, updatedAt: DateTime.now());
});

// ??? Saved Routes ??????????????????????????????????????????????
class SavedRoutesNotifier extends AsyncNotifier<List<SavedRoute>> {
  static const _key = 'saved_routes';

  @override
  Future<List<SavedRoute>> build() async => [];

  Future<void> load() async {
    final box = Hive.box<String>('routes');
    final raws = box.get(_key);
    if (raws == null || raws.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    try {
      final list = (raws.split('||')).map(SavedRoute.fromJson).toList();
      state = AsyncData(list);
    } catch (_) {
      state = const AsyncData([]);
    }
  }

  Future<void> add(SavedRoute route) async {
    final current = state.valueOrNull ?? [];
    if (current.any((r) => r.id == route.id)) return;
    final updated = [route, ...current];
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> remove(String id) async {
    final updated = (state.valueOrNull ?? []).where((r) => r.id != id).toList();
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> reschedule(String id, DateTime scheduledAt) async {
    final updated = (state.valueOrNull ?? [])
        .map((route) =>
            route.id == id ? route.copyWith(savedAt: scheduledAt) : route)
        .toList();
    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = List<SavedRoute>.from(state.valueOrNull ?? []);
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = AsyncData(list);
    await _persist(list);
  }

  Future<void> _persist(List<SavedRoute> routes) async {
    final box = Hive.box<String>('routes');
    await box.put(_key, routes.map((r) => r.toJson()).join('||'));
  }
}

final savedRoutesProvider =
    AsyncNotifierProvider<SavedRoutesNotifier, List<SavedRoute>>(
  SavedRoutesNotifier.new,
);

// ??? Place List (API) ??????????????????????????????????????????
final placeListProvider = FutureProvider.family<List<TourPlace>, PlaceType>(
  (ref, type) async {
    final language = ref.watch(appLanguageProvider);
    final places = await TourService.fetchPlaces(
      type,
      language: tourLanguageCode(language),
    );
    if (places.isNotEmpty || type != PlaceType.tourist) return places;
    return _fallbackTourPlaces(ref.watch(regionProvider));
  },
);

// ??? Weather-based spots ???????????????????????????????????????
final weatherSpotsProvider = FutureProvider<List<TourPlace>>((ref) async {
  final isBad = ref.watch(currentWeatherProvider).valueOrNull?.isBad ?? false;
  final language = ref.watch(appLanguageProvider);
  final places = await TourService.fetchWeatherSpots(
    isBadWeather: isBad,
    numOfRows: 20,
    language: tourLanguageCode(language),
  );
  if (places.isNotEmpty) return places;
  final spots = ref.watch(filteredSpotsProvider);
  return spots.map(_spotToPlace).toList();
});

final allTouristSpotsProvider = FutureProvider<List<Spot>>((ref) async {
  return ref.watch(allPlaceSpotsProvider(PlaceType.tourist).future);
});

final allPlaceSpotsProvider =
    FutureProvider.family<List<Spot>, PlaceType>((ref, type) async {
  final language = ref.watch(appLanguageProvider);
  final languageCode = tourLanguageCode(language);
  final apiType = type == PlaceType.cafe ? PlaceType.restaurant : type;
  final places = await TourService.fetchAllPlaces(
    apiType,
    numOfRows: 100,
    maxPages: 100,
    arrange: 'A',
    language: languageCode,
  );
  final filteredPlaces = places.where((place) {
    if (type == PlaceType.cafe) return _looksLikeCafe(place);
    if (type == PlaceType.restaurant) return !_looksLikeCafe(place);
    return true;
  });
  final apiSpots = filteredPlaces
      .map((place) => _tourPlaceToSpot(place, type, language))
      .where((spot) => spot.contentId.isNotEmpty)
      .toList();
  if (apiSpots.isNotEmpty) return apiSpots;
  if (type != PlaceType.tourist) return const [];
  return kSpots;
});

final apiRecommendedSpotsProvider = FutureProvider<List<Spot>>((ref) async {
  final seed = ref.watch(appOpenSeedProvider);
  final draftIds = ref.watch(routeDraftProvider).map((spot) => spot.id).toSet();
  final skippedIds = ref.watch(skippedSpotIdsProvider);
  final language = ref.watch(appLanguageProvider);
  final languageCode = tourLanguageCode(language);
  final pageNo = seed % 5 + 1;
  final places = await Future.wait([
    TourService.fetchPlaces(
      PlaceType.tourist,
      pageNo: pageNo,
      numOfRows: 12,
      arrange: 'R',
      language: languageCode,
    ),
    TourService.fetchPlaces(
      PlaceType.restaurant,
      pageNo: pageNo,
      numOfRows: 8,
      arrange: 'R',
      language: languageCode,
    ),
    TourService.fetchPlaces(
      PlaceType.cafe,
      pageNo: pageNo + 1,
      numOfRows: 6,
      arrange: 'R',
      language: languageCode,
    ),
  ]);
  final random = math.Random(seed);
  final mapped = [
    ...places[0]
        .map((place) => _tourPlaceToSpot(place, PlaceType.tourist, language)),
    ...places[1].map(
        (place) => _tourPlaceToSpot(place, PlaceType.restaurant, language)),
    ...places[2]
        .map((place) => _tourPlaceToSpot(place, PlaceType.cafe, language)),
  ]
      .where((spot) => spot.contentId.isNotEmpty)
      .where((spot) => !draftIds.contains(spot.id))
      .where((spot) => !skippedIds.contains(spot.id))
      .where((spot) => !kSpotById.containsKey(spot.id))
      .toList()
    ..shuffle(random);
  return mapped.take(20).toList();
});

String tourLanguageCode(AppLanguage language) {
  return 'ko';
}

String weatherLabelFor(AppLanguage language, WeatherCondition condition) {
  return switch (condition) {
    WeatherCondition.clear => switch (language) {
        AppLanguage.ko => '맑음',
        AppLanguage.en => 'Clear',
        AppLanguage.ja => '晴れ',
        AppLanguage.zh => '晴朗',
      },
    WeatherCondition.cloudy => switch (language) {
        AppLanguage.ko => '흐림',
        AppLanguage.en => 'Cloudy',
        AppLanguage.ja => 'くもり',
        AppLanguage.zh => '多云',
      },
    WeatherCondition.rain => switch (language) {
        AppLanguage.ko => '비',
        AppLanguage.en => 'Rain',
        AppLanguage.ja => '雨',
        AppLanguage.zh => '下雨',
      },
    WeatherCondition.windy => switch (language) {
        AppLanguage.ko => '강풍',
        AppLanguage.en => 'Strong Wind',
        AppLanguage.ja => '強風',
        AppLanguage.zh => '强风',
      },
    WeatherCondition.storm => switch (language) {
        AppLanguage.ko => '폭풍',
        AppLanguage.en => 'Storm',
        AppLanguage.ja => '嵐',
        AppLanguage.zh => '暴风雨',
      },
  };
}

String regionLabelFor(AppLanguage language, SpotRegion region) {
  return switch (region) {
    SpotRegion.jejuCity => switch (language) {
        AppLanguage.ko => '제주시',
        AppLanguage.en => 'Jeju City',
        AppLanguage.ja => '済州市',
        AppLanguage.zh => '济州市',
      },
    SpotRegion.seogwipo => switch (language) {
        AppLanguage.ko => '서귀포시',
        AppLanguage.en => 'Seogwipo',
        AppLanguage.ja => '西帰浦市',
        AppLanguage.zh => '西归浦市',
      },
  };
}

String spotDisplayName(Spot spot, AppLanguage language) {
  if (spot.tags.contains('api')) {
    return localizeKoreanTourText(spot.nameEn, language, titleCase: true);
  }
  return _spotText[spot.id]?[language]?.$1 ?? spot.nameEn;
}

String spotDisplayDescription(Spot spot, AppLanguage language) {
  if (spot.tags.contains('api')) {
    final localized = localizeKoreanTourText(spot.sub, language);
    if (localized.isNotEmpty) return localized;
  }
  if (spot.tags.contains('restaurant')) {
    if (spot.sub.isNotEmpty) return spot.sub;
    return switch (language) {
      AppLanguage.ko => '제주에서 추천하는 음식점입니다.',
      AppLanguage.en => 'Recommended Jeju restaurant',
      AppLanguage.ja => '済州のおすすめ飲食店です。',
      AppLanguage.zh => '济州推荐餐厅。',
    };
  }
  if (spot.tags.contains('cafe')) {
    if (spot.sub.isNotEmpty) return spot.sub;
    return switch (language) {
      AppLanguage.ko => '제주에서 추천하는 카페입니다.',
      AppLanguage.en => 'Recommended Jeju cafe',
      AppLanguage.ja => '済州のおすすめカフェです。',
      AppLanguage.zh => '济州推荐咖啡馆。',
    };
  }
  return _spotText[spot.id]?[language]?.$2 ?? spot.sub;
}

String tourPlaceDisplayTitle(TourPlace place, AppLanguage language) {
  return localizeKoreanTourText(place.title, language, titleCase: true);
}

String tourPlaceDisplayAddress(TourPlace place, AppLanguage language) {
  return localizeKoreanTourText(place.addr, language);
}

String localizeKoreanTourText(
  String raw,
  AppLanguage language, {
  bool titleCase = false,
}) {
  final text = raw.trim();
  if (text.isEmpty || language == AppLanguage.ko) return text;

  var localized = text;
  for (final entry in _tourTextTerms(language).entries) {
    localized = localized.replaceAll(entry.key, entry.value);
  }
  localized = switch (language) {
    AppLanguage.en => _romanizeRemainingKorean(localized),
    AppLanguage.ja => _katakanaRemainingKorean(localized),
    AppLanguage.zh => localized,
    AppLanguage.ko => localized,
  };
  localized = localized
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(' ,', ',')
      .replaceAll('( ', '(')
      .replaceAll(' )', ')')
      .trim();

  return titleCase && language == AppLanguage.en
      ? _titleCaseEnglish(localized)
      : localized;
}

String localizeKoreanTourField(
  String raw,
  AppLanguage language, {
  required TourTextField field,
}) {
  final text = _normalizeKoreanTourField(raw);
  if (text.isEmpty || language == AppLanguage.ko) return text;

  var localized = text;
  final terms = switch (language) {
    AppLanguage.en => _tourFieldTermsEn,
    AppLanguage.ja => _tourFieldTermsJa,
    AppLanguage.zh => _tourFieldTermsZh,
    AppLanguage.ko => const <String, String>{},
  };
  for (final entry in terms.entries) {
    localized = localized.replaceAll(entry.key, entry.value);
  }

  final fallback = localizeKoreanTourText(localized, language);
  if (field == TourTextField.menu && fallback == localized) {
    return switch (language) {
      AppLanguage.en => fallback,
      AppLanguage.ja => _katakanaRemainingKorean(fallback),
      AppLanguage.zh => fallback,
      AppLanguage.ko => fallback,
    };
  }
  return fallback;
}

enum TourTextField { hours, lastOrder, breakTime, menu, fee, closedDay }

String _normalizeKoreanTourField(String raw) {
  return raw
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

const _tourFieldTermsEn = {
  '준비시간': 'Break time',
  '브레이크타임': 'Break time',
  '브레이크 타임': 'Break time',
  '라스트오더': 'Last order',
  '라스트 오더': 'Last order',
  '마지막 주문': 'Last order',
  '대표메뉴': 'Signature menu',
  '대표 메뉴': 'Signature menu',
  '주요메뉴': 'Main menu',
  '주요 메뉴': 'Main menu',
  '영업시간': 'Opening hours',
  '운영시간': 'Opening hours',
  '이용시간': 'Opening hours',
  '휴무일': 'Closed days',
  '휴무': 'Closed',
  '정기휴무': 'Regular closing day',
  '연중무휴': 'Open year-round',
  '매일': 'Daily',
  '없음': 'None',
  '문의': 'Ask before visiting',
  '전화문의': 'Call before visiting',
  '입장료': 'Admission',
  '이용요금': 'Fee',
  '무료': 'Free',
  '유료': 'Paid',
};

const _tourFieldTermsJa = {
  '준비시간': '休憩時間',
  '브레이크타임': '休憩時間',
  '브레이크 타임': '休憩時間',
  '라스트오더': 'ラストオーダー',
  '라스트 오더': 'ラストオーダー',
  '마지막 주문': 'ラストオーダー',
  '대표메뉴': '代表メニュー',
  '대표 메뉴': '代表メニュー',
  '주요메뉴': '主なメニュー',
  '주요 메뉴': '主なメニュー',
  '영업시간': '営業時間',
  '운영시간': '営業時間',
  '이용시간': '利用時間',
  '휴무일': '休業日',
  '휴무': '休業',
  '정기휴무': '定休日',
  '연중무휴': '年中無休',
  '매일': '毎日',
  '없음': 'なし',
  '문의': '訪問前に確認',
  '전화문의': '電話で確認',
  '입장료': '入場料',
  '이용요금': '利用料金',
  '무료': '無料',
  '유료': '有料',
};

const _tourFieldTermsZh = {
  '준비시간': '休息时间',
  '브레이크타임': '休息时间',
  '브레이크 타임': '休息时间',
  '라스트오더': '最后点餐',
  '라스트 오더': '最后点餐',
  '마지막 주문': '最后点餐',
  '대표메뉴': '招牌菜单',
  '대표 메뉴': '招牌菜单',
  '주요메뉴': '主要菜单',
  '주요 메뉴': '主要菜单',
  '영업시간': '营业时间',
  '운영시간': '营业时间',
  '이용시간': '开放时间',
  '휴무일': '休息日',
  '휴무': '休息',
  '정기휴무': '定期休息',
  '연중무휴': '全年无休',
  '매일': '每天',
  '없음': '无',
  '문의': '访问前请确认',
  '전화문의': '请电话咨询',
  '입장료': '门票',
  '이용요금': '费用',
  '무료': '免费',
  '유료': '收费',
};

Map<String, String> _tourTextTerms(AppLanguage language) {
  return switch (language) {
    AppLanguage.en => _tourTermsEn,
    AppLanguage.ja => _tourTermsJa,
    AppLanguage.zh => _tourTermsZh,
    AppLanguage.ko => const {},
  };
}

const _tourTermsEn = {
  '제주특별자치도': 'Jeju-do',
  '서귀포시': 'Seogwipo',
  '제주시': 'Jeju City',
  '제주': 'Jeju',
  '중문': 'Jungmun',
  '성산': 'Seongsan',
  '애월': 'Aewol',
  '한림': 'Hallim',
  '구좌': 'Gujwa',
  '표선': 'Pyoseon',
  '대정': 'Daejeong',
  '안덕': 'Andeok',
  '조천': 'Jocheon',
  '우도': 'Udo',
  '오름': ' Oreum',
  '해수욕장': ' Beach',
  '해변': ' Beach',
  '폭포': ' Waterfall',
  '박물관': ' Museum',
  '미술관': ' Art Museum',
  '수목원': ' Arboretum',
  '공원': ' Park',
  '테마파크': ' Theme Park',
  '동굴': ' Cave',
  '숲': ' Forest',
  '정원': ' Garden',
  '시장': ' Market',
  '거리': ' Street',
  '마을': ' Village',
  '등대': ' Lighthouse',
  '포구': ' Port',
  '항': ' Port',
  '사찰': ' Temple',
  '절': ' Temple',
  '카페': ' Cafe',
  '커피': ' Coffee',
  '베이커리': ' Bakery',
  '디저트': ' Dessert',
  '식당': ' Restaurant',
  '음식점': ' Restaurant',
  '맛집': ' Restaurant',
  '횟집': ' Raw Fish Restaurant',
  '흑돼지': ' Black Pork',
  '고기국수': ' Pork Noodles',
  '국수': ' Noodles',
  '해장국': ' Hangover Soup',
  '해물': ' Seafood',
  '갈치': ' Cutlassfish',
  '전복': ' Abalone',
  '김밥': ' Gimbap',
  '분식': ' Snack Bar',
  '무료': ' Free',
  '유료': ' Paid',
  '어른': ' Adult',
  '성인': ' Adult',
  '청소년': ' Teen',
  '어린이': ' Child',
  '매일': ' Daily',
  '연중무휴': ' Open year-round',
  '휴무': ' Closed',
  '월요일': ' Monday',
  '화요일': ' Tuesday',
  '수요일': ' Wednesday',
  '목요일': ' Thursday',
  '금요일': ' Friday',
  '토요일': ' Saturday',
  '일요일': ' Sunday',
  '이용시간': ' Hours',
  '입장료': ' Admission',
  '본점': ' Main Branch',
  '제주점': ' Jeju Branch',
  '중문점': ' Jungmun Branch',
  '성산점': ' Seongsan Branch',
  '로 ': '-ro ',
  '길 ': '-gil ',
};

const _tourTermsJa = {
  '제주특별자치도': '済州特別自治道',
  '서귀포시': '西帰浦市',
  '제주시': '済州市',
  '제주': '済州',
  '중문': '中文',
  '성산': '城山',
  '애월': '涯月',
  '한림': '翰林',
  '구좌': '旧左',
  '표선': '表善',
  '대정': '大静',
  '안덕': '安徳',
  '조천': '朝天',
  '우도': '牛島',
  '오름': ' オルム',
  '해수욕장': ' 海水浴場',
  '해변': ' 海辺',
  '폭포': ' 滝',
  '박물관': ' 博物館',
  '미술관': ' 美術館',
  '수목원': ' 樹木園',
  '공원': ' 公園',
  '테마파크': ' テーマパーク',
  '동굴': ' 洞窟',
  '숲': ' 森',
  '정원': ' 庭園',
  '시장': ' 市場',
  '거리': ' 通り',
  '마을': ' 村',
  '등대': ' 灯台',
  '포구': ' 港',
  '항': ' 港',
  '사찰': ' 寺院',
  '절': ' 寺',
  '카페': ' カフェ',
  '커피': ' コーヒー',
  '베이커리': ' ベーカリー',
  '디저트': ' デザート',
  '식당': ' 食堂',
  '음식점': ' レストラン',
  '맛집': ' グルメ店',
  '횟집': ' 刺身店',
  '흑돼지': ' 黒豚',
  '고기국수': ' 肉麺',
  '국수': ' 麺',
  '해장국': ' ヘジャングク',
  '해물': ' 海鮮',
  '갈치': ' 太刀魚',
  '전복': ' アワビ',
  '김밥': ' キンパ',
  '분식': ' 軽食',
  '무료': ' 無料',
  '유료': ' 有料',
  '어른': ' 大人',
  '성인': ' 大人',
  '청소년': ' 青少年',
  '어린이': ' 子ども',
  '매일': ' 毎日',
  '연중무휴': ' 年中無休',
  '휴무': ' 休業',
  '월요일': ' 月曜日',
  '화요일': ' 火曜日',
  '수요일': ' 水曜日',
  '목요일': ' 木曜日',
  '금요일': ' 金曜日',
  '토요일': ' 土曜日',
  '일요일': ' 日曜日',
  '이용시간': ' 利用時間',
  '입장료': ' 入場料',
  '본점': ' 本店',
  '제주점': ' 済州店',
  '중문점': ' 中文店',
  '성산점': ' 城山店',
};

const _tourTermsZh = {
  '제주특별자치도': '济州特别自治道',
  '서귀포시': '西归浦市',
  '제주시': '济州市',
  '제주': '济州',
  '중문': '中文',
  '성산': '城山',
  '애월': '涯月',
  '한림': '翰林',
  '구좌': '旧左',
  '표선': '表善',
  '대정': '大静',
  '안덕': '安德',
  '조천': '朝天',
  '우도': '牛岛',
  '오름': ' 火山丘',
  '해수욕장': ' 海水浴场',
  '해변': ' 海边',
  '폭포': ' 瀑布',
  '박물관': ' 博物馆',
  '미술관': ' 美术馆',
  '수목원': ' 树木园',
  '공원': ' 公园',
  '테마파크': ' 主题公园',
  '동굴': ' 洞窟',
  '숲': ' 森林',
  '정원': ' 庭园',
  '시장': ' 市场',
  '거리': ' 街',
  '마을': ' 村',
  '등대': ' 灯塔',
  '포구': ' 港口',
  '항': ' 港',
  '사찰': ' 寺庙',
  '절': ' 寺',
  '카페': ' 咖啡馆',
  '커피': ' 咖啡',
  '베이커리': ' 烘焙店',
  '디저트': ' 甜品',
  '식당': ' 餐厅',
  '음식점': ' 餐厅',
  '맛집': ' 美食店',
  '횟집': ' 生鱼片店',
  '흑돼지': ' 黑猪肉',
  '고기국수': ' 肉面',
  '국수': ' 面条',
  '해장국': ' 醒酒汤',
  '해물': ' 海鲜',
  '갈치': ' 带鱼',
  '전복': ' 鲍鱼',
  '김밥': ' 紫菜包饭',
  '분식': ' 小吃',
  '무료': ' 免费',
  '유료': ' 收费',
  '어른': ' 成人',
  '성인': ' 成人',
  '청소년': ' 青少年',
  '어린이': ' 儿童',
  '매일': ' 每天',
  '연중무휴': ' 全年无休',
  '휴무': ' 休息',
  '월요일': ' 星期一',
  '화요일': ' 星期二',
  '수요일': ' 星期三',
  '목요일': ' 星期四',
  '금요일': ' 星期五',
  '토요일': ' 星期六',
  '일요일': ' 星期日',
  '이용시간': ' 开放时间',
  '입장료': ' 门票',
  '본점': ' 总店',
  '제주점': ' 济州店',
  '중문점': ' 中文店',
  '성산점': ' 城山店',
};

String _romanizeRemainingKorean(String text) {
  final buffer = StringBuffer();
  var previousWasRomanized = false;
  for (final rune in text.runes) {
    final romanized = _romanizeHangulSyllable(rune);
    if (romanized == null) {
      buffer.write(String.fromCharCode(rune));
      previousWasRomanized = false;
      continue;
    }
    if (!previousWasRomanized &&
        buffer.isNotEmpty &&
        !buffer.toString().endsWith(' ') &&
        !buffer.toString().endsWith('(')) {
      buffer.write(' ');
    }
    buffer.write(romanized);
    previousWasRomanized = true;
  }
  return buffer.toString();
}

String _katakanaRemainingKorean(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    buffer.write(_hangulSyllableToKatakana(rune) ?? String.fromCharCode(rune));
  }
  return buffer.toString();
}

String? _hangulSyllableToKatakana(int rune) {
  final romanized = _romanizeHangulSyllable(rune);
  if (romanized == null) return null;
  var kana = romanized;
  const replacements = {
    'kk': 'ッカ',
    'tt': 'ッタ',
    'pp': 'ッパ',
    'ss': 'ッサ',
    'jj': 'ッチャ',
    'ch': 'チャ',
    'ng': 'ン',
    'g': 'ガ',
    'n': 'ン',
    'd': 'ダ',
    'r': 'ラ',
    'm': 'ム',
    'b': 'バ',
    's': 'サ',
    'j': 'ジャ',
    'k': 'カ',
    't': 'タ',
    'p': 'パ',
    'h': 'ハ',
    'yae': 'イェ',
    'ya': 'ヤ',
    'yeo': 'ヨ',
    'ye': 'イェ',
    'wae': 'ウェ',
    'wa': 'ワ',
    'wo': 'ウォ',
    'we': 'ウェ',
    'wi': 'ウィ',
    'ae': 'エ',
    'eo': 'オ',
    'oe': 'ウェ',
    'yo': 'ヨ',
    'yu': 'ユ',
    'eu': 'ウ',
    'ui': 'ウィ',
    'a': 'ア',
    'e': 'エ',
    'o': 'オ',
    'u': 'ウ',
    'i': 'イ',
  };
  for (final entry in replacements.entries) {
    kana = kana.replaceAll(entry.key, entry.value);
  }
  return kana;
}

String? _romanizeHangulSyllable(int rune) {
  if (rune < 0xAC00 || rune > 0xD7A3) return null;
  const initial = [
    'g',
    'kk',
    'n',
    'd',
    'tt',
    'r',
    'm',
    'b',
    'pp',
    's',
    'ss',
    '',
    'j',
    'jj',
    'ch',
    'k',
    't',
    'p',
    'h'
  ];
  const vowel = [
    'a',
    'ae',
    'ya',
    'yae',
    'eo',
    'e',
    'yeo',
    'ye',
    'o',
    'wa',
    'wae',
    'oe',
    'yo',
    'u',
    'wo',
    'we',
    'wi',
    'yu',
    'eu',
    'ui',
    'i'
  ];
  const finalConsonant = [
    '',
    'k',
    'k',
    'ks',
    'n',
    'nj',
    'nh',
    't',
    'l',
    'lk',
    'lm',
    'lb',
    'ls',
    'lt',
    'lp',
    'lh',
    'm',
    'p',
    'ps',
    't',
    't',
    'ng',
    't',
    't',
    'k',
    't',
    'p',
    't'
  ];

  final offset = rune - 0xAC00;
  final l = offset ~/ 588;
  final v = (offset % 588) ~/ 28;
  final t = offset % 28;
  return '${initial[l]}${vowel[v]}${finalConsonant[t]}';
}

String _titleCaseEnglish(String text) {
  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    if (word.length <= 2 && word == word.toUpperCase()) return word;
    return '${word[0].toUpperCase()}${word.substring(1)}';
  }).join(' ');
}

const _spotText = <String, Map<AppLanguage, (String, String)>>{
  'seongsan-ilchulbong': {
    AppLanguage.ko: ('성산일출봉', '유네스코 화산 분화구와 일출 명소'),
    AppLanguage.en: ('Seongsan Sunrise Peak', 'UNESCO volcanic crater'),
    AppLanguage.ja: ('城山日出峰', 'ユネスコ火山火口と日の出の名所'),
    AppLanguage.zh: ('城山日出峰', '联合国教科文组织火山口与日出名胜'),
  },
  'hallim-park': {
    AppLanguage.ko: ('한림공원', '아열대 정원과 동굴을 함께 보는 공원'),
    AppLanguage.en: ('Hallim Park', 'Subtropical garden and caves'),
    AppLanguage.ja: ('翰林公園', '亜熱帯庭園と洞窟を楽しめる公園'),
    AppLanguage.zh: ('翰林公园', '亚热带庭园与洞窟'),
  },
  'manjanggul-cave': {
    AppLanguage.ko: ('만장굴', '세계적으로 긴 용암동굴'),
    AppLanguage.en: (
      'Manjanggul Lava Tube',
      "One of the world's longest lava tubes"
    ),
    AppLanguage.ja: ('万丈窟', '世界有数の長い溶岩洞窟'),
    AppLanguage.zh: ('万丈窟', '世界知名的长型熔岩洞窟'),
  },
  'cheonjiyeon-falls': {
    AppLanguage.ko: ('천지연폭포', '밤 산책도 좋은 서귀포 폭포'),
    AppLanguage.en: ('Cheonjiyeon Waterfall', 'Night-friendly waterfall walk'),
    AppLanguage.ja: ('天地淵瀑布', '夜の散策にも良い滝'),
    AppLanguage.zh: ('天地渊瀑布', '适合夜间散步的瀑布'),
  },
  'hyeopjae-beach': {
    AppLanguage.ko: ('협재해수욕장', '에메랄드빛 바다와 하얀 모래'),
    AppLanguage.en: ('Hyeopjae Beach', 'Emerald water and white sand'),
    AppLanguage.ja: ('挟才海水浴場', 'エメラルド色の海と白い砂浜'),
    AppLanguage.zh: ('挟才海水浴场', '翡翠海水与白色沙滩'),
  },
  'seopjikoji': {
    AppLanguage.ko: ('섭지코지', '유채꽃과 등대가 있는 해안 산책지'),
    AppLanguage.en: ('Seopjikoji Cape', 'Canola fields and lighthouse'),
    AppLanguage.ja: ('ソプジコジ', '菜の花畑と灯台のある岬'),
    AppLanguage.zh: ('涉地可支', '油菜花田与灯塔海岬'),
  },
  'haenyeo-museum': {
    AppLanguage.ko: ('해녀박물관', '제주 해녀 문화와 유네스코 유산'),
    AppLanguage.en: (
      'Haenyeo Museum',
      'Female diver culture and UNESCO heritage'
    ),
    AppLanguage.ja: ('海女博物館', '済州海女文化とユネスコ遺産'),
    AppLanguage.zh: ('海女博物馆', '济州海女文化与非遗遗产'),
  },
  'bijarim-forest': {
    AppLanguage.ko: ('비자림', '오래된 비자나무 숲길'),
    AppLanguage.en: ('Bijarim Forest', 'Ancient nutmeg grove'),
    AppLanguage.ja: ('榧子林', '古い榧の森の散策路'),
    AppLanguage.zh: ('榧子林', '古老榧树林步道'),
  },
  'aqua-planet': {
    AppLanguage.ko: ('아쿠아플라넷 제주', '제주의 대형 아쿠아리움'),
    AppLanguage.en: ('Aqua Planet Jeju', "Korea's largest aquarium"),
    AppLanguage.ja: ('アクアプラネット済州', '済州の大型水族館'),
    AppLanguage.zh: ('济州Aqua Planet', '济州大型水族馆'),
  },
  'eco-land': {
    AppLanguage.ko: ('에코랜드 테마파크', '곶자왈 숲을 기차로 둘러보는 공원'),
    AppLanguage.en: ('Eco Land Theme Park', 'Train through Gotjawal forest'),
    AppLanguage.ja: ('エコランドテーマパーク', 'コッチャワルの森を列車で巡る公園'),
    AppLanguage.zh: ('生态乐园主题公园', '乘小火车游览森林'),
  },
  'yongduam-rock': {
    AppLanguage.ko: ('용두암', '제주항 근처의 용머리 모양 화산암'),
    AppLanguage.en: (
      'Yongduam Dragon Head Rock',
      'Volcanic rock near Jeju Port'
    ),
    AppLanguage.ja: ('龍頭岩', '済州港近くの龍の頭形の岩'),
    AppLanguage.zh: ('龙头岩', '济州港附近的龙头形火山岩'),
  },
  'sangumburi': {
    AppLanguage.ko: ('산굼부리', '넓은 초원과 분화구 산책'),
    AppLanguage.en: (
      'Sangumburi Crater',
      'Dormant crater with open grasslands'
    ),
    AppLanguage.ja: ('サングムブリ', '広い草原と火口散策'),
    AppLanguage.zh: ('山君不离', '开阔草原与火山口散步'),
  },
};
// ??? Time of day ???????????????????????????????????????????????
final timeOfDayProvider = Provider<TimeOfDay>((ref) => detectTimeOfDay());

List<TourPlace> _fallbackTourPlaces(SpotRegion region) {
  return kSpots
      .where((spot) => spot.region == region)
      .map(_spotToPlace)
      .toList();
}

TourPlace _spotToPlace(Spot spot) {
  return TourPlace(
    contentId: spot.contentId,
    contentTypeId: '12',
    title: spot.nameEn,
    addr: '${spot.nearestStop} stop',
    tel: '',
    imageUrl: '',
    thumbUrl: '',
    lat: spot.lat,
    lng: spot.lng,
  );
}

Spot _tourPlaceToSpot(TourPlace place, PlaceType type, AppLanguage language) {
  final lat = place.lat ?? 33.38;
  final lng = place.lng ?? 126.55;
  final hash = place.contentId.hashCode.abs();
  final typeTag = switch (type) {
    PlaceType.tourist => 'tourism',
    PlaceType.restaurant => 'restaurant',
    PlaceType.cafe => 'cafe',
  };
  final fallbackSub = switch ((type, language)) {
    (PlaceType.restaurant, AppLanguage.ko) => '제주 추천 음식점',
    (PlaceType.restaurant, AppLanguage.en) => 'Recommended Jeju restaurant',
    (PlaceType.restaurant, AppLanguage.ja) => '済州のおすすめ飲食店',
    (PlaceType.restaurant, AppLanguage.zh) => '济州推荐餐厅',
    (PlaceType.cafe, AppLanguage.ko) => '제주 추천 카페',
    (PlaceType.cafe, AppLanguage.en) => 'Recommended Jeju cafe',
    (PlaceType.cafe, AppLanguage.ja) => '済州のおすすめカフェ',
    (PlaceType.cafe, AppLanguage.zh) => '济州推荐咖啡馆',
    (_, AppLanguage.ko) => '제주 추천 관광지',
    (_, AppLanguage.en) => 'Jeju recommended spot',
    (_, AppLanguage.ja) => '済州のおすすめ観光地',
    (_, AppLanguage.zh) => '济州推荐景点',
  };
  return Spot(
    id: 'api-${place.contentId}',
    nameEn: place.title,
    emoji: '',
    sub: place.addr.isEmpty ? fallbackSub : place.addr,
    category:
        type == PlaceType.tourist ? SpotCategory.outdoor : SpotCategory.indoor,
    region: lat < 33.33 ? SpotRegion.seogwipo : SpotRegion.jejuCity,
    nearestStop: place.addr.isEmpty ? 'Nearby stop' : place.addr,
    stopId: '',
    busRoutes: ['KakaoMap'],
    walkMinutes: 5 + hash % 8,
    busWaitMinutes: 10 + hash % 18,
    bgColor: AppColors.greenBg,
    accentColor: AppColors.accent,
    fee: 0,
    hours: 'Check before visit',
    tags: ['api', typeTag, 'recommended'],
    altSpotId: null,
    contentId: place.contentId,
    lat: lat,
    lng: lng,
  )..photoUrl = place.displayImage;
}

bool _looksLikeCafe(TourPlace place) {
  if (place.cat3 == 'A05020900') return true;
  final text = [
    place.title,
    place.addr,
    place.cat1,
    place.cat2,
    place.cat3,
  ].join(' ').toLowerCase();
  return const [
    'cafe',
    'caf',
    'tea',
    'coffee',
    'bakery',
    'bread',
    'brunch',
    'roaster',
    'dessert',
    'cake',
    'donut',
    'roastery',
    '카페',
    '커피',
    '베이커리',
    '디저트',
    '다방',
    '찻집',
  ].any(text.contains);
}
