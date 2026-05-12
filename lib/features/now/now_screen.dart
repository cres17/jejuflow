import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../app.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spot_data.dart';
import '../../core/models/spot.dart';
import '../../core/models/weather.dart' hide TimeOfDay;
import '../../providers/app_providers.dart';
import '../../shared/widgets/app_ui.dart';

class NowScreen extends ConsumerStatefulWidget {
  const NowScreen({super.key});

  @override
  ConsumerState<NowScreen> createState() => _NowScreenState();
}

class _NowScreenState extends ConsumerState<NowScreen> {
  Offset _drag = Offset.zero;
  bool _loadLiveData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() => _loadLiveData = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final weatherAsync =
        _loadLiveData ? ref.watch(currentWeatherProvider) : null;
    final region = ref.watch(regionProvider);
    final spots = _loadLiveData
        ? ref.watch(filteredSpotsProvider)
        : kSpots.where((spot) => spot.region == region).toList();
    final apiSpots = _loadLiveData
        ? ref.watch(apiRecommendedSpotsProvider).valueOrNull ?? []
        : const <Spot>[];
    final routeDraft = ref.watch(routeDraftProvider);
    final skippedIds = ref.watch(skippedSpotIdsProvider);
    final lang = ref.watch(appLanguageProvider);
    final now = DateTime.now();
    final hour = now.hour + now.minute / 60;
    final weather = weatherAsync?.valueOrNull;
    final isIndoorFlow = weather?.isBad ?? false;
    final recommended = apiSpots.isNotEmpty
        ? apiSpots.where((s) => isIndoorFlow ? s.isIndoor : s.isOutdoor)
        : spots.where((s) => isIndoorFlow ? s.isIndoor : s.isOutdoor);
    final draftIds = routeDraft.map((spot) => spot.id).toSet();
    final cards = recommended
        .where((spot) => !draftIds.contains(spot.id))
        .where((spot) => !skippedIds.contains(spot.id))
        .fold<List<Spot>>([], (list, spot) {
          if (!list.any((existing) => existing.id == spot.id)) list.add(spot);
          return list;
        })
        .take(20)
        .toList();
    final top = cards.isEmpty ? null : cards.first;
    final sky =
        isIndoorFlow ? const Color(0xFFEAEAEA) : const Color(0xFFF7E9D0);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 370,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [sky, AppColors.bg],
                ),
              ),
              child: CustomPaint(
                  painter: _WeatherOverlayPainter(bad: isIndoorFlow)),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async {
                ref.read(appOpenSeedProvider.notifier).state =
                    DateTime.now().microsecondsSinceEpoch;
                ref.read(skippedSpotIdsProvider.notifier).state = {};
                ref.invalidate(weatherProvider);
                ref.invalidate(apiRecommendedSpotsProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 132),
                children: [
                  _Header(flowIndoor: isIndoorFlow, lang: lang, region: region),
                  const SizedBox(height: 12),
                  AppSunArc(
                    hour: hour,
                    temperature: weather?.temperature ?? '22°C',
                    weatherLabel: weather == null
                        ? weatherLabelFor(lang, WeatherCondition.clear)
                        : weatherLabelFor(lang, weather.condition),
                    weatherIcon: weather?.iconData ?? Icons.wb_sunny_rounded,
                    onHourChanged: (_) {},
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isIndoorFlow
                        ? _weatherIndoorCopy(lang)
                        : _weatherOutdoorCopy(lang),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.text2, height: 1.35),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(lang, 'todayFlow'),
                              style: appHeadingStyle(
                                lang,
                                fontSize: 27,
                                height: 1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              tr(lang, 'dragHint'),
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.text2),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${routeDraft.length} / ${cards.length}',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 11, color: AppColors.text3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ProgressDots(count: cards.length, index: 0),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 390,
                    child: top == null
                        ? _NoRecommendations(lang: lang)
                        : Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (var i = 2; i >= 0; i--)
                                if (i < cards.length)
                                  _StackedSpotCard(
                                    spot: cards[i],
                                    lang: lang,
                                    depth: i,
                                    drag: i == 0 ? _drag : Offset.zero,
                                    added: routeDraft
                                        .any((s) => s.id == cards[i].id),
                                    onDragUpdate: (delta) =>
                                        setState(() => _drag += delta),
                                    onDragEnd: () => _finishDrag(cards, lang),
                                    onOpen: () {
                                      ref
                                          .read(selectedSpotProvider.notifier)
                                          .state = cards[i];
                                      ref
                                          .read(tabIndexProvider.notifier)
                                          .state = 1;
                                    },
                                  ),
                              Positioned(
                                left: 8,
                                right: 8,
                                bottom: -22,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('??skip',
                                        style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10,
                                            color: AppColors.text3)),
                                    Text('??add to route',
                                        style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10,
                                            color: AppColors.tertiary,
                                            fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finishDrag(List<Spot> cards, AppLanguage lang) async {
    if (cards.isEmpty) return;
    final top = cards.first;
    if (_drag.dy < -80) {
      setState(() => _drag = Offset.zero);
      final result = await showDialog<({bool added, DateTime? scheduledAt})>(
        context: context,
        builder: (ctx) => _AddSpotDialog(spot: top, lang: lang),
      );
      if (result != null && result.added) {
        final draft = ref.read(routeDraftProvider);
        if (!draft.any((s) => s.id == top.id)) {
          ref.read(routeDraftProvider.notifier).state = [...draft, top];
        }
        if (result.scheduledAt != null) {
          final schedule =
              Map<String, DateTime>.from(ref.read(routeDraftScheduleProvider));
          schedule[top.id] = result.scheduledAt!;
          ref.read(routeDraftScheduleProvider.notifier).state = schedule;
        }
        _settleCurrent();
      }
      return;
    }
    if (_drag.dy > 80) {
      ref.read(skippedSpotIdsProvider.notifier).state = {
        ...ref.read(skippedSpotIdsProvider),
        top.id,
      };
      _settleCurrent();
      return;
    }
    setState(() => _drag = Offset.zero);
  }

  void _settleCurrent() {
    setState(() {
      _drag = Offset.zero;
    });
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.flowIndoor,
    required this.lang,
    required this.region,
  });

  final bool flowIndoor;
  final AppLanguage lang;
  final SpotRegion region;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'JEJUFLOW',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: AppColors.text2,
              ),
            ),
            const SizedBox(height: 3),
            Text(regionLabelFor(lang, region),
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.text2)),
          ],
        ),
        const Spacer(),
        AppChip(
          label: flowIndoor ? _indoorLabel(lang) : _outdoorLabel(lang),
          active: true,
          tone: flowIndoor ? AppChipTone.secondary : AppChipTone.primary,
        ),
      ],
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: active ? 18 : 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: i < index
                ? AppColors.accent
                : active
                    ? AppColors.tertiary
                    : AppColors.separator,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

