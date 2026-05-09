import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spot_data.dart';
import '../../core/models/place.dart';
import '../../core/models/spot.dart';
import '../../core/utils/jeju_map_projection.dart';
import '../../core/utils/route_utils.dart';
import '../../providers/app_providers.dart';
import '../../core/services/tour_service.dart';
import '../../shared/widgets/claude_ui.dart';
import '../../shared/widgets/place_card.dart';
import '../../shared/widgets/route_steps_widget.dart';

class MoveScreen extends ConsumerWidget {
  const MoveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spot = ref.watch(selectedSpotProvider);
    return spot == null ? const _BrowseView() : _SpotDetailScreen(spot: spot);
  }
}

IconData _categoryIcon(Spot spot) {
  if (spot.category == SpotCategory.indoor) return Icons.museum_rounded;
  if (spot.category == SpotCategory.both) return Icons.attractions_rounded;
  return Icons.terrain_rounded;
}

String _spotTransitLabel(AppLanguage lang, Spot spot) {
  final route = spot.busRoutes.isEmpty ? '' : spot.busRoutes.first;
  if (route.isEmpty || route.toLowerCase() == 'kakaomap') {
    return switch (lang) {
      AppLanguage.ko => '지도 확인',
      AppLanguage.en => 'Check map',
      AppLanguage.ja => '地図を確認',
      AppLanguage.zh => '查看地图',
    };
  }
  return switch (lang) {
    AppLanguage.ko => '버스 $route',
    AppLanguage.en => 'Bus $route',
    AppLanguage.ja => 'バス $route',
    AppLanguage.zh => '$route 路公交',
  };
}

String _spotTypeLabel(AppLanguage lang, Spot spot) {
  final tags = spot.tags.map((tag) => tag.toLowerCase()).toSet();
  final type = tags.contains('restaurant')
      ? 'restaurant'
      : tags.contains('cafe')
          ? 'cafe'
          : 'tourism';

  return switch ((lang, type)) {
    (AppLanguage.ko, 'restaurant') => '음식점',
    (AppLanguage.ko, 'cafe') => '카페',
    (AppLanguage.ko, _) => '관광지',
    (AppLanguage.ja, 'restaurant') => 'レストラン',
    (AppLanguage.ja, 'cafe') => 'カフェ',
    (AppLanguage.ja, _) => '観光地',
    (AppLanguage.zh, 'restaurant') => '餐厅',
    (AppLanguage.zh, 'cafe') => '咖啡馆',
    (AppLanguage.zh, _) => '景点',
    (AppLanguage.en, 'restaurant') => 'Restaurant',
    (AppLanguage.en, 'cafe') => 'Cafe',
    (AppLanguage.en, _) => 'Attraction',
  };
}

class _WeatherRouteWarning extends StatelessWidget {
  const _WeatherRouteWarning({required this.altSpot, required this.onSwitch});

