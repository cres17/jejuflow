import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/weather.dart';
import '../../core/models/spot.dart';

class SituationCard extends StatelessWidget {
  const SituationCard({
    super.key,
    required this.weather,
    required this.region,
  });
  final WeatherData weather;
  final SpotRegion region;

  @override
  Widget build(BuildContext context) {
    final regionLabel = region == SpotRegion.jejuCity ? 'Jeju City' : 'Seogwipo';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: weather.bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: weather.bgColor.withValues(alpha:0.4),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: region + status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📍 $regionLabel'.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1.5, color: Colors.white70,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: weather.fromCache ? Colors.orange : const Color(0xFF44FF88),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    weather.fromCache ? 'Cached' : 'Live',
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.white60),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weather + Temp
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(weather.iconData, size: 44, color: weather.accentColor),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weather.label,
                    style: GoogleFonts.outfit(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: weather.accentColor, letterSpacing: -0.5,
                    ),
                  ),
                  if (weather.temperature != null)
                    Text(
                      weather.temperature!,
                      style: GoogleFonts.outfit(
                        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${weather.wind.toStringAsFixed(1)} m/s',
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.white60),
                  ),
                  Text(
                    weather.updatedAgo,
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Advice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              weather.advice,
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white, height: 1.4),
            ),
          ),

          // Warning
          if (weather.warning != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha:0.3)),
              ),
              child: Text(
                weather.warning!,
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.amber.shade200),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class SituationCardSkeleton extends StatelessWidget {
  const SituationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF0F2A12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF2A7A4A)),
      ),
    );
  }
}
