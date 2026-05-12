import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/colors.dart';
import '../../core/models/spot.dart';
import '../../providers/app_providers.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.active = false,
    this.tone = AppChipTone.primary,
    this.icon,
  });

  final String label;
  final bool active;
  final AppChipTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      AppChipTone.primary => (AppColors.greenBg, AppColors.accent),
      AppChipTone.secondary => (AppColors.secondaryBg, AppColors.secondary),
      AppChipTone.tertiary => (AppColors.yellowBg, AppColors.tertiary),
      AppChipTone.outline => (Colors.transparent, AppColors.text2),
    };
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: active ? colors.$2 : colors.$1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: tone == AppChipTone.outline
                ? AppColors.separator
                : Colors.transparent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: active ? Colors.white : colors.$2),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : colors.$2,
            ),
          ),
        ],
      ),
    );
  }
}

enum AppChipTone { primary, secondary, tertiary, outline }

class AppSunArc extends StatelessWidget {
  const AppSunArc({
    super.key,
    required this.hour,
    required this.temperature,
    required this.weatherLabel,
    required this.weatherIcon,
    required this.onHourChanged,
  });

  final double hour;
  final String temperature;
  final String weatherLabel;
  final IconData weatherIcon;
  final ValueChanged<double> onHourChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: (details) => _update(context, details.localPosition),
      onPanUpdate: (details) => _update(context, details.localPosition),
      child: SizedBox(
        height: 172,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SunArcPainter(hour: hour),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  temperature,
                  style: GoogleFonts.montserrat(
                    fontSize: 56,
                    height: 0.96,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${hour.floor().toString().padLeft(2, '0')}:${((hour % 1) * 60).round().toString().padLeft(2, '0')}',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.text2,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 7),
                    Icon(weatherIcon, size: 17, color: AppColors.tertiary),
                    const SizedBox(width: 5),
                    Text(weatherLabel,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.text2)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _update(BuildContext context, Offset position) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final cx = size.width / 2;
    const cy = 136.0;
    final dx = position.dx - cx;
    final dy = cy - position.dy;
    var angle = math.atan2(dy, dx);
    angle = angle.clamp(0, math.pi);
    final next = 6 + ((math.pi - angle) / math.pi) * 14;
    onHourChanged((next * 2).round() / 2);
  }
}

class _SunArcPainter extends CustomPainter {
  const _SunArcPainter({required this.hour});

  final double hour;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const cy = 136.0;
    final radius = math.min(size.width * 0.36, 132.0);
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = const LinearGradient(
        colors: [AppColors.separator, AppColors.tertiary, AppColors.separator],
      ).createShader(rect);

    canvas.drawLine(
        Offset(cx - radius, cy),
        Offset(cx + radius, cy),
        Paint()
          ..color = AppColors.separator
          ..strokeWidth = 1);
    canvas.drawArc(rect, math.pi, math.pi, false, base);

    for (final h in [6, 9, 12, 15, 18]) {
      final angle = (180 - ((h - 6) / 14) * 180) * math.pi / 180;
      final a = Offset(cx + math.cos(angle) * (radius - 8),
          cy - math.sin(angle) * (radius - 8));
      final b = Offset(cx + math.cos(angle) * (radius + 5),
          cy - math.sin(angle) * (radius + 5));
      canvas.drawLine(
          a,
          b,
          Paint()
            ..color = AppColors.text3.withValues(alpha: 0.55)
            ..strokeWidth = 1);
    }

    final norm = hour.clamp(6, 20);
    final angle = (180 - ((norm - 6) / 14) * 180) * math.pi / 180;
    final sun =
        Offset(cx + math.cos(angle) * radius, cy - math.sin(angle) * radius);
    canvas.drawCircle(sun, 15, Paint()..color = AppColors.bg);
    canvas.drawCircle(
      sun,
      15,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.tertiary,
    );
    canvas.drawCircle(sun, 4.5, Paint()..color = AppColors.tertiary);
  }

  @override
  bool shouldRepaint(covariant _SunArcPainter oldDelegate) =>
      oldDelegate.hour != hour;
}

class AppSpotImage extends ConsumerWidget {
  const AppSpotImage(
      {super.key,
      required this.spot,
      this.height = 170,
      this.borderRadius = 24});

  final Spot spot;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerPhoto = ref.watch(spotPhotoUrlProvider(spot.id));
    final photoUrl =
        spot.photoUrl?.isNotEmpty == true ? spot.photoUrl : providerPhoto;
    final tone = switch (spot.category) {
      SpotCategory.indoor => (AppColors.surface3, AppColors.surfaceDim),
      SpotCategory.both => (AppColors.secondaryBg, const Color(0xFFE7B49C)),
      SpotCategory.outdoor => (AppColors.greenBg, AppColors.greenBgDim),
    };
    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tone.$1,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Stack(
        children: [
          if (photoUrl != null && photoUrl.isNotEmpty)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    CustomPaint(painter: _StripePainter(color: tone.$2)),
              ),
            )
          else
            Positioned.fill(
              child: _SpotImageFallback(
                color: tone.$2,
                category: spot.category,
              ),
            ),
          if (photoUrl != null && photoUrl.isNotEmpty)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.text1.withValues(alpha: 0.42),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 14,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.bg.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                spot.category.name.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: AppColors.text1.withValues(alpha: 0.58),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 14,
            child: Text(spot.emoji, style: const TextStyle(fontSize: 30)),
          ),
        ],
      ),
    );
  }
}

class _SpotImageFallback extends StatelessWidget {
  const _SpotImageFallback({required this.color, required this.category});

  final Color color;
  final SpotCategory category;