  final Spot? altSpot;
  final VoidCallback? onSwitch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.yellowBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 18, color: AppColors.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Weather affected',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            altSpot == null
                ? 'This outdoor route may be uncomfortable right now.'
                : 'This outdoor route may be uncomfortable. ${altSpot!.nameEn} is a better indoor backup.',
            style: GoogleFonts.outfit(
                fontSize: 12, color: AppColors.text2, height: 1.35),
          ),
          if (altSpot != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: onSwitch,
                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                label: Text('Switch to ${altSpot!.nameEn}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tertiary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ?????? Browse: 3 tabs ????????????????????????????????????????????????????????????????????????????????????????
class _BrowseView extends ConsumerStatefulWidget {
  const _BrowseView();

  @override
  ConsumerState<_BrowseView> createState() => _BrowseViewState();
}

class _BrowseViewState extends ConsumerState<_BrowseView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _updateFilter(BrowseFilter f) =>
      ref.read(browseFilterProvider.notifier).state = f;

  @override
  Widget build(BuildContext context) {
    final f = ref.watch(browseFilterProvider);
    final selectedType = switch (f.kind) {
      'food' => PlaceType.restaurant,
      'cafe' => PlaceType.cafe,
      _ => PlaceType.tourist,
    };
    final apiSpots = ref.watch(allPlaceSpotsProvider(selectedType));
    final List<Spot> spots = apiSpots.valueOrNull ??
        (selectedType == PlaceType.tourist
            ? ref.watch(filteredSpotsProvider)
            : const <Spot>[]);
    final lang = ref.watch(appLanguageProvider);
    final list = spots.where((spot) {
      final query = f.query.trim().toLowerCase();
      if (query.isNotEmpty) {
        final haystack = [
          spotDisplayName(spot, lang),
          spotDisplayDescription(spot, lang),
          spot.nameEn,
          spot.sub,
          spot.nearestStop,
          ...spot.tags,
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      if (f.kind == 'oreum' && !_isOreum(spot)) return false;
      if (f.kind == 'spots' && _isOreum(spot)) return false;
      if (f.kind == 'spots' &&
          f.tourismStyle != 'all' &&
          !_matchesTourismStyle(spot, f.tourismStyle)) return false;
      if (f.kind == 'under30' && (spot.busWaitMinutes + spot.walkMinutes) > 30)
        return false;
      if (f.kind == 'food' &&
          f.foodStyle != 'all' &&
          !_matchesFoodStyle(spot, f.foodStyle)) return false;
      if (f.kind == 'cafe' &&
          f.cafeStyle != 'all' &&
          !_matchesCafeStyle(spot, f.cafeStyle)) return false;
      if (f.kind == 'oreum' && f.oreum == 'easy' && spot.walkMinutes > 20)
        return false;
      if (f.kind == 'oreum' && f.oreum == 'moderate' && spot.walkMinutes > 40)
        return false;
      if (f.kind == 'oreum' &&
          f.oreum == 'sunrise' &&
          !_matchesOreumStyle(spot, 'sunrise')) return false;
      if (f.kind == 'oreum' &&
          f.oreum == 'crater' &&
          !_matchesOreumStyle(spot, 'crater')) return false;
      // '뷰/전망': 정상에서 바다·섬이 보이는 오름
      if (f.kind == 'oreum' &&
          f.oreum == 'view' &&
          !_matchesOreumStyle(spot, 'view')) return false;
      // '접근 쉬운': 버스 정류장 도보 10분 이내
      if (f.kind == 'oreum' && f.oreum == 'accessible' && spot.walkMinutes > 10)
        return false;
      return true;
    }).toList();
    final routeDraft = ref.watch(routeDraftProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _ExploreSearchBar(
                query: f.query,
                lang: lang,
                onChanged: (value) => _updateFilter(f.copyWith(query: value)),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      _exploreTitle(lang),
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text1,
                      ),
                    ),
                  ),
                  _FilterLauncher(
                    label: _filterLabel(f, lang),
                    oreum: f.kind == 'oreum',
                    onTap: _openFilterSheet,
                  ),
                ],
              ),
            ),
            if (f.kind == 'oreum') ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.oreumGreenBg,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.terrain_rounded,
                          color: AppColors.oreumGreen, size: 19),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Oreum filter: ${f.oreum}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.oreumGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  apiSpots.isLoading
                      ? '${list.length}+ ${_placesLabel(lang)}'
                      : '${list.length} ${_placesLabel(lang)}',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 11, color: AppColors.text3),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 126),
                children: [
                  if (apiSpots.isLoading && list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (apiSpots.hasError && list.isEmpty)
                    Text('Failed to load places',
                        style: GoogleFonts.inter(color: AppColors.text2))
                  else
                    ...list.map(
                      (spot) => _ExploreSpotRow(
                          spot: spot,
                          lang: lang,
                          added: routeDraft.any((s) => s.id == spot.id),
                          onHover: () {},
                          onLeave: () {},
                          onOpen: () => ref
                              .read(selectedSpotProvider.notifier)
                              .state = spot,
                          onAdd: () {
                            final draft = ref.read(routeDraftProvider);
                            if (!draft.any((s) => s.id == spot.id)) {
                              ref.read(routeDraftProvider.notifier).state = [
                                ...draft,
                                spot
                              ];
                            }
                            final route = buildSavedRoute(spot, null,
                                scheduledAt: DateTime.now());
                            unawaited(
                              ref.read(savedRoutesProvider.notifier).add(route),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _savedToTripsLabel(lang, DateTime.now()),
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800),
                                ),
                                backgroundColor: AppColors.accent,
                                duration: const Duration(milliseconds: 1400),
                              ),
                            );
                          }),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _filterLabel(BrowseFilter f, AppLanguage lang) {
    final parts = <String>[
      switch (f.kind) {
        'food' => _moveFilterText(lang, 'food'),
        'cafe' => _moveFilterText(lang, 'cafe'),
        'oreum' => _moveFilterText(lang, 'oreum'),
        'under30' => _moveFilterText(lang, 'under30'),
        _ => _moveFilterText(lang, 'attractions'),
      },
      if (f.kind == 'spots' && f.tourismStyle != 'all')
        _moveFilterText(lang, f.tourismStyle),
      if (f.kind == 'oreum' && f.oreum != 'all') _moveFilterText(lang, f.oreum),
      if (f.kind == 'food' && f.foodStyle != 'all')
        _moveFilterText(lang, f.foodStyle),
      if (f.kind == 'cafe' && f.cafeStyle != 'all')
        _moveFilterText(lang, f.cafeStyle),
    ];
    return parts.join(' / ');
  }

  void _openFilterSheet() {
    final cur = ref.read(browseFilterProvider);
    var sheetKind = cur.kind;
    var sheetTourismStyle = cur.tourismStyle;
    var sheetOreum = cur.oreum;
    var sheetFoodStyle = cur.foodStyle;
    var sheetCafeStyle = cur.cafeStyle;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.separator,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _moveFilterText(ref.watch(appLanguageProvider), 'filters'),
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text1,
                  ),
                ),
                const SizedBox(height: 16),
                _FilterSection(
                  title: _moveFilterText(
                      ref.watch(appLanguageProvider), 'placeType'),
                  children: [
                    for (final item in [
                      (
                        'spots',
                        _moveFilterText(
                            ref.watch(appLanguageProvider), 'attractions'),
                        Icons.tune_rounded
                      ),
                      (
                        'food',
                        _moveFilterText(ref.watch(appLanguageProvider), 'food'),
                        Icons.restaurant_rounded
                      ),
                      (
                        'cafe',
                        _moveFilterText(ref.watch(appLanguageProvider), 'cafe'),
                        Icons.local_cafe_rounded
                      ),
                      (
                        'oreum',
                        _moveFilterText(
                            ref.watch(appLanguageProvider), 'oreum'),
                        Icons.terrain_rounded
                      ),
                      (
                        'under30',
                        _moveFilterText(
                            ref.watch(appLanguageProvider), 'under30'),
                        Icons.timer_rounded
                      ),
                    ])
                      _FilterChoice(
                        label: item.$2,
                        icon: item.$3,
                        active: sheetKind == item.$1,
                        oreum: item.$1 == 'oreum',
                        onTap: () => setSheetState(() => sheetKind = item.$1),
                      ),
                  ],
                ),
                if (sheetKind == 'food') ...[
                  const SizedBox(height: 18),
                  _FilterSection(
                    title: _moveFilterText(
                        ref.watch(appLanguageProvider), 'foodType'),
                    children: [
                      for (final item in [
                        (
                          'all',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'allFood'),
                          Icons.restaurant_menu_rounded
                        ),
                        (
                          'local',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'localFood'),
                          Icons.storefront_rounded
                        ),
                        (
                          'korean',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'korean'),
                          Icons.rice_bowl_rounded
                        ),
                        (
                          'seafood',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'seafood'),
                          Icons.set_meal_rounded
                        ),
                        (
                          'japanese',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'japanese'),
                          Icons.ramen_dining_rounded
                        ),
                        (
                          'western',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'western'),
                          Icons.local_pizza_rounded
                        ),
                        (
                          'chinese',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'chinese'),
                          Icons.lunch_dining_rounded
                        ),
                        (
                          'vegetarian',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'vegetarian'),
                          Icons.eco_rounded
                        ),
                      ])
                        _FilterChoice(
                          label: item.$2,
                          icon: item.$3,
                          active: sheetFoodStyle == item.$1,
                          onTap: () =>
                              setSheetState(() => sheetFoodStyle = item.$1),
                        ),
                    ],
                  ),
                ] else if (sheetKind == 'cafe') ...[
                  const SizedBox(height: 18),
                  _FilterSection(
                    title: _moveFilterText(
                        ref.watch(appLanguageProvider), 'cafeStyle'),
                    children: [
                      for (final item in [
                        (
                          'all',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'allCafes'),
                          Icons.local_cafe_rounded
                        ),
                        (
                          'view',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'view'),
                          Icons.landscape_rounded
                        ),
                        (
                          'dessert',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'dessert'),
                          Icons.cake_rounded
                        ),
                        (
                          'roastery',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'roastery'),
                          Icons.coffee_rounded
                        ),
                        (
                          'brunch',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'brunch'),
                          Icons.brunch_dining_rounded
                        ),
                        (
                          'traditional',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'traditional'),
                          Icons.temple_buddhist_rounded
                        ),
                        (
                          'unique',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'unique'),
                          Icons.auto_awesome_rounded
                        ),
                      ])
                        _FilterChoice(
                          label: item.$2,
                          icon: item.$3,
                          active: sheetCafeStyle == item.$1,
                          onTap: () =>
                              setSheetState(() => sheetCafeStyle = item.$1),
                        ),
                    ],
                  ),
                ] else if (sheetKind == 'spots') ...[
                  const SizedBox(height: 18),
                  _FilterSection(
                    title: _moveFilterText(
                        ref.watch(appLanguageProvider), 'attractionType'),
                    children: [
                      for (final item in [
                        (
                          'all',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'all'),
                          Icons.all_inclusive_rounded
                        ),
                        (
                          'nature',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'nature'),
                          Icons.forest_rounded
                        ),
                        (
                          'beach',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'beach'),
                          Icons.beach_access_rounded
                        ),
                        (
                          'culture',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'culture'),
                          Icons.account_balance_rounded
                        ),
                        (
                          'family',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'family'),
                          Icons.attractions_rounded
                        ),
                        (
                          'scenic',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'scenic'),
                          Icons.landscape_rounded
                        ),
                        (
                          'cave',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'cave'),
                          Icons.blur_circular_rounded
                        ),
                      ])
                        _FilterChoice(
                          label: item.$2,
                          icon: item.$3,
                          active: sheetTourismStyle == item.$1,
                          onTap: () =>
                              setSheetState(() => sheetTourismStyle = item.$1),
                        ),
                    ],
                  ),
                ],
                if (sheetKind == 'oreum') ...[
                  const SizedBox(height: 18),
                  _FilterSection(
                    title: _moveFilterText(
                        ref.watch(appLanguageProvider), 'oreumDetails'),
                    green: true,
                    children: [
                      for (final item in [
                        (
                          'all',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'allOreum'),
                          Icons.eco_rounded
                        ),
                        (
                          'easy',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'oreumEasy'),
                          Icons.directions_walk_rounded
                        ),
                        (
                          'moderate',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'oreumModerate'),
                          Icons.hiking_rounded
                        ),
                        (
                          'sunrise',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'sunrise'),
                          Icons.wb_twilight_rounded
                        ),
                        (
                          'crater',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'crater'),
                          Icons.circle_outlined
                        ),
                        (
                          'view',
                          _moveFilterText(
                              ref.watch(appLanguageProvider), 'oreumView'),
                          Icons.landscape_rounded
                        ),
                        (
                          'accessible',
                          _moveFilterText(ref.watch(appLanguageProvider),
                              'oreumAccessible'),
                          Icons.accessible_rounded
                        ),
                      ])
                        _FilterChoice(
                          label: item.$2,
                          icon: item.$3,
                          active: sheetOreum == item.$1,
                          oreum: true,
                          onTap: () =>
                              setSheetState(() => sheetOreum = item.$1),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _updateFilter(BrowseFilter(
                          kind: sheetKind,
                          tourismStyle: sheetTourismStyle,
                          oreum: sheetOreum,
                          foodStyle: sheetFoodStyle,
                          cafeStyle: sheetCafeStyle,
                          query: ref.read(browseFilterProvider).query,
                        ));
                      });
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(_moveFilterText(
                        ref.watch(appLanguageProvider), 'applyFilters')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sheetKind == 'oreum'
                          ? AppColors.oreumGreen
                          : AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterLauncher extends StatelessWidget {
  const _FilterLauncher({
    required this.label,
    required this.oreum,
    required this.onTap,
  });

  final String label;
  final bool oreum;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.tune_rounded, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: oreum ? AppColors.oreumGreen : AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.children,
    this.green = false,
  });

  final String title;
  final List<Widget> children;
  final bool green;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: green ? AppColors.oreumGreenBg : AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: green ? AppColors.oreumGreen : AppColors.text2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}

