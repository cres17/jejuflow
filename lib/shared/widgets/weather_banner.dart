import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/weather.dart';

class WeatherBanner extends StatelessWidget {
  const WeatherBanner({
    super.key,
    required this.weather,
    required this.onSwitch,
    required this.onDismiss,
  });
  final WeatherData weather;
  final VoidCallback onSwitch;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF6E4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC8920A).withValues(alpha:0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(weather.warning!, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF8A6010))),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(
                onPressed: onSwitch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC8920A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text('Switch Route', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onDismiss,
                child: Text('Keep Route', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF8A6010))),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: -0.3, end: 0, duration: 300.ms).fadeIn();
  }
}
