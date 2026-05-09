import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/colors.dart';

class KakaoMapView extends StatelessWidget {
  const KakaoMapView({
    super.key,
    required this.lat,
    required this.lng,
    required this.name,
    required this.nameKo,
    this.height = 280,
    this.showRoute = false,
  });

  final double lat;
  final double lng;
  final String name;
  final String nameKo;
  final double height;
  final bool showRoute;

  @override
  Widget build(BuildContext context) {
    return KakaoFallbackLocationCard(
      height: height,
      name: name,
      lat: lat,
      lng: lng,
      showRoute: showRoute,
    );
  }
}

class KakaoFallbackLocationCard extends StatelessWidget {
  const KakaoFallbackLocationCard({
    super.key,
    required this.height,
    required this.name,
    required this.lat,
    required this.lng,
    required this.showRoute,
  });

  final double height;
  final String name;
  final double lat;
  final double lng;
  final bool showRoute;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.separator),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _JejuPositionPainter(lat: lat, lng: lng),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                showRoute ? 'In-app route preview' : name,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JejuPositionPainter extends CustomPainter {
  const _JejuPositionPainter({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  void paint(Canvas canvas, Size size) {
    final islandPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..moveTo(size.width * .11, size.height * .56)
      ..cubicTo(size.width * .18, size.height * .26, size.width * .46,
          size.height * .18, size.width * .72, size.height * .28)
      ..cubicTo(size.width * .94, size.height * .36, size.width * .95,
          size.height * .67, size.width * .72, size.height * .76)
      ..cubicTo(size.width * .48, size.height * .86, size.width * .18,
          size.height * .78, size.width * .11, size.height * .56);
    canvas.drawPath(path, islandPaint);
    canvas.drawPath(path, outline);

    final x = ((lng - 126.12) / (126.98 - 126.12)).clamp(0.0, 1.0);
    final y = (1 - ((lat - 33.10) / (33.62 - 33.10))).clamp(0.0, 1.0);
    final point = Offset(
      size.width * (.12 + x * .76),
      size.height * (.22 + y * .56),
    );
    canvas.drawCircle(
      point,
      12,
      Paint()..color = AppColors.tertiary.withValues(alpha: 0.22),
    );
    canvas.drawCircle(point, 5, Paint()..color = AppColors.tertiary);
  }

  @override
  bool shouldRepaint(covariant _JejuPositionPainter oldDelegate) {
    return oldDelegate.lat != lat || oldDelegate.lng != lng;
  }
}