class _FilterChoice extends StatelessWidget {
  const _FilterChoice({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.oreum = false,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final bool oreum;

  @override
  Widget build(BuildContext context) {
    final color = oreum ? AppColors.oreumGreen : AppColors.accent;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: active ? color : AppColors.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? color : AppColors.separator.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: active ? Colors.white : color),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : AppColors.text1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreSearchBar extends StatelessWidget {
  const _ExploreSearchBar({
    required this.query,
    required this.lang,
    required this.onChanged,
  });

  final String query;
  final AppLanguage lang;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.only(left: 14, right: 6),
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.separator),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.text1, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: query)
                ..selection = TextSelection.collapsed(offset: query.length),
              onChanged: onChanged,
              decoration: InputDecoration(
                isDense: true,
                hintText: _moveFilterText(lang, 'searchHint'),
                hintStyle:
                    GoogleFonts.inter(fontSize: 14, color: AppColors.text3),
                border: InputBorder.none,
              ),
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.text1),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isOreum(Spot spot) {
  final name = [
    spot.nameEn,
    spot.sub,
    spot.nearestStop,
    ...spot.tags,
  ].join(' ').toLowerCase();
  return name.contains('peak') ||
      name.contains('crater') ||
      name.contains('sangumburi') ||
      name.contains('oreum') ||
      name.contains('오름') ||
      name.contains('분화구') ||
      name.contains('산굼부리') ||
      name.contains('용눈이') ||
      name.contains('다랑쉬') ||
      name.contains('새별') ||
      name.contains('따라비') ||
      spot.tags.contains('volcanic') ||
      spot.tags.contains('crater');
}

bool _matchesOreumStyle(Spot spot, String style) {
  final text = _spotSearchText(spot);
  final keywords = switch (style) {
    'sunrise' => [
        'sunrise',
        'peak',
        '일출',
        '해돋이',
        '봉',
        '성산',
        'ilchulbong',
        'seongsan'
      ],
    'crater' => [
        'crater',
        'volcanic',
        '분화구',
        '화산',
        '굼부리',
        'sangumburi',
        '산굼부리',
        'caldera'
      ],
    // 정상 전망이 좋은 오름: scenic·photo·view 태그 또는 이름에 '봉'
    'view' => [
        'scenic',
        'photo',
        'view',
        '전망',
        '봉',
        'peak',
        'panorama',
        '조망',
        '경관'
      ],
    _ => const <String>[],
  };
  return keywords.isEmpty || keywords.any(text.contains);
}

String _exploreTitle(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '탐색',
      AppLanguage.en => 'Explore',
      AppLanguage.ja => '探す',
      AppLanguage.zh => '探索',
    };

String _placesLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '장소',
      AppLanguage.en => 'places',
      AppLanguage.ja => 'スポット',
      AppLanguage.zh => '地点',
    };

String _savedToTripsLabel(AppLanguage lang, DateTime date) {
  final m = date.month;
  final d = date.day;
  return switch (lang) {
    AppLanguage.ko => '${m}월 ${d}일 일정에 추가했어요 ✓',
    AppLanguage.en => 'Added to $m/$d route ✓',
    AppLanguage.ja => '${m}/${d}の旅程に追加しました ✓',
    AppLanguage.zh => '已添加到${m}月${d}日行程 ✓',
  };
}

bool _matchesTourismStyle(Spot spot, String style) {
  final text = _spotSearchText(spot);
  final tags = spot.tags.map((t) => t.toLowerCase()).toSet();
  final keywords = switch (style) {
    'nature' => [
        'forest',
        'park',
        'garden',
        'waterfall',
        'trail',
        'eco',
        'nature',
        'botanical',
        'grove',
        'valley',
        'stream',
        'wetland',
        'bijarim',
        '숲',
        '공원',
        '정원',
        '폭포',
        '생태',
        '수목원',
        '산책',
        '계곡',
        '자연',
      ],
    'beach' => [
        'beach',
        'coast',
        'ocean',
        'sea',
        'cape',
        'bay',
        'swimming',
        'shore',
        'sand',
        'coral',
        'emerald',
        'snorkel',
        'surf',
        '해변',
        '해수욕장',
        '바다',
        '해안',
        '오션',
        '포구',
        '협재',
        '이호',
        '함덕',
      ],
    'culture' => [
        'museum',
        'heritage',
        'village',
        'temple',
        'history',
        'culture',
        'art',
        'diver',
        'haenyeo',
        'traditional',
        'folk',
        'gallery',
        'exhibit',
        '박물관',
        '미술관',
        '문화',
        '역사',
        '마을',
        '유적',
        '기념관',
        '해녀',
        '전통',
      ],
    'family' => [
        'theme',
        'aquarium',
        'zoo',
        'experience',
        'kids',
        'family',
        'train',
        'park',
        'land',
        'animal',
        'ride',
        'play',
        '테마',
        '아쿠아',
        '체험',
        '어린이',
        '가족',
        '랜드',
        '동물',
        '기차',
      ],
    'scenic' => [
        'scenic',
        'view',
        'photo',
        'lighthouse',
        'sunrise',
        'sunset',
        'cliff',
        'rock',
        'panorama',
        'landscape',
        '전망',
        '경치',
        '뷰',
        '등대',
        '일출',
        '일몰',
        '절벽',
        '바위',
      ],
    'cave' => [
        'cave',
        'lava',
        'tube',
        'underground',
        'manjanggul',
        'hallim',
        '동굴',
        '용암',
        '지하',
        '만장굴',
        '협재굴',
      ],
    _ => const <String>[],
  };
  if (keywords.isEmpty) return true;
  if (keywords.any(text.contains)) return true;
  // tag-based fallback
  return switch (style) {
    'nature' => tags.any(
        {'forest', 'nature', 'garden', 'eco', 'walking', 'trail'}.contains),
    'beach' => tags.any({'beach', 'swimming', 'coastal'}.contains),
    'culture' =>
      tags.any({'museum', 'culture', 'heritage', 'UNESCO', 'indoor'}.contains),
    'family' =>
      tags.any({'family', 'aquarium', 'theme', 'experience'}.contains),
    'scenic' => tags.any({'scenic', 'photo', 'lighthouse', 'sunrise'}.contains),
    'cave' => tags.any({'cave', 'lava', 'indoor'}.contains),
    _ => false,
  };
}

String _moveFilterText(AppLanguage lang, String key) {
  final ko = {
    'filter': '필터',
    'attractions': '관광지',
    'filters': '필터',
    'placeType': '장소 유형',
    'attractionType': '관광지 유형',
    'nature': '자연/생태',
    'beach': '해변/해안',
    'culture': '문화/역사',
    'family': '가족/체험',
    'scenic': '전망/경관',
    'cave': '동굴',
    'food': '음식점',
    'cafe': '카페',
    'oreum': '오름',
    'under30': '30분 이내',
    'foodType': '음식 종류',
    'allFood': '전체',
    'localFood': '제주 향토',
    'korean': '한식',
    'chinese': '중식',
    'western': '양식',
    'japanese': '일식',
    'seafood': '해산물',
    'vegetarian': '채식/비건',
    'cafeStyle': '카페 스타일',
    'allCafes': '전체',
    'dessert': '디저트/베이커리',
    'view': '오션뷰/전망',
    'roastery': '스페셜티/로스터리',
    'brunch': '브런치',
    'traditional': '전통/한옥차',
    'unique': '독특한/컨셉',
    'mood': '분위기',
    'all': '전체',
    'outdoor': '야외',
    'indoor': '실내',
    'both': '둘 다',
    'oreumDetails': '오름 필터',
    'allOreum': '전체 오름',
    'oreumEasy': '가벼운 산책 (20분↓)',
    'oreumModerate': '보통 난이도 (40분↓)',
    'oreumView': '전망 좋은 오름',
    'oreumAccessible': '접근 편한 오름',
    'easy': '가벼운 산책',
    'sunrise': '일출 명소',
    'crater': '분화구',
    'applyFilters': '필터 적용',
    'searchHint': '장소, 정류장 검색',
  };
  final en = {
    'filter': 'Filter',
    'attractions': 'Attractions',
    'filters': 'Filters',
    'placeType': 'Place type',
    'attractionType': 'Attraction type',
    'nature': 'Nature / Eco',
    'beach': 'Beach / Coast',
    'culture': 'Culture / History',
    'family': 'Family / Activity',
    'scenic': 'Scenic / View',
    'cave': 'Cave / Underground',
    'food': 'Food',
    'cafe': 'Cafe',
    'oreum': 'Oreum',
    'under30': 'Under 30 min',
    'foodType': 'Food type',
    'allFood': 'All',
    'localFood': 'Jeju Local',
    'korean': 'Korean',
    'chinese': 'Chinese',
    'western': 'Western',
    'japanese': 'Japanese',
    'seafood': 'Seafood',
    'vegetarian': 'Vegetarian',
    'cafeStyle': 'Cafe style',
    'allCafes': 'All',
    'dessert': 'Dessert / Bakery',
    'view': 'Ocean View',
    'roastery': 'Specialty Coffee',
    'brunch': 'Brunch',
    'traditional': 'Traditional Tea',
    'unique': 'Unique / Concept',
    'mood': 'Mood',
    'all': 'All',
    'outdoor': 'Outdoor',
    'indoor': 'Indoor',
    'both': 'Both',
    'oreumDetails': 'Oreum filter',
    'allOreum': 'All oreum',
    'oreumEasy': 'Easy (under 20min)',
    'oreumModerate': 'Moderate (under 40min)',
    'oreumView': 'Scenic view',
    'oreumAccessible': 'Easy access',
    'easy': 'Easy walk',
    'sunrise': 'Sunrise spot',
    'crater': 'Crater',
    'applyFilters': 'Apply filters',
    'searchHint': 'Search spots, stops',
  };
  final ja = {
    'filter': 'フィルター',
    'attractions': '観光地',
    'filters': 'フィルター',
    'placeType': '場所タイプ',
    'attractionType': '観光地タイプ',
    'nature': '自然/エコ',
    'beach': 'ビーチ/海岸',
    'culture': '文化/歴史',
    'family': '家族/体験',
    'scenic': '絶景/展望',
    'cave': '洞窟',
    'food': 'グルメ',
    'cafe': 'カフェ',
    'oreum': 'オルム',
    'under30': '30分以内',
    'foodType': '料理タイプ',
    'allFood': 'すべて',
    'localFood': '済州郷土料理',
    'korean': '韓国料理',
    'chinese': '中華',
    'western': '洋食',
    'japanese': '和食',
    'seafood': '海鮮',
    'vegetarian': 'ベジタリアン',
    'cafeStyle': 'カフェスタイル',
    'allCafes': 'すべて',
    'dessert': 'デザート/ベーカリー',
    'view': 'オーシャンビュー',
    'roastery': 'スペシャルティ',
    'brunch': 'ブランチ',
    'traditional': '伝統茶/韓屋',
    'unique': 'ユニーク/テーマ',
    'mood': '雰囲気',
    'all': 'すべて',
    'outdoor': '屋外',
    'indoor': '屋内',
    'both': '両方',
    'oreumDetails': 'オルムフィルター',
    'allOreum': 'すべてのオルム',
    'oreumEasy': '楽な散歩 (20分以内)',
    'oreumModerate': '普通 (40分以内)',
    'oreumView': '展望の良いオルム',
    'oreumAccessible': 'アクセス便利',
    'easy': '歩きやすい',
    'sunrise': '日の出スポット',
    'crater': '火口',
    'applyFilters': '適用',
    'searchHint': '場所、停留所を検索',
  };
  final zh = {
    'filter': '筛选',
    'attractions': '景点',
    'filters': '筛选',
    'placeType': '地点类型',
    'attractionType': '景点类型',
    'nature': '自然',
    'beach': '海滩',
    'culture': '文化',
    'family': '亲子/体验',
    'food': '餐厅',
    'cafe': '咖啡馆',
    'oreum': '寄生火山',
    'under30': '30分钟内',
    'foodType': '餐饮类型',
    'allFood': '全部餐厅',
    'korean': '韩餐',
    'chinese': '中餐',
    'western': '西餐',
    'japanese': '日餐',
    'seafood': '海鲜',
    'cafeStyle': '咖啡馆风格',
    'allCafes': '全部咖啡馆',
    'dessert': '甜点',
    'view': '海景 / 景观',
    'roastery': '烘焙咖啡',
    'brunch': '早午餐',
    'mood': '氛围',
    'all': '全部',
    'outdoor': '户外',
    'indoor': '室内',
    'both': '两者',
    'scenic': '景观/展望',
    'cave': '洞窟',
    'localFood': '济州乡土料理',
    'vegetarian': '素食/纯素',
    'traditional': '传统茶/韩屋',
    'unique': '独特/主题',
    'oreumEasy': '轻松散步 (20分钟内)',
    'oreumModerate': '普通难度 (40分钟内)',
    'oreumView': '景色好的岳',
    'oreumAccessible': '交通便利',
    'oreumDetails': '寄生火山筛选',
    'allOreum': '全部寄生火山',
    'easy': '轻松步行',
    'sunrise': '日出景点',
    'crater': '火山口',
    'applyFilters': '应用筛选',
    'searchHint': '搜索地点、车站',
  };
  return switch (lang) {
    AppLanguage.ko => ko[key] ?? en[key] ?? key,
    AppLanguage.ja => ja[key] ?? en[key] ?? key,
    AppLanguage.zh => zh[key] ?? en[key] ?? key,
    AppLanguage.en => en[key] ?? key,
  };
}

