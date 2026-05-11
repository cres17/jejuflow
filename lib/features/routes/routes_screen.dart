import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spot_data.dart';
import '../../core/models/saved_route.dart';
import '../../core/models/spot.dart';
import '../../core/utils/jeju_map_projection.dart';
import '../../core/utils/route_utils.dart';
import '../../providers/app_providers.dart';

// ─── Design tokens (mirrors jf-tokens.jsx EG palette) ────────────────────────
class _C {
  static const surface = Color(0xFFFCF9F2);
  static const surfaceLow = Color(0xFFF6F3ED);
  static const surfaceCt = Color(0xFFF0EEE7);
  static const ink = Color(0xFF1C1C18);
  static const ink2 = Color(0xFF444844);
  static const outline = Color(0xFF757873);
  static const outlineV = Color(0xFFC5C7C2);
  static const primary = Color(0xFF4B6450);
  static const primaryC = Color(0xFFDAF7DD);
  static const onPrimaryC = Color(0xFF334C3A);
  static const tertiary = Color(0xFFA43D00);
}

class RoutesScreen extends ConsumerStatefulWidget {
  const RoutesScreen({super.key});

  @override
  ConsumerState<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends ConsumerState<RoutesScreen> {
  String? _selectedDateKey;
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(savedRoutesProvider);
    final lang = ref.watch(appLanguageProvider);

    return Scaffold(
      backgroundColor: _C.surface,
      body: SafeArea(
        child: routesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _C.primary)),
          error: (_, __) => const SizedBox.shrink(),
          data: (routes) {
            final grouped = <String, List<SavedRoute>>{};
            for (final r in routes) {
              grouped
                  .putIfAbsent(
                      DateFormat('yyyy-MM-dd').format(r.savedAt), () => [])
                  .add(r);
            }
            final dateKeys = grouped.keys.toList()..sort();

            if ((_selectedDateKey == null ||
                    !dateKeys.contains(_selectedDateKey)) &&
                dateKeys.isNotEmpty) {
              final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
              _selectedDateKey = dateKeys.lastWhere(
                (k) => k.compareTo(today) <= 0,
                orElse: () => dateKeys.first,
              );
            }

            final selectedRoutes = _selectedDateKey != null
                ? (grouped[_selectedDateKey] ?? [])
                : <SavedRoute>[];
            final plan = buildDayPlan(selectedRoutes, kSpotById);
            final totalSpots = selectedRoutes.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                _Header(
                  lang: lang,
                  spotCount: totalSpots,
                  editMode: _editMode,
                  hasRoutes: routes.isNotEmpty,
                  onToggleEdit: () => setState(() => _editMode = !_editMode),
                ),

                // ── Jeju map ─────────────────────────────────────────────
                if (selectedRoutes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _JejuMapSection(routes: selectedRoutes, lang: lang),
                ],

                // ── Date tabs ─────────────────────────────────────────────
                if (dateKeys.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _DateTabBar(
                    dateKeys: dateKeys,
                    selected: _selectedDateKey,
                    onSelect: (k) => setState(() {
                      _selectedDateKey = k;
                      _editMode = false;
                    }),
                  ),
                ],

                if (_editMode && selectedRoutes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    child: Row(children: [
                      const Icon(Icons.drag_handle_rounded,
                          size: 14, color: _C.outline),
                      const SizedBox(width: 6),
                      Text(_dragHint(lang),
                          style: GoogleFonts.inter(
                              fontSize: 11, color: _C.outline)),
                    ]),
                  ),

                const SizedBox(height: 10),

                // ── List ─────────────────────────────────────────────────
                Expanded(
                  child: routes.isEmpty
                      ? _EmptyState(lang: lang)
                      : selectedRoutes.isEmpty
                          ? const SizedBox.shrink()
                          : _editMode
                              ? _buildReorderableList(
                                  context, plan, lang, selectedRoutes)
                              : _buildTimelineList(plan, lang),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimelineList(List<DayPlanItem> plan, AppLanguage lang) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      itemCount: plan.length,
      itemBuilder: (ctx, i) => _TimelineRow(
        item: plan[i],
        index: i,
        total: plan.length,
        lang: lang,
        editMode: false,
        onDelete: null,
        onNavigate: () => _navigateRoute(plan[i].route),
        onOpen: () => _useRoute(plan[i].route),
      ),
    );
  }

  Widget _buildReorderableList(BuildContext context, List<DayPlanItem> plan,
      AppLanguage lang, List<SavedRoute> selectedRoutes) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      onReorder: (o, n) => ref.read(savedRoutesProvider.notifier).reorder(o, n),
      proxyDecorator: (child, _, __) => Material(
          color: Colors.transparent,
          elevation: 10,
          borderRadius: BorderRadius.circular(24),
          child: child),
      itemCount: plan.length,
      itemBuilder: (ctx, i) => _TimelineRow(
        key: ValueKey(plan[i].route.id),
        item: plan[i],
        index: i,
        total: plan.length,
        lang: lang,
        editMode: true,
        onDelete: () =>
            ref.read(savedRoutesProvider.notifier).remove(plan[i].route.id),
        onNavigate: () => _navigateRoute(plan[i].route),
        onOpen: () => _useRoute(plan[i].route),
      ),
    );
  }

  void _useRoute(SavedRoute route) {
    final spot = _spotFromRoute(route);
    if (spot != null) {
      ref.read(selectedSpotProvider.notifier).state = spot;
      ref.read(tabIndexProvider.notifier).state = 1;
    }
  }

  Future<void> _navigateRoute(SavedRoute route) async {
    final lang = ref.read(appLanguageProvider);
    final spot = kSpotById[route.spotId];
    final lat = spot?.lat ?? route.lat;
    final lng = spot?.lng ?? route.lng;
    if (lat == null || lng == null) return;
    final name = spot == null
        ? _localizedRouteName(route, lang)
        : spotDisplayName(spot, lang);
    final appUri = Uri(scheme: 'kakaomap', host: 'route', queryParameters: {
      'ep': '$lat,$lng',
      'ename': name,
      'by': 'PUBLICTRANSIT'
    });
    final webUri = Uri.https('map.kakao.com', '/link/to/$name,$lat,$lng');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
      return;
    }
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_navUnavailable(lang)),
      backgroundColor: _C.primary,
    ));
  }

  // ignore: unused_element
  Future<void> _rescheduleRoute(SavedRoute route) async {
    final pickedDate = await showDatePicker(
        context: context,
        initialDate: route.savedAt,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 365)));
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(route.savedAt));
    if (pickedTime == null) return;
    final scheduled = DateTime(pickedDate.year, pickedDate.month,
        pickedDate.day, pickedTime.hour, pickedTime.minute);
    await ref
        .read(savedRoutesProvider.notifier)
        .reschedule(route.id, scheduled);
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.lang,
    required this.spotCount,
    required this.editMode,
    required this.hasRoutes,
    required this.onToggleEdit,
  });
  final AppLanguage lang;
  final int spotCount;
  final bool editMode;
  final bool hasRoutes;
  final VoidCallback onToggleEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _routeLabel(lang).toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12 * 11,
                  color: _C.ink2,
                ),
              ),
              const Spacer(),
              if (hasRoutes)
                GestureDetector(
                  onTap: onToggleEdit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: editMode ? _C.primary : _C.surfaceLow,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: editMode ? _C.primary : _C.outlineV,
                      ),
                    ),
                    child: Text(
                      editMode ? 'DONE' : 'EDIT',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.12 * 11,
                        color: editMode ? Colors.white : _C.ink2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // big spot count
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$spotCount',
                      style: GoogleFonts.montserrat(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.03 * 40,
                        height: 1,
                        color: _C.ink,
                      ),
                    ),
                    TextSpan(
                      text: '  ${_spotsWord(lang, spotCount)}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _C.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Jeju Map ──────────────────────────────────────────────────────────────────

class _JejuMapSection extends StatelessWidget {
  const _JejuMapSection({required this.routes, required this.lang});
  final List<SavedRoute> routes;
  final AppLanguage lang;

  Offset _project(double lat, double lng, Size size) {
    return projectJejuLatLng(lat, lng, size);
  }

  @override
  Widget build(BuildContext context) {
    final spots = routes.where((r) => r.lat != null && r.lng != null).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _C.outlineV),
          boxShadow: [
            BoxShadow(
              color: _C.ink.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(builder: (ctx, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final pinPositions = _spreadPinPositions(spots, size);
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/jeju.png', fit: BoxFit.fill),
              // route line
              if (spots.length > 1)
                CustomPaint(
                  painter: _RoutePainter(spots, size, _project),
                ),
              // pins
              for (var i = 0; i < spots.length; i++)
                _MapPin(
                  route: spots[i],
                  index: i,
                  position: pinPositions[i],
                ),
              // MAP label pill
              Positioned(
                top: 12,
                left: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _C.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _C.outlineV),
                  ),
                  child: Text(
                    _mapLabel(lang).toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _C.ink,
                      letterSpacing: 0.04 * 10,
                    ),
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

List<Offset> _spreadPinPositions(List<SavedRoute> routes, Size size) {
  final positions = routes
      .map((route) => projectJejuLatLng(route.lat!, route.lng!, size))
      .toList();
  final adjusted = <Offset>[];
  const minDistance = 18.0;

  for (var i = 0; i < positions.length; i++) {
    var position = positions[i];
    var collisionCount = 0;
    for (final previous in adjusted) {
      if ((position - previous).distance < minDistance) collisionCount++;
    }
    if (collisionCount > 0) {
      final angle = (collisionCount * 70 + i * 31) * math.pi / 180;
      final radius = 12.0 + collisionCount * 4.0;
      position = Offset(
        (position.dx + math.cos(angle) * radius).clamp(12.0, size.width - 12.0),
        (position.dy + math.sin(angle) * radius)
            .clamp(12.0, size.height - 12.0),
      );
    }
    adjusted.add(position);
  }

  return adjusted;
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter(this.routes, this.size, this.project);
  final List<SavedRoute> routes;
  final Size size;
  final Offset Function(double, double, Size) project;

  @override
  void paint(Canvas canvas, Size sz) {
    if (routes.length < 2) return;
    final pts = routes.map((r) => project(r.lat!, r.lng!, sz)).toList();
    final paint = Paint()
      ..color = _C.primary.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) => old.routes != routes;
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.route,
    required this.index,
    required this.position,
  });
  final SavedRoute route;
  final int index;
  final Offset position;

  @override
  Widget build(BuildContext context) {
    final isFirst = index == 0;
    return Positioned(
      left: position.dx - 10,
      top: position.dy - 10,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isFirst ? _C.tertiary : _C.primary,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '${index + 1}',
          style: GoogleFonts.jetBrainsMono(
              fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
  }
}

// ── Date Tab Bar ──────────────────────────────────────────────────────────────

class _DateTabBar extends StatelessWidget {
  const _DateTabBar({
    required this.dateKeys,
    required this.selected,
    required this.onSelect,
  });
  final List<String> dateKeys;
  final String? selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: dateKeys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (ctx, i) {
          final key = dateKeys[i];
          final isSelected = key == selected;
          return GestureDetector(
            onTap: () => onSelect(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? _C.ink : _C.surfaceLow,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                DateFormat('M/d (E)').format(DateTime.parse(key)).toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.02 * 11,
                  color: isSelected ? _C.surface : _C.ink2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Timeline Row ──────────────────────────────────────────────────────────────

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    super.key,
    required this.item,
    required this.index,
    required this.total,
    required this.lang,
    required this.editMode,
    required this.onDelete,
    required this.onNavigate,
    required this.onOpen,
  });

  final DayPlanItem item;
  final int index;
  final int total;
  final AppLanguage lang;
  final bool editMode;
  final VoidCallback? onDelete;
  final VoidCallback onNavigate;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final route = item.route;
    final isFirst = index == 0;
    final isLast = index == total - 1;
    final dotColor = isFirst ? _C.tertiary : _C.surface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── index column ─────────────────────────────────────
          SizedBox(
            width: 32,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _C.ink,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ── dot + vertical line ───────────────────────────────
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: Border.all(color: _C.primary, width: 2),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 82,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _C.outlineV,
                          _C.outlineV.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ── card ──────────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: editMode ? null : onOpen,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: _C.surfaceLow,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        // drag handle (edit mode only)
                        if (editMode)
                          ReorderableDragStartListener(
                            index: index,
                            child: Container(
                              width: 28,
                              height: 90,
                              decoration: const BoxDecoration(
                                color: _C.surfaceCt,
                                borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(24)),
                              ),
                              child: const Icon(Icons.drag_indicator_rounded,
                                  size: 16, color: _C.outline),
                            ),
                          ),

                        // photo
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(editMode ? 0 : 24),
                            bottomLeft: Radius.circular(editMode ? 0 : 24),
                          ),
                          child: SizedBox(
                            width: 72,
                            height: 90,
                            child: route.photoUrl != null
                                ? Image.network(
                                    route.photoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _PhotoFallback(route: route),
                                  )
                                : _PhotoFallback(route: route),
                          ),
                        ),

                        // info
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 40, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _displayRouteName(route, lang),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.01 * 15,
                                    color: _C.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _categoryText(route.spotId, lang),
                                  style: GoogleFonts.inter(
                                      fontSize: 11, color: _C.ink2),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  kSpotById[route.spotId]?.hours ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10, color: _C.outline),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // delete button — bottom right (edit mode only)
                  if (editMode)
                    Positioned(
                      bottom: 24,
                      right: 10,
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFBA1A1A),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  // nav button — bottom right (normal mode only)
                  if (!editMode)
                    Positioned(
                      bottom: 24,
                      right: 10,
                      child: GestureDetector(
                        onTap: onNavigate,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _C.primaryC,
                          ),
                          child: const Icon(Icons.near_me_rounded,
                              size: 13, color: _C.onPrimaryC),
                        ),
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

  static String _categoryText(String spotId, AppLanguage lang) {
    final tags =
        kSpotById[spotId]?.tags.map((t) => t.toLowerCase()).toSet() ?? {};
    if (tags.contains('restaurant')) {
      return switch (lang) {
        AppLanguage.ko => '음식점',
        AppLanguage.en => 'Restaurant',
        AppLanguage.ja => 'レストラン',
        AppLanguage.zh => '餐厅',
      };
    }
    if (tags.contains('cafe')) {
      return switch (lang) {
        AppLanguage.ko => '카페',
        AppLanguage.en => 'Café',
        AppLanguage.ja => 'カフェ',
        AppLanguage.zh => '咖啡厅',
      };
    }
    if (tags.contains('oreum') || tags.contains('오름')) {
      return switch (lang) {
        AppLanguage.ko => '오름',
        AppLanguage.en => 'Oreum',
        AppLanguage.ja => '오름',
        AppLanguage.zh => '山丘',
      };
    }
    return switch (lang) {
      AppLanguage.ko => '관광지',
      AppLanguage.en => 'Attraction',
      AppLanguage.ja => '観光地',
      AppLanguage.zh => '景点',
    };
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.route});
  final SavedRoute route;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.surfaceCt,
      alignment: Alignment.center,
      child: Text(route.spotEmoji, style: const TextStyle(fontSize: 26)),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.lang});
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: _C.surfaceLow,
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.outlineV, width: 1.5)),
              child:
                  const Icon(Icons.map_outlined, size: 32, color: _C.outline),
            ),
            const SizedBox(height: 20),
            Text(
              _emptyTitle(lang),
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.02 * 18,
                color: _C.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _emptySub(lang),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: _C.ink2),
            ),
          ],
        ),
      ),
    );
  }
}