String _weatherIndoorCopy(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '날씨가 거칠어요. 실내에서 천천히 둘러보세요.',
      AppLanguage.en => 'Weather is rough. Stay slow, stay in.',
      AppLanguage.ja => '天気が荒れています。屋内でゆっくり過ごしましょう。',
      AppLanguage.zh => '天气不太好。建议慢慢逛室内景点。',
    };

String _weatherOutdoorCopy(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '야외 활동하기 좋아요. 버스로 편하게 이동해보세요.',
      AppLanguage.en => 'Clear enough outside. Follow the easy bus flow.',
      AppLanguage.ja => '屋外でも過ごしやすいです。バスで気軽に移動しましょう。',
      AppLanguage.zh => '适合户外活动。可以轻松搭乘巴士移动。',
    };

String _indoorLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '실내',
      AppLanguage.en => 'Indoor',
      AppLanguage.ja => '屋内',
      AppLanguage.zh => '室内',
    };

String _outdoorLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '야외',
      AppLanguage.en => 'Outdoor',
      AppLanguage.ja => '屋外',
      AppLanguage.zh => '户外',
    };

class _StackedSpotCard extends StatelessWidget {
  const _StackedSpotCard({
    required this.spot,
    required this.lang,
    required this.depth,
    required this.drag,
    required this.added,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onOpen,
  });

  final Spot spot;
  final AppLanguage lang;
  final int depth;
  final Offset drag;
  final bool added;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isTop = depth == 0;
    final offsetY = depth * 14.0;
    final scale = 1 - depth * 0.04;
    return AnimatedPositioned(
      duration: isTop && drag != Offset.zero
          ? Duration.zero
          : const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      top: 8 + offsetY + (isTop ? drag.dy : 0),
      left: 0,
      right: 0,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: depth == 2 ? 0.58 : 1,
          child: GestureDetector(
            onTap: onOpen,
            onPanUpdate:
                isTop ? (details) => onDragUpdate(details.delta) : null,
            onPanEnd: isTop ? (_) => onDragEnd() : null,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                    color: AppColors.separator.withValues(alpha: 0.75)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.text1.withValues(alpha: 0.08),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSpotImage(spot: spot),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spotDisplayName(spot, lang),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: appHeadingStyle(
                                lang,
                                fontSize: 22,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              spotDisplayDescription(spot, lang),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  height: 1.35,
                                  color: AppColors.text2),
                            ),
                          ],
                        ),
                      ),
                      if (added)
                        const AppChip(
                            label: 'Added', tone: AppChipTone.primary),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppChip(
                          label: _spotCategoryLabel(lang, spot.category),
                          tone: AppChipTone.primary),
                      AppChip(
                          label: _spotTransitLabel(lang, spot),
                          tone: AppChipTone.outline,
                          icon: Icons.directions_bus),
                      AppChip(
                          label: _spotTypeLabel(lang, spot),
                          tone: AppChipTone.tertiary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _spotCategoryLabel(AppLanguage lang, SpotCategory category) {
  return switch ((lang, category)) {
    (AppLanguage.ko, SpotCategory.outdoor) => '야외',
    (AppLanguage.ko, SpotCategory.indoor) => '실내',
    (AppLanguage.ko, SpotCategory.both) => '실내/야외',
    (AppLanguage.ja, SpotCategory.outdoor) => '屋外',
    (AppLanguage.ja, SpotCategory.indoor) => '屋内',
    (AppLanguage.ja, SpotCategory.both) => '屋内/屋外',
    (AppLanguage.zh, SpotCategory.outdoor) => '户外',
    (AppLanguage.zh, SpotCategory.indoor) => '室内',
    (AppLanguage.zh, SpotCategory.both) => '室内/户外',
    (AppLanguage.en, SpotCategory.outdoor) => 'Outdoor',
    (AppLanguage.en, SpotCategory.indoor) => 'Indoor',
    (AppLanguage.en, SpotCategory.both) => 'Indoor/Outdoor',
  };
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

class _NoRecommendations extends StatelessWidget {
  const _NoRecommendations({required this.lang});

  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Flow complete!',
              style: appHeadingStyle(lang,
                  fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('No more recommended spots right now',
              style: appBodyStyle(lang, fontSize: 13, color: AppColors.text2)),
        ],
      ),
    );
  }
}