bool _matchesFoodStyle(Spot spot, String style) {
  final text = _spotSearchText(spot);
  final tags = spot.tags.map((t) => t.toLowerCase()).toSet();
  final keywords = switch (style) {
    'local' => [
        'jeju',
        'local',
        'specialty',
        'black pork',
        'heukdwaeji',
        'haemul',
        'gogi',
        'okdom',
        'galchi',
        'haenyeo',
        'dolsot',
        'jeonbok',
        '제주',
        '향토',
        '흑돼지',
        '고기국수',
        '옥돔',
        '갈치',
        '전복',
        '해산물',
        '해물',
        '제주산',
        '향토음식',
        '로컬',
      ],
    'korean' => [
        'korean',
        'hanguk',
        'guksu',
        'pork',
        'rice',
        'noodle',
        'soup',
        'bbq',
        'meat',
        'kimchi',
        'bibimbap',
        'doenjang',
        'samgyupsal',
        '한식',
        '국수',
        '흑돼지',
        '고기',
        '갈비',
        '해장국',
        '밥',
        '김치',
        '비빔밥',
        '된장',
        '삼겹살',
        '순대',
        '설렁탕',
        '국밥',
        '찌개',
      ],
    'seafood' => [
        'seafood',
        'fish',
        'sashimi',
        'abalone',
        'raw fish',
        'grilled fish',
        'octopus',
        'shrimp',
        'crab',
        'haemul',
        'galchi',
        'okdom',
        '해물',
        '해산물',
        '생선',
        '회',
        '전복',
        '갈치',
        '고등어',
        '문어',
        '새우',
        '게',
        '낙지',
        '조개',
        '굴',
        '해물탕',
      ],
    'japanese' => [
        'japanese',
        'sushi',
        'ramen',
        'udon',
        'katsu',
        'donburi',
        'tempura',
        'izakaya',
        'yakitori',
        'tonkatsu',
        '일식',
        '초밥',
        '스시',
        '라멘',
        '우동',
        '돈카츠',
        '돈가스',
        '덮밥',
        '튀김',
      ],
    'western' => [
        'western',
        'pasta',
        'pizza',
        'steak',
        'burger',
        'bistro',
        'brunch',
        'french',
        'italian',
        'american',
        'sandwich',
        'grill',
        '양식',
        '파스타',
        '피자',
        '스테이크',
        '버거',
        '브런치',
        '샌드위치',
        '그릴',
      ],
    'chinese' => [
        'chinese',
        'jajang',
        'jjamppong',
        'mala',
        'dim sum',
        'hotpot',
        'tang',
        'chunjang',
        '중식',
        '중국',
        '짜장',
        '짬뽕',
        '마라',
        '딤섬',
        '훠궈',
        '탕수육',
      ],
    'vegetarian' => [
        'vegetarian',
        'vegan',
        'plant',
        'salad',
        'tofu',
        'temple food',
        'healthy',
        'organic',
        'grain',
        '채식',
        '비건',
        '사찰음식',
        '두부',
        '샐러드',
        '건강식',
        '유기농',
      ],
    _ => const <String>[],
  };
  if (keywords.isEmpty) return true;
  if (keywords.any(text.contains)) return true;
  return switch (style) {
    'local' => tags.any({'jeju', 'local', 'seafood', 'specialty'}.contains),
    'korean' => tags.any({'korean', 'bbq', 'meat', 'noodle'}.contains),
    'seafood' => tags.any({'seafood', 'fish', 'ocean'}.contains),
    'japanese' => tags.any({'japanese', 'sushi', 'ramen'}.contains),
    'western' => tags.any({'western', 'pasta', 'pizza', 'burger'}.contains),
    'chinese' => tags.any({'chinese', 'noodle'}.contains),
    'vegetarian' => tags.any({'vegetarian', 'vegan', 'healthy'}.contains),
    _ => false,
  };
}

bool _matchesCafeStyle(Spot spot, String style) {
  final text = _spotSearchText(spot);
  final tags = spot.tags.map((t) => t.toLowerCase()).toSet();
  final keywords = switch (style) {
    'view' => [
        'beach',
        'ocean',
        'sea',
        'view',
        'coast',
        'cliff',
        'panorama',
        'rooftop',
        'terrace',
        'mountain',
        'landscape',
        'scenic',
        '바다',
        '해변',
        '오션',
        '뷰',
        '전망',
        '테라스',
        '루프탑',
        '경치',
        '해안',
      ],
    'dessert' => [
        'dessert',
        'bakery',
        'cake',
        'bread',
        'donut',
        'macaron',
        'ice cream',
        'gelato',
        'waffle',
        'croissant',
        'chocolate',
        'tart',
        'pudding',
        '디저트',
        '베이커리',
        '케이크',
        '빵',
        '마카롱',
        '아이스크림',
        '와플',
        '타르트',
        '초콜릿',
        '크루아상',
        '젤라토',
      ],
    'roastery' => [
        'coffee',
        'roastery',
        'roaster',
        'espresso',
        'barista',
        'specialty',
        'drip',
        'single origin',
        'filter',
        '커피',
        '로스터리',
        '에스프레소',
        '바리스타',
        '스페셜티',
        '드립',
      ],
    'brunch' => [
        'brunch',
        'sandwich',
        'pancake',
        'egg',
        'toast',
        'salad',
        'healthy',
        'avocado',
        'granola',
        'acai',
        '브런치',
        '샌드위치',
        '팬케이크',
        '에그',
        '토스트',
        '샐러드',
        '아보카도',
      ],
    'traditional' => [
        'traditional',
        'hanok',
        'tea',
        'korean tea',
        'yuja',
        'sikhye',
        'omija',
        'herb',
        'jeju tea',
        '전통',
        '한옥',
        '차',
        '녹차',
        '유자',
        '식혜',
        '오미자',
        '허브',
        '제주차',
      ],
    'unique' => [
        'unique',
        'concept',
        'theme',
        'art',
        'design',
        'instagrammable',
        'special',
        'experience',
        'workshop',
        'gallery',
        '독특',
        '컨셉',
        '테마',
        '아트',
        '디자인',
        '인스타',
        '특별',
        '체험',
        '갤러리',
      ],
    _ => const <String>[],
  };
  if (keywords.isEmpty) return true;
  if (keywords.any(text.contains)) return true;
  return switch (style) {
    'view' => tags.any({'view', 'beach', 'ocean', 'scenic'}.contains),
    'dessert' => tags.any({'dessert', 'bakery', 'sweet'}.contains),
    'roastery' => tags.any({'coffee', 'roastery', 'specialty'}.contains),
    'brunch' => tags.any({'brunch', 'breakfast', 'healthy'}.contains),
    'traditional' => tags.any({'traditional', 'tea', 'korean'}.contains),
    'unique' => tags.any({'art', 'concept', 'design', 'unique'}.contains),
    _ => false,
  };
}