// ── helpers ───────────────────────────────────────────────────────────────────

Spot? _spotFromRoute(SavedRoute route) {
  final local = kSpotById[route.spotId];
  if (local != null) return local;
  final lat = route.lat;
  final lng = route.lng;
  if (lat == null || lng == null) return null;
  return Spot(
    id: route.spotId,
    nameEn: route.spotName,
    emoji: route.spotEmoji,
    sub: '',
    category: SpotCategory.outdoor,
    region: lat < 33.33 ? SpotRegion.seogwipo : SpotRegion.jejuCity,
    nearestStop: '',
    stopId: '',
    busRoutes: const ['KakaoMap'],
    walkMinutes: 8,
    busWaitMinutes: route.totalMinutes,
    bgColor: AppColors.greenBg,
    accentColor: route.accent,
    fee: route.fee,
    hours: 'Check before visit',
    tags: const ['api', 'saved'],
    altSpotId: null,
    contentId: route.contentId ?? '',
    lat: lat,
    lng: lng,
  )..photoUrl = route.photoUrl;
}

String _localizedRouteName(SavedRoute route, AppLanguage lang) {
  final source =
      route.koreanName?.isNotEmpty == true ? route.koreanName! : route.spotName;
  return localizeKoreanTourText(source, lang, titleCase: true);
}

