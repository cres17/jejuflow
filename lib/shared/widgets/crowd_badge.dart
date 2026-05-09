import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/crowd_data.dart';

class CrowdBadge extends StatelessWidget {
  const CrowdBadge({super.key, required this.level});
  final CrowdLevel level;

  @override
  Widget build(BuildContext context) {
    final (icon, label, bg, fg) = switch (level) {
      CrowdLevel.low      => ('🟢', 'Quiet', const Color(0xFFE6F4EC), const Color(0xFF1F7A42)),
      CrowdLevel.moderate => ('🟡', 'Moderate', const Color(0xFFFEF6E4), const Color(0xFFC8920A)),
      CrowdLevel.high     => ('🔴', 'Busy', const Color(0xFFFCECEA), const Color(0xFFD63B2A)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        '$icon $label',
        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