String _spotSearchText(Spot spot) {
  return [
    spot.nameEn,
    spot.sub,
    spot.nearestStop,
    spot.hours,
    ...spot.tags,
  ].join(' ').toLowerCase();
}

class _ExploreSpotRow extends StatelessWidget {
  const _ExploreSpotRow({
    required this.spot,
    required this.lang,
    required this.added,
    required this.onHover,
    required this.onLeave,
    required this.onOpen,
    required this.onAdd,
  });

  final Spot spot;
  final AppLanguage lang;
  final bool added;
  final VoidCallback onHover;
  final VoidCallback onLeave;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(),
      onExit: (_) => onLeave(),
      child: GestureDetector(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.surface2)),
          ),
          child: Row(
            children: [
              SizedBox(
                  width: 100,
                  child: ClaudeSpotImage(
                      spot: spot, height: 76, borderRadius: 18)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            spotDisplayName(spot, lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text1,
                            ),
                          ),
                        ),
                        if (added)
                          const ClaudeChip(
                              label: 'Added', tone: ClaudeChipTone.primary),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      spotDisplayDescription(spot, lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.text2),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          _spotTransitLabel(lang, spot),
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 11, color: AppColors.text1),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: onAdd,
                          child: const Icon(Icons.add_circle_rounded,
                              color: AppColors.accent, size: 22),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*
Legacy API-backed place tab remains below for the route planner detail sheet and
as a fallback surface if we wire search results back in later.
*/

class _LegacyBrowseView extends ConsumerStatefulWidget {
  const _LegacyBrowseView();

  @override
  ConsumerState<_LegacyBrowseView> createState() => _LegacyBrowseViewState();
}

class _LegacyBrowseViewState extends ConsumerState<_LegacyBrowseView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                            color: AppColors.greenBg, shape: BoxShape.circle),
                        child: const Icon(Icons.search_rounded,
                            color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'JejuFlow',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text1,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: AppColors.surfaceLow,
                            borderRadius: BorderRadius.circular(999)),
                        child: const Icon(Icons.tune_rounded,
                            color: AppColors.text2, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Explore',
                    style: GoogleFonts.montserrat(
                      fontSize: 42,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Live spots, bus timing, and weather-aware picks.',
                    style: GoogleFonts.inter(
                        fontSize: 16, height: 1.45, color: AppColors.text2),
                  ),
                  const SizedBox(height: 18),
                  const _MapPreview(),
                  const SizedBox(height: 14),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: AppColors.separator.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded,
                            color: AppColors.text1, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Search spots, stops',
                          style: GoogleFonts.inter(
                              fontSize: 14, color: AppColors.text3),
                        ),
                        const Spacer(),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                              color: AppColors.accent, shape: BoxShape.circle),
                          child: const Icon(Icons.near_me_rounded,
                              color: Colors.white, size: 17),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 0, 8),
              child: TabBar(
                controller: _tab,
                isScrollable: true,
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w800),
                unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.text2,
                indicator: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: 'Under 30'),
                  Tab(text: 'Food'),
                  Tab(text: 'Cafe'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _PlaceTab(type: PlaceType.tourist),
                  _PlaceTab(type: PlaceType.restaurant),
                  _PlaceTab(type: PlaceType.cafe),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.separator.withValues(alpha: 0.45)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _JejuMiniMapPainter()),
          ),
          Positioned(
            left: 18,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.bg.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'JEJU LIVE MAP',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.inverseSurface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '12 spots',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inverseText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JejuMiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sea = Paint()..color = AppColors.surface2;
    canvas.drawRect(Offset.zero & size, sea);

    final island = Path()
      ..moveTo(size.width * .12, size.height * .46)
      ..quadraticBezierTo(size.width * .20, size.height * .15, size.width * .48,
          size.height * .16)
      ..quadraticBezierTo(size.width * .83, size.height * .12, size.width * .90,
          size.height * .42)
      ..quadraticBezierTo(size.width * .93, size.height * .70, size.width * .63,
          size.height * .82)
      ..quadraticBezierTo(size.width * .30, size.height * .90, size.width * .13,
          size.height * .62)
      ..close();
    canvas.drawPath(
        island, Paint()..color = AppColors.greenBg.withValues(alpha: 0.62));
    canvas.drawPath(
      island,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.greenBgDim,
    );

    final dots = [
      const Offset(.20, .40),
      const Offset(.34, .28),
      const Offset(.50, .52),
      const Offset(.72, .34),
      const Offset(.82, .52),
      const Offset(.36, .70),
    ];
    for (final dot in dots) {
      canvas.drawCircle(Offset(size.width * dot.dx, size.height * dot.dy), 5,
          Paint()..color = AppColors.bg);
      canvas.drawCircle(Offset(size.width * dot.dx, size.height * dot.dy), 3,
          Paint()..color = AppColors.accent);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlaceTab extends ConsumerWidget {
  const _PlaceTab({required this.type});
  final PlaceType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(placeListProvider(type));
    final lang = ref.watch(appLanguageProvider);

    return places.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 40, color: AppColors.text3),
            const SizedBox(height: 12),
            Text('Failed to load',
                style:
                    GoogleFonts.outfit(fontSize: 14, color: AppColors.text2)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(placeListProvider(type)),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off_rounded,
                    size: 42, color: AppColors.text3),
                const SizedBox(height: 12),
                Text('No results found',
                    style: GoogleFonts.outfit(
                        fontSize: 14, color: AppColors.text2)),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisSpacing: 14,
            childAspectRatio: 0.9,
          ),
          itemCount: list.length,
          itemBuilder: (ctx, i) => PlaceCard(
            place: list[i],
            lang: lang,
            onTap: () => _onTap(context, ref, list[i]),
          ),
        );
      },
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, TourPlace place) {
    final match =
        kSpots.where((s) => s.contentId == place.contentId).firstOrNull;
    if (match != null) {
      ref.read(selectedSpotProvider.notifier).state = match;
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) =>
          _DetailSheet(place: place, lang: ref.read(appLanguageProvider)),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.place, required this.lang});
  final TourPlace place;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (ctx, ctrl) => SingleChildScrollView(
        controller: ctrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.separator,
                        borderRadius: BorderRadius.circular(2)))),
            if (place.hasImage) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                width: double.infinity,
                child: PlaceCard(place: place, lang: lang),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tourPlaceDisplayTitle(place, lang),
                      style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text1)),
                  if (tourPlaceDisplayAddress(place, lang).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 15, color: AppColors.text3),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(tourPlaceDisplayAddress(place, lang),
                              style: GoogleFonts.outfit(
                                  fontSize: 13, color: AppColors.text2))),
                    ]),
                  ],
                  if (place.tel.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.phone_outlined,
                          size: 15, color: AppColors.text3),
                      const SizedBox(width: 4),
                      Text(place.tel,
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: AppColors.text2)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ?????? Route Planner ??????????????????????????????????????????????????????????????????????????????????????????
class _RoutePlanner extends ConsumerStatefulWidget {
  const _RoutePlanner({required this.spot});
  final Spot spot;

  @override
  ConsumerState<_RoutePlanner> createState() => _RoutePlannerState();
}