String _displayRouteName(SavedRoute route, AppLanguage lang) {
  final spot = kSpotById[route.spotId];
  if (spot != null) return spotDisplayName(spot, lang);
  return _localizedRouteName(route, lang);
}

String _routeLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '여정',
      AppLanguage.en => 'Route',
      AppLanguage.ja => 'ルート',
      AppLanguage.zh => '路线',
    };

String _spotsWord(AppLanguage lang, int n) => switch (lang) {
      AppLanguage.ko => '곳',
      AppLanguage.en => n == 1 ? 'spot' : 'spots',
      AppLanguage.ja => 'ヶ所',
      AppLanguage.zh => '处',
    };

String _mapLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '지도',
      AppLanguage.en => 'Map',
      AppLanguage.ja => '地図',
      AppLanguage.zh => '地图',
    };

String _dragHint(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '길게 눌러 드래그해서 순서를 바꾸세요',
      AppLanguage.en => 'Long-press to drag and reorder',
      AppLanguage.ja => '長押しでドラッグして並べ替え',
      AppLanguage.zh => '长按拖动以调整顺序',
    };

String _navUnavailable(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '카카오맵을 열 수 없습니다.',
      AppLanguage.en => 'Kakao Map could not be opened.',
      AppLanguage.ja => 'Kakao Mapを開けませんでした。',
      AppLanguage.zh => '无法打开 Kakao Map。',
    };

String _emptyTitle(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '아직 비어있어요',
      AppLanguage.en => 'Empty for now',
      AppLanguage.ja => 'まだ空です',
      AppLanguage.zh => '尚为空',
    };

String _emptySub(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => 'Move 탭에서 관광지를 추가해보세요',
      AppLanguage.en => 'Add spots from the Move tab',
      AppLanguage.ja => '移動タブからスポットを追加',
      AppLanguage.zh => '从移动页添加景点',
    };
