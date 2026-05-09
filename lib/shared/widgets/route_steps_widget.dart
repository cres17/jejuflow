import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/models/saved_route.dart';

class RouteStepsWidget extends StatelessWidget {
  const RouteStepsWidget({super.key, required this.steps, required this.accent});
  final List<RouteStep> steps;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (i) {
        final step    = steps[i];
        final isFirst = i == 0;
        final isLast  = i == steps.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline column
              SizedBox(
                width: 26,
                child: Column(
                  children: [
                    Container(
                      width: isFirst || isLast ? 14 : 10,
                      height: isFirst || isLast ? 14 : 10,
                      decoration: BoxDecoration(
                        color: (isFirst || isLast) ? accent : Colors.transparent,
                        border: (isFirst || isLast) ? null : Border.all(color: accent, width: 2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(child: Container(
                        width: 2, color: AppColors.separator,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                      )),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_iconFor(step.type), size: 16, color: accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(step.main,
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1)),
                          ),
                          if (step.durationMinutes > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('${step.durationMinutes} min',
                                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: accent)),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 24, top: 3),
                        child: Text(step.detail,
                            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.text2)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'start':
        return Icons.my_location_rounded;
      case 'walk':
        return Icons.directions_walk_rounded;
      case 'bus':
        return Icons.directions_bus_rounded;
      case 'arrive':
        return Icons.place_rounded;
      default:
        return Icons.circle_rounded;
    }
  }
}