  @override
  Widget build(BuildContext context) {
    final icon = switch (category) {
      SpotCategory.indoor => Icons.museum_rounded,
      SpotCategory.both => Icons.attractions_rounded,
      SpotCategory.outdoor => Icons.terrain_rounded,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.72),
            AppColors.bg.withValues(alpha: 0.86),
            AppColors.tertiary.withValues(alpha: 0.22),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _StripePainter(color: color),
        child: Center(
          child: Icon(
            icon,
            size: 42,
            color: AppColors.text1.withValues(alpha: 0.32),
          ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.52)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width; x += 14) {
      canvas.drawLine(
          Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StripePainter oldDelegate) =>
      oldDelegate.color != color;
}

class AppJejuMap extends StatelessWidget {
  const AppJejuMap({
    super.key,
    required this.spots,
    this.highlight,
    this.route = const [],
    this.onTapSpot,
  });

  final List<Spot> spots;
  final Spot? highlight;
  final List<Spot> route;
  final ValueChanged<Spot>? onTapSpot;

  static const _minLat = 33.10;
  static const _maxLat = 33.62;
  static const _minLng = 126.12;
  static const _maxLng = 126.98;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final mapRect = _mapRect(size);
        final points = {
          for (final spot in spots) spot.id: _project(spot, mapRect),
        };

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: onTapSpot == null
              ? null
              : (details) {
                  Spot? nearest;
                  var best = double.infinity;
                  for (final spot in spots) {
                    final point = points[spot.id];
                    if (point == null) continue;
                    final distance = (details.localPosition - point).distance;
                    if (distance < best) {
                      best = distance;
                      nearest = spot;
                    }
                  }
                  if (nearest != null && best < 34) onTapSpot!(nearest);
                },
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _AppJejuMapPainter(
                    mapRect: mapRect,
                    spots: spots,
                    route: route,
                    highlight: highlight,
                    points: points,
                  ),
                ),
              ),
              for (final spot in spots)
                if (points[spot.id] case final point?)
                  Positioned(
                    left: point.dx - 15,
                    top: point.dy - 15,
                    width: 30,
                    height: 30,
                    child: IgnorePointer(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: spot.id == highlight?.id
                              ? AppColors.tertiary
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: spot.id == highlight?.id
                                ? Colors.white
                                : AppColors.accent.withValues(alpha: 0.55),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.text1.withValues(alpha: 0.16),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            spot.emoji,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  static Rect _mapRect(Size size) {
    final width = size.width * 0.86;
    final height = math.min(size.height * 0.58, width * 0.48);
    return Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.46),
      width: width,
      height: height,
    );
  }

  static Offset _project(Spot spot, Rect rect) {
    final x = ((spot.lng - _minLng) / (_maxLng - _minLng)).clamp(0.0, 1.0);
    final y =
        (1 - ((spot.lat - _minLat) / (_maxLat - _minLat))).clamp(0.0, 1.0);
    return Offset(rect.left + rect.width * x, rect.top + rect.height * y);
  }
}

class _AppJejuMapPainter extends CustomPainter {
  const _AppJejuMapPainter({
    required this.mapRect,
    required this.spots,
    required this.route,
    required this.highlight,
    required this.points,
  });

  final Rect mapRect;
  final List<Spot> spots;
  final List<Spot> route;
  final Spot? highlight;
  final Map<String, Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppColors.greenBg.withValues(alpha: 0.55);
    canvas.drawRect(Offset.zero & size, bg);

    final island = Path()
      ..moveTo(mapRect.left + mapRect.width * .03,
          mapRect.top + mapRect.height * .55)
      ..cubicTo(
          mapRect.left + mapRect.width * .13,
          mapRect.top + mapRect.height * .18,
          mapRect.left + mapRect.width * .47,
          mapRect.top + mapRect.height * .02,
          mapRect.left + mapRect.width * .78,
          mapRect.top + mapRect.height * .20)
      ..cubicTo(
          mapRect.left + mapRect.width * .98,
          mapRect.top + mapRect.height * .32,
          mapRect.left + mapRect.width * 1.00,
          mapRect.top + mapRect.height * .66,
          mapRect.left + mapRect.width * .72,
          mapRect.top + mapRect.height * .86)
      ..cubicTo(
          mapRect.left + mapRect.width * .47,
          mapRect.top + mapRect.height * 1.02,
          mapRect.left + mapRect.width * .12,
          mapRect.top + mapRect.height * .86,
          mapRect.left + mapRect.width * .03,
          mapRect.top + mapRect.height * .55)
      ..close();

    canvas.drawPath(
      island,
      Paint()..color = AppColors.surface.withValues(alpha: 0.92),
    );
    canvas.drawPath(
      island,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    for (final radius in [0.22, 0.34, 0.46]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: mapRect.center,
          width: mapRect.width * radius,
          height: mapRect.height * radius,
        ),
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    final routePoints =
        route.map((spot) => points[spot.id]).whereType<Offset>().toList();
    if (routePoints.length > 1) {
      final path = Path()..moveTo(routePoints.first.dx, routePoints.first.dy);
      for (final point in routePoints.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.accent
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 4,
      );
    }

    final highlightPoint = highlight == null ? null : points[highlight!.id];
    if (highlightPoint != null) {
      canvas.drawCircle(
        highlightPoint,
        22,
        Paint()..color = AppColors.tertiary.withValues(alpha: 0.16),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AppJejuMapPainter oldDelegate) {
    return oldDelegate.spots != spots ||
        oldDelegate.route != route ||
        oldDelegate.highlight != highlight ||
        oldDelegate.mapRect != mapRect;
  }
}