class _WeatherOverlayPainter extends CustomPainter {
  const _WeatherOverlayPainter({required this.bad});

  final bool bad;

  @override
  void paint(Canvas canvas, Size size) {
    if (bad) {
      final paint = Paint()
        ..color = const Color(0xFF5A7E96).withValues(alpha: 0.18)
        ..strokeWidth = 1;
      for (var i = 0; i < 24; i++) {
        final x = (i * 53 + 11) % size.width;
        final y = (i * 89 + 17) % size.height;
        canvas.drawLine(Offset(x, y), Offset(x - 4, y + 14), paint);
      }
    } else {
      canvas.drawCircle(
        Offset(size.width * .86, 34),
        108,
        Paint()..color = const Color(0xFFFFB597).withValues(alpha: 0.24),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherOverlayPainter oldDelegate) =>
      oldDelegate.bad != bad;
}

class _AddSpotDialog extends StatefulWidget {
  const _AddSpotDialog({required this.spot, required this.lang});

  final Spot spot;
  final AppLanguage lang;

  @override
  State<_AddSpotDialog> createState() => _AddSpotDialogState();
}

class _AddSpotDialogState extends State<_AddSpotDialog> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String get _scheduleLabel {
    if (_selectedDate == null) return '';
    final dateFmt = DateFormat('MMM d (EEE)').format(_selectedDate!);
    if (_selectedTime == null) return dateFmt;
    final h = _selectedTime!.hour.toString().padLeft(2, '0');
    final m = _selectedTime!.minute.toString().padLeft(2, '0');
    return '$dateFmt  $h:$m';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  DateTime? get _scheduledAt {
    if (_selectedDate == null) return null;
    final t = _selectedTime;
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      t?.hour ?? 0,
      t?.minute ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Dialog(
      backgroundColor: AppColors.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(lang, 'addQuestion'),
              style: appHeadingStyle(lang,
                  fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              spotDisplayName(widget.spot, lang),
              style: appBodyStyle(lang, fontSize: 14, color: AppColors.text2),
            ),
            const SizedBox(height: 20),
            Text(
              tr(lang, 'scheduleFor'),
              style: appBodyStyle(lang,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text3),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _selectedDate != null
                                ? AppColors.accent
                                : AppColors.separator),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 16,
                              color: _selectedDate != null
                                  ? AppColors.accent
                                  : AppColors.text3),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDate == null
                                  ? tr(lang, 'selectDate')
                                  : DateFormat('MMM d (EEE)')
                                      .format(_selectedDate!),
                              style: appBodyStyle(lang,
                                  fontSize: 13,
                                  color: _selectedDate != null
                                      ? AppColors.text1
                                      : AppColors.text3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _selectedTime != null
                              ? AppColors.accent
                              : AppColors.separator),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 16,
                            color: _selectedTime != null
                                ? AppColors.accent
                                : AppColors.text3),
                        const SizedBox(width: 6),
                        Text(
                          _selectedTime == null
                              ? tr(lang, 'selectTime')
                              : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                          style: appBodyStyle(lang,
                              fontSize: 13,
                              color: _selectedTime != null
                                  ? AppColors.text1
                                  : AppColors.text3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_scheduleLabel.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.greenBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(_scheduleLabel,
                        style: appBodyStyle(lang,
                            fontSize: 12,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, (added: false, scheduledAt: null)),
                  child: Text(tr(lang, 'cancel'),
                      style: appBodyStyle(lang,
                          fontSize: 14, color: AppColors.text2)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                      context, (added: true, scheduledAt: _scheduledAt)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  child: Text(tr(lang, 'add'),
                      style: appHeadingStyle(lang,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