class _RoutePlannerState extends ConsumerState<_RoutePlanner> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final buses = ref.watch(busArrivalsProvider(widget.spot.stopId));
    final weather = ref.watch(currentWeatherProvider).valueOrNull;
    final busArrival = buses.valueOrNull?.firstOrNull;
    final steps = buildRouteSteps(widget.spot, busArrival);
    final affected = widget.spot.isOutdoor && (weather?.isBad ?? false);
    final altSpot =
        widget.spot.altSpotId == null ? null : kSpotById[widget.spot.altSpotId];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 14, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: AppColors.text2,
                    onPressed: () =>
                        ref.read(selectedSpotProvider.notifier).state = null,
                  ),
                  Icon(_categoryIcon(widget.spot),
                      color: widget.spot.accentColor, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.spot.nameEn,
                        style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text1)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.spot.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Route',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: widget.spot.accentColor)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOUR ROUTE',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: AppColors.text3)),
                    const SizedBox(height: 16),
                    RouteStepsWidget(
                        steps: steps, accent: widget.spot.accentColor),
                    if (affected) ...[
                      const SizedBox(height: 18),
                      _WeatherRouteWarning(
                        altSpot: altSpot,
                        onSwitch: altSpot == null
                            ? null
                            : () {
                                ref.read(selectedSpotProvider.notifier).state =
                                    altSpot;
                                setState(() => _saved = false);
                              },
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saved
                            ? null
                            : () async {
                                final route =
                                    buildSavedRoute(widget.spot, busArrival);
                                await ref
                                    .read(savedRoutesProvider.notifier)
                                    .add(route);
                                setState(() => _saved = true);
                                if (context.mounted) {
                                  final l = ref.read(appLanguageProvider);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _savedToTripsLabel(l, DateTime.now()),
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w800),
                                      ),
                                      backgroundColor: AppColors.accent,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _saved
                              ? AppColors.separator
                              : widget.spot.accentColor,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.separator,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999)),
                          elevation: 0,
                        ),
                        child: Text(
                          _saved ? '??Saved' : 'Save Route',
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotDetailScreen extends ConsumerStatefulWidget {
  const _SpotDetailScreen({required this.spot});

  final Spot spot;

  @override
  ConsumerState<_SpotDetailScreen> createState() => _SpotDetailScreenState();
}

class _SpotDetailScreenState extends ConsumerState<_SpotDetailScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final weather = ref.watch(currentWeatherProvider).valueOrNull;
    final photo = ref.watch(spotPhotoUrlProvider(widget.spot.id));
    final info = ref
        .watch(
            spotInfoProvider((widget.spot.contentId, tourLanguageCode(lang))))
        .valueOrNull;
    final affected = widget.spot.isOutdoor && (weather?.isBad ?? false);
    final displayPhoto = photo ?? widget.spot.photoUrl;

    // detailIntro2 — 음식점/카페(39) or 관광지(12)
    final tags = widget.spot.tags.map((t) => t.toLowerCase()).toSet();
    final contentTypeId =
        (tags.contains('restaurant') || tags.contains('cafe')) ? '39' : '12';
    final intro = ref
        .watch(spotIntroProvider((widget.spot.contentId, contentTypeId)))
        .valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
          child: ElevatedButton.icon(
            onPressed: () => _openAddRouteSheet(context),
            icon: const Icon(Icons.add_location_alt_rounded),
            label: Text(_addToRouteLabel(lang)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle:
                  GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 530,
            pinned: true,
            backgroundColor: AppColors.bg,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _GlassButton(
                icon: Icons.arrow_back_rounded,
                onTap: () =>
                    ref.read(selectedSpotProvider.notifier).state = null,
              ),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: _GlassButton(icon: Icons.ios_share_rounded),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (displayPhoto != null && displayPhoto.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: displayPhoto,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => ClaudeSpotImage(
                          spot: widget.spot, height: 530, borderRadius: 0),
                    )
                  else
                    ClaudeSpotImage(
                        spot: widget.spot, height: 530, borderRadius: 0),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.34),
                          Colors.transparent,
                          AppColors.bg,
                        ],
                        stops: const [0, 0.68, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 92),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClaudeChip(
                    label: _spotTypeLabel(lang, widget.spot),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    spotDisplayName(widget.spot, lang),
                    style: GoogleFonts.montserrat(
                      fontSize: 38,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    spotDisplayDescription(widget.spot, lang),
                    style: GoogleFonts.inter(
                        fontSize: 16, height: 1.45, color: AppColors.text2),
                  ),
                  const SizedBox(height: 24),
                  // ── 운영시간 (전체폭) ──────────────────────────────
                  _HoursCard(
                    openTime:
                        _resolveOpenTime(intro, info, widget.spot.hours, lang),
                    restDate: _resolveRestDate(intro, info, lang),
                    lang: lang,
                  ),
                  const SizedBox(height: 12),
                  // ── 날씨 + 메뉴·입장료 (2열) ──────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _DetailInfoCard(
                          icon: weather?.iconData ?? Icons.wb_sunny_rounded,
                          label: _weatherTipLabel(lang),
                          value: affected
                              ? _weatherAffectedLabel(lang)
                              : _goodToGoLabel(lang),
                          sub: affected
                              ? _indoorBackupLabel(lang)
                              : _comfortableLabel(lang),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: contentTypeId == '39'
                            ? _DetailInfoCard(
                                icon: Icons.restaurant_menu_rounded,
                                label: _menuLabel(lang),
                                value: intro?.menu.isNotEmpty == true
                                    ? localizeKoreanTourField(
                                        _cleanTourText(intro!.menu),
                                        lang,
                                        field: TourTextField.menu,
                                      )
                                    : _menuUnknownLabel(lang),
                                sub: _signatureDishLabel(lang),
                              )
                            : _DetailInfoCard(
                                icon: Icons.payments_rounded,
                                label: _feeLabel(lang),
                                value: intro?.useFee.isNotEmpty == true
                                    ? localizeKoreanTourField(
                                        _cleanTourText(intro!.useFee),
                                        lang,
                                        field: TourTextField.fee,
                                      )
                                    : info?.usefee.isNotEmpty == true
                                        ? localizeKoreanTourField(
                                            info!.usefee,
                                            lang,
                                            field: TourTextField.fee,
                                          )
                                        : widget.spot.fee == 0
                                            ? _freeLabel(lang)
                                            : '₩${widget.spot.fee}',
                                sub: _adultStandardLabel(lang),
                                primary: widget.spot.fee > 0,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _TransitAccessCard(spot: widget.spot, lang: lang),
                  const SizedBox(height: 24),
                  _SpotLocationPreview(
                    spot: widget.spot,
                    lang: lang,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _overviewTitle(lang),
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lang == AppLanguage.ko && info?.overview.isNotEmpty == true
                        ? info!.overview
                        : spotDisplayDescription(widget.spot, lang),
                    style: GoogleFonts.inter(
                        fontSize: 16, height: 1.6, color: AppColors.text2),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: _NavigationButton(spot: widget.spot, lang: lang),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: () => _openAddRouteSheet(context),
                            icon: const Icon(Icons.add_location_alt_rounded,
                                size: 20),
                            label: Text(_addToRouteLabel(lang)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              textStyle: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddRouteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final draft = ref.watch(routeDraftProvider);
          final lang = ref.watch(appLanguageProvider);
          final inDraft = draft.any((s) => s.id == widget.spot.id);
          return StatefulBuilder(
            builder: (context, setSheetState) => DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.72,
              minChildSize: 0.46,
              maxChildSize: 0.94,
              builder: (context, controller) => ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.separator,
                          borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _addToRouteLabel(lang),
                    style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text1),
                  ),
                  const SizedBox(height: 6),
                  Text(spotDisplayName(widget.spot, lang),
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.text2)),
                  const SizedBox(height: 18),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 180)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        setSheetState(() {});
                      }
                    },
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded,
                              color: AppColors.accent),
                          const SizedBox(width: 12),
                          Text(
                            '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}',
                            style: GoogleFonts.inter(
                                fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          const Icon(Icons.expand_more_rounded,
                              color: AppColors.text3),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _AddSpotInfoSummary(spot: widget.spot, lang: lang),
                  const SizedBox(height: 22),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (!inDraft) {
                        ref.read(routeDraftProvider.notifier).state = [
                          ...draft,
                          widget.spot
                        ];
                      }
                      final scheduledAt = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                      );
                      final route = buildSavedRoute(widget.spot, null,
                          scheduledAt: scheduledAt);
                      await ref.read(savedRoutesProvider.notifier).add(route);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        final l = ref.read(appLanguageProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _savedToTripsLabel(l, scheduledAt),
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800),
                            ),
                            backgroundColor: AppColors.accent,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon:
                        Icon(inDraft ? Icons.check_rounded : Icons.add_rounded),
                    label: Text(inDraft
                        ? _updateRouteLabel(lang)
                        : _addToRouteLabel(lang)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }
}

class _AddSpotInfoSummary extends ConsumerWidget {
  const _AddSpotInfoSummary({required this.spot, required this.lang});

  final Spot spot;
  final AppLanguage lang;

  String _feeText() {
    if (spot.fee == 0) {
      return switch (lang) {
        AppLanguage.ko => '무료',
        AppLanguage.en => 'Free',
        AppLanguage.ja => '無料',
        AppLanguage.zh => '免費',
      };
    }
    return '₩${spot.fee.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
  }

  String _hoursText(String? apiHours) {
    // API 데이터 우선 사용
    final raw = (apiHours?.isNotEmpty == true) ? apiHours! : spot.hours;
    if (raw.isEmpty || raw == 'All day') {
      return switch (lang) {
        AppLanguage.ko => '상시 개방',
        AppLanguage.en => 'Always open',
        AppLanguage.ja => '常時開放',
        AppLanguage.zh => '全天開放',
      };
    }
    if (raw == 'Check before visit') {
      return switch (lang) {
        AppLanguage.ko => '방문 전 확인',
        AppLanguage.en => 'Check before visit',
        AppLanguage.ja => '訪問前に確認',
        AppLanguage.zh => '出发前确认',
      };
    }
    return _cleanTourText(raw).replaceAll('-', ' – ');
  }

  // 표시하지 않을 태그 목록 (내부 분류용)
  static const _hiddenTags = {
    'api',
    'saved',
    'restaurant',
    'cafe',
    'tourism',
    'recommended',
    'outdoor',
    'indoor_ok',
    'both',
    'spot',
  };

