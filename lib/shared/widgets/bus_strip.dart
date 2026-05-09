import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/models/bus_arrival.dart';
import '../../core/utils/route_utils.dart';
import '../../core/utils/time_utils.dart';

class BusStrip extends StatelessWidget {
  const BusStrip({
    super.key,
    required this.arrivals,
    required this.isLoading,
    required this.fromCache,
    required this.onRefresh,
  });
  final List<BusArrival> arrivals;
  final bool isLoading;
  final bool fromCache;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final allLong  = arrivals.isNotEmpty && arrivals.every((a) => a.isLongWait);
    final avgWait  = arrivals.isEmpty ? 40 : arrivals.map((a) => a.arrivalMinutes).reduce((a, b) => a + b) ~/ arrivals.length;
    final taxi     = estimateTaxi(avgWait);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NEXT BUSES', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.text3)),
              GestureDetector(
                onTap: onRefresh,
                child: isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('↻ Refresh', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (arrivals.isEmpty && !isLoading)
            Text('No bus data available.', style: GoogleFonts.outfit(fontSize: 14, color: AppColors.text2)),

          ...arrivals.map((bus) => _BusRow(bus: bus)),

          if (fromCache)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('📡 Showing cached data', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.text3)),
            ),

          if (allLong) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.yellowBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('🚕', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Taxi recommended', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF8A6010))),
                        Text('~${taxi.minutes} min · ${formatWon(taxi.minKrw)}–${formatWon(taxi.maxKrw)}',
                            style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF8A6010))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BusRow extends StatelessWidget {
  const _BusRow({required this.bus});
  final BusArrival bus;

  @override
  Widget build(BuildContext context) {
    final color = bus.arrivalMinutes <= 5 ? AppColors.green
        : bus.arrivalMinutes <= 20 ? AppColors.yellow
        : AppColors.text3;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 46, height: 28,
            decoration: BoxDecoration(color: AppColors.text1, borderRadius: BorderRadius.circular(6)),
            alignment: Alignment.center,
            child: Text(bus.routeNo, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bus.destination, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1)),
                Text('${bus.remainingStops} stops away',
                    style: GoogleFonts.outfit(fontSize: 11, color: AppColors.text3)),
              ],
            ),
          ),
          Text('${bus.arrivalMinutes} min',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