  String? _localizedTag(String tag) {
    const ko = {
      'UNESCO': 'UNESCO',
      'sunrise': '일출',
      'volcanic': '화산',
      'garden': '정원',
      'cave': '동굴',
      'family': '가족',
      'beach': '해변',
      'free': '무료',
      'swimming': '수영',
      'scenic': '절경',
      'lighthouse': '등대',
      'walking': '산책',
      'indoor': '실내',
      'culture': '문화',
      'nature': '자연',
      'forest': '숲',
      'waterfall': '폭포',
      'aquarium': '아쿠아리움',
      'rain_ok': '우천OK',
      'photo': '포토스팟',
      'coastal': '해안',
      'crater': '분화구',
      'train': '기차',
      'eco': '생태',
      'oreum': '오름',
      'gotjawal': '곶자왈',
      'bbq': '바베큐',
      'seafood': '해산물',
      'korean': '한식',
      'western': '양식',
      'japanese': '일식',
      'brunch': '브런치',
      'dessert': '디저트',
      'view': '전망',
      'roastery': '로스터리',
      'traditional': '전통',
      'unique': '이색카페',
    };
    const en = {
      'UNESCO': 'UNESCO',
      'sunrise': 'Sunrise',
      'volcanic': 'Volcanic',
      'garden': 'Garden',
      'cave': 'Cave',
      'family': 'Family',
      'beach': 'Beach',
      'free': 'Free',
      'swimming': 'Swimming',
      'scenic': 'Scenic',
      'lighthouse': 'Lighthouse',
      'walking': 'Walking',
      'indoor': 'Indoor',
      'culture': 'Culture',
      'nature': 'Nature',
      'forest': 'Forest',
      'waterfall': 'Waterfall',
      'aquarium': 'Aquarium',
      'rain_ok': 'Rain OK',
      'photo': 'Photo spot',
      'coastal': 'Coastal',
      'crater': 'Crater',
      'train': 'Train',
      'eco': 'Eco',
      'oreum': 'Oreum',
      'gotjawal': 'Gotjawal',
      'bbq': 'BBQ',
      'seafood': 'Seafood',
      'korean': 'Korean',
      'western': 'Western',
      'japanese': 'Japanese',
      'brunch': 'Brunch',
      'dessert': 'Dessert',
      'view': 'View',
      'roastery': 'Roastery',
      'traditional': 'Traditional',
      'unique': 'Unique',
    };
    const ja = {
      'UNESCO': 'UNESCO',
      'sunrise': '日の出',
      'volcanic': '火山',
      'garden': '庭園',
      'cave': '洞窟',
      'family': '家族向け',
      'beach': 'ビーチ',
      'free': '無料',
      'swimming': '水泳',
      'scenic': '絶景',
      'lighthouse': '灯台',
      'walking': '散歩',
      'indoor': '屋内',
      'culture': '文化',
      'nature': '自然',
      'forest': '森',
      'waterfall': '滝',
      'aquarium': '水族館',
      'rain_ok': '雨でもOK',
      'photo': '写真スポット',
      'coastal': '海岸',
      'crater': '火口',
      'train': '電車',
      'eco': '自然生態',
      'oreum': 'オルム',
      'gotjawal': 'ゴッチャウォル',
      'bbq': 'バーベキュー',
      'seafood': '海鮮',
      'korean': '韓国料理',
      'western': '洋食',
      'japanese': '和食',
      'brunch': 'ブランチ',
      'dessert': 'デザート',
      'view': '眺望',
      'roastery': 'ロースタリー',
      'traditional': '伝統',
      'unique': 'ユニーク',
    };
    const zh = {
      'UNESCO': 'UNESCO',
      'sunrise': '日出',
      'volcanic': '火山',
      'garden': '庭园',
      'cave': '洞窟',
      'family': '家庭游',
      'beach': '海滩',
      'free': '免费',
      'swimming': '游泳',
      'scenic': '美景',
      'lighthouse': '灯塔',
      'walking': '步行',
      'indoor': '室内',
      'culture': '文化',
      'nature': '自然',
      'forest': '森林',
      'waterfall': '瀑布',
      'aquarium': '水族馆',
      'rain_ok': '雨天可',
      'photo': '拍照打卡',
      'coastal': '海岸',
      'crater': '火山口',
      'train': '小火车',
      'eco': '生态',
      'oreum': '寄生火山',
      'gotjawal': '곶자왈',
      'bbq': '烧烤',
      'seafood': '海鲜',
      'korean': '韩餐',
      'western': '西餐',
      'japanese': '日料',
      'brunch': '早午餐',
      'dessert': '甜点',
      'view': '海景',
      'roastery': '精品咖啡',
      'traditional': '传统',
      'unique': '特色',
    };
    final result = switch (lang) {
      AppLanguage.ko => ko[tag],
      AppLanguage.en => en[tag],
      AppLanguage.ja => ja[tag],
      AppLanguage.zh => zh[tag],
    };
    // 번역이 없으면 null 반환 (태그 숨김)
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang2 = ref.watch(appLanguageProvider);
    final info = ref
        .watch(spotInfoProvider((spot.contentId, tourLanguageCode(lang2))))
        .valueOrNull;
    final spotTags = spot.tags.map((t) => t.toLowerCase()).toSet();
    final ctid = (spotTags.contains('restaurant') || spotTags.contains('cafe'))
        ? '39'
        : '12';
    final intro =
        ref.watch(spotIntroProvider((spot.contentId, ctid))).valueOrNull;

    // intro > info.usetime > spot.hours 순서로 영업시간 결정
    final apiHours = intro?.openTime.isNotEmpty == true
        ? localizeKoreanTourField(
            _cleanTourText(intro!.openTime),
            lang2,
            field: TourTextField.hours,
          )
        : info?.usetime.isNotEmpty == true
            ? localizeKoreanTourField(
                _cleanTourText(info!.usetime),
                lang2,
                field: TourTextField.hours,
              )
            : null;

    final visibleTags = spot.tags
        .where((t) => !_hiddenTags.contains(t))
        .map((t) => (tag: t, label: _localizedTag(t)))
        .where((e) => e.label != null)
        .take(3)
        .toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.greenBg.withValues(alpha: 0.55),
            AppColors.surfaceLow,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top: image + name + desc
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: ClaudeSpotImage(
                        spot: spot, height: 72, borderRadius: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spotDisplayName(spot, lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        spotDisplayDescription(spot, lang),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.text2,
                          height: 1.4,
                        ),
                      ),
                      if (visibleTags.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: visibleTags
                              .map((e) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      e.label!,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: AppColors.separator.withValues(alpha: 0.25),
          ),
          // bottom: hours + fee
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 14, color: AppColors.text3),
                const SizedBox(width: 5),
                Text(
                  _hoursText(apiHours),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: AppColors.text2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: spot.fee == 0
                        ? AppColors.greenBg
                        : AppColors.secondaryBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    _feeText(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: spot.fee == 0
                          ? AppColors.accent
                          : AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotLocationPreview extends StatelessWidget {
  const _SpotLocationPreview({required this.spot, required this.lang});

  final Spot spot;
  final AppLanguage lang;

  Offset _project(double lat, double lng, Size size) {
    return projectJejuLatLng(lat, lng, size);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: 1270 / 840,
        child: LayoutBuilder(builder: (ctx, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final pos = _project(spot.lat, spot.lng, size);
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/jeju.png', fit: BoxFit.fill),
              // halo
              Positioned(
                left: pos.dx - 22,
                top: pos.dy - 22,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.18),
                  ),
                ),
              ),
              // dot
              Positioned(
                left: pos.dx - 9,
                top: pos.dy - 9,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // label
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bg.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.accent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          spotDisplayName(spot, lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({required this.spot, required this.lang});

  final Spot spot;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _launchKakaoNavigation(context, spot, lang),
        icon: const Icon(Icons.navigation_rounded, size: 20),
        label: Text(_navigationLabel(lang)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent, width: 1.5),
          padding: EdgeInsets.zero,
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
    );
  }
}

Future<void> _launchKakaoNavigation(
    BuildContext context, Spot spot, AppLanguage lang) async {
  final destinationName = spotDisplayName(spot, lang);
  final appUri = Uri(
    scheme: 'kakaomap',
    host: 'route',
    queryParameters: {
      'ep': '${spot.lat},${spot.lng}',
      'ename': destinationName,
      'by': 'PUBLICTRANSIT',
    },
  );
  final webUri = Uri.https(
      'map.kakao.com', '/link/to/$destinationName,${spot.lat},${spot.lng}');

  if (await canLaunchUrl(appUri)) {
    await launchUrl(appUri, mode: LaunchMode.externalApplication);
    return;
  }

  if (await canLaunchUrl(webUri)) {
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
    return;
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(_navigationUnavailableLabel(lang)),
      backgroundColor: AppColors.accent,
    ),
  );
}

String _addToRouteLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '일정에 추가하기',
      AppLanguage.en => 'Add to route',
      AppLanguage.ja => '日程に追加',
      AppLanguage.zh => '添加到行程',
    };

String _updateRouteLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '일정 업데이트',
      AppLanguage.en => 'Update route',
      AppLanguage.ja => '日程を更新',
      AppLanguage.zh => '更新行程',
    };

String _navigationLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '네비게이션',
      AppLanguage.en => 'Navigation',
      AppLanguage.ja => 'ナビ',
      AppLanguage.zh => '导航',
    };

String _navigationUnavailableLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '카카오맵을 열 수 없습니다.',
      AppLanguage.en => 'Kakao Map could not be opened.',
      AppLanguage.ja => 'Kakao Mapを開けませんでした。',
      AppLanguage.zh => '无法打开 Kakao Map。',
    };

String _weatherAffectedLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '날씨 영향 있음',
      AppLanguage.en => 'Weather affected',
      AppLanguage.ja => '天候の影響あり',
      AppLanguage.zh => '受天气影响',
    };

String _goodToGoLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '방문하기 좋아요',
      AppLanguage.en => 'Good to go',
      AppLanguage.ja => '訪問しやすいです',
      AppLanguage.zh => '适合前往',
    };

String _indoorBackupLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '실내 대안 추천',
      AppLanguage.en => 'Indoor backup recommended',
      AppLanguage.ja => '屋内の代案をおすすめ',
      AppLanguage.zh => '建议准备室内备选',
    };

String _comfortableLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '편하게 둘러보기 좋아요',
      AppLanguage.en => 'Comfortable visit',
      AppLanguage.ja => '快適に見て回れます',
      AppLanguage.zh => '游览较舒适',
    };

String _weatherTipLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '날씨 팁',
      AppLanguage.en => 'Weather tip',
      AppLanguage.ja => '天気メモ',
      AppLanguage.zh => '天气提示',
    };

String _hoursLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '운영 시간',
      AppLanguage.en => 'Operating hours',
      AppLanguage.ja => '営業時間',
      AppLanguage.zh => '营业时间',
    };

String _cleanTourText(String value) {
  return value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .trim();
}

String _formatHours(String hours, AppLanguage lang) {
  if (hours.isEmpty || hours == 'All day' || hours == 'Open 24h') {
    return switch (lang) {
      AppLanguage.ko => '상시 개방',
      AppLanguage.en => 'Always open',
      AppLanguage.ja => '常時開放',
      AppLanguage.zh => '全天开放',
    };
  }
  if (hours == 'Check before visit') {
    return switch (lang) {
      AppLanguage.ko => '방문 전 확인',
      AppLanguage.en => 'Check before visit',
      AppLanguage.ja => '訪問前に確認',
      AppLanguage.zh => '出发前确认',
    };
  }
  return hours.replaceAll('-', ' – ');
}

String _openStatusLabel(AppLanguage lang, String hours) {
  if (hours.isEmpty || hours == 'All day') {
    return switch (lang) {
      AppLanguage.ko => '상시 개방',
      AppLanguage.en => 'Always open',
      AppLanguage.ja => '常時開放',
      AppLanguage.zh => '全天开放',
    };
  }
  // parse "HH:mm-HH:mm"
  final match =
      RegExp(r'(\d{1,2}):(\d{2})\s*[-–]\s*(\d{1,2}):(\d{2})').firstMatch(hours);
  if (match == null) {
    return switch (lang) {
      AppLanguage.ko => '방문 전 확인 권장',
      AppLanguage.en => 'Check before visit',
      AppLanguage.ja => '訪問前に確認',
      AppLanguage.zh => '出发前确认',
    };
  }
  final now = TimeOfDay.now();
  final openH = int.parse(match.group(1)!);
  final openM = int.parse(match.group(2)!);
  final closeH = int.parse(match.group(3)!);
  final closeM = int.parse(match.group(4)!);
  final nowMins = now.hour * 60 + now.minute;
  final openMins = openH * 60 + openM;
  final closeMins = closeH * 60 + closeM;
  final isOpen = nowMins >= openMins && nowMins < closeMins;
  if (isOpen) {
    return switch (lang) {
      AppLanguage.ko => '지금 영업 중',
      AppLanguage.en => 'Open now',
      AppLanguage.ja => '現在営業中',
      AppLanguage.zh => '现在营业中',
    };
  } else {
    return switch (lang) {
      AppLanguage.ko => '지금 영업 종료',
      AppLanguage.en => 'Closed now',
      AppLanguage.ja => '現在休業中',
      AppLanguage.zh => '现在休息中',
    };
  }
}

/// intro(detailIntro2) > info.usetime(detailCommon2) > spot.hours 순서로 영업시간 결정
String _resolveOpenTime(SpotIntroInfo? intro, SpotInfoEN? info,
    String spotHours, AppLanguage lang) {
  if (intro?.openTime.isNotEmpty == true) {
    return localizeKoreanTourField(
      _cleanTourText(intro!.openTime).replaceAll('-', ' - '),
      lang,
      field: TourTextField.hours,
    );
  }
  if (info?.usetime.isNotEmpty == true) {
    return localizeKoreanTourField(
      _cleanTourText(info!.usetime).replaceAll('-', ' - '),
      lang,
      field: TourTextField.hours,
    );
  }
  return _formatHours(spotHours, lang);
}

/// 휴무일: intro > info.restdate. 없으면 현재 영업 여부 표시
String _resolveRestDate(
    SpotIntroInfo? intro, SpotInfoEN? info, AppLanguage lang) {
  final restRaw = intro?.restDate.isNotEmpty == true
      ? intro!.restDate
      : info?.restdate.isNotEmpty == true
          ? info!.restdate
          : '';
  if (restRaw.isNotEmpty) {
    return '${_closedDayLabel(lang)}: '
        '${localizeKoreanTourField(
      _cleanTourText(restRaw),
      lang,
      field: TourTextField.closedDay,
    )}';
  }
  // 휴무 정보 없으면 현재 영업 여부 (openTime 기반)
  final openTimeRaw = intro?.openTime.isNotEmpty == true
      ? intro!.openTime
      : info?.usetime ?? '';
  return _openStatusLabel(lang, openTimeRaw);
}

String _menuLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '대표 메뉴',
      AppLanguage.en => 'Signature dish',
      AppLanguage.ja => '代表メニュー',
      AppLanguage.zh => '招牌菜',
    };

String _menuUnknownLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '방문 전 확인',
      AppLanguage.en => 'Check before visit',
      AppLanguage.ja => '訪問前に確認',
      AppLanguage.zh => '出发前确认',
    };

String _signatureDishLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '대표 음식',
      AppLanguage.en => 'Featured menu',
      AppLanguage.ja => '代表料理',
      AppLanguage.zh => '特色菜',
    };

String _freeLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '무료',
      AppLanguage.en => 'Free',
      AppLanguage.ja => '無料',
      AppLanguage.zh => '免费',
    };

String _feeLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '입장료',
      AppLanguage.en => 'Entrance fee',
      AppLanguage.ja => '入場料',
      AppLanguage.zh => '门票',
    };

String _checkBeforeVisitLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '방문 전 확인',
      AppLanguage.en => 'Check before visit',
      AppLanguage.ja => '訪問前に確認',
      AppLanguage.zh => '出发前确认',
    };

String _closedDayLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '휴무',
      AppLanguage.en => 'Closed',
      AppLanguage.ja => '定休日',
      AppLanguage.zh => '休息日',
    };

String _adultStandardLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '성인 기준',
      AppLanguage.en => 'Adult standard',
      AppLanguage.ja => '大人基準',
      AppLanguage.zh => '成人标准',
    };

String _overviewTitle(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '장소 소개',
      AppLanguage.en => 'About this place',
      AppLanguage.ja => 'スポット紹介',
      AppLanguage.zh => '景点介绍',
    };

String _transitAccessLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '대중교통 정보',
      AppLanguage.en => 'Transit access',
      AppLanguage.ja => '公共交通情報',
      AppLanguage.zh => '公共交通信息',
    };

class _HoursCard extends StatelessWidget {
  const _HoursCard({
    required this.openTime,
    required this.restDate,
    required this.lang,
  });

  final String openTime;
  final String restDate;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.accent, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hoursLabel(lang),
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text3),
                ),
                const SizedBox(height: 4),
                Text(
                  openTime,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text1,
                  ),
                ),
                if (restDate.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    restDate,
                    style:
                        GoogleFonts.inter(fontSize: 11, color: AppColors.text2),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailInfoCard extends StatelessWidget {
  const _DetailInfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary ? AppColors.greenBg : AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 25),
              const Spacer(),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text2),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                    fontSize: 17,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text1),
              ),
              const SizedBox(height: 3),
              Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      GoogleFonts.inter(fontSize: 10, color: AppColors.text3)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransitAccessCard extends StatelessWidget {
  const _TransitAccessCard({required this.spot, required this.lang});

  final Spot spot;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: AppColors.inverseSurface,
          borderRadius: BorderRadius.circular(28)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
                color: AppColors.accent, shape: BoxShape.circle),
            child:
                const Icon(Icons.directions_bus_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _transitAccessLabel(lang),
                  style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.inverseText),
                ),
                const SizedBox(height: 4),
                Text(
                  spot.nearestStop,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: AppColors.surfaceDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
