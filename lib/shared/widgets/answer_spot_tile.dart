import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/models/spot.dart';
import '../../core/utils/time_utils.dart';
import '../../providers/app_providers.dart';
import 'crowd_badge.dart';

class AnswerSpotTile extends ConsumerWidget {
  const AnswerSpotTile({
    super.key,
    required this.spot,
    required this.rank,
    required this.busWaitMinutes,
    required this.onTap,
  });
  final Spot spot;
  final int rank;
  final int busWaitMinutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalMin   = busWaitMinutes + spot.walkMinutes;
    final arriveAt   = formatArrivalTime(totalMin);
    final photoUrl   = ref.watch(spotPhotoUrlProvider(spot.id));
    final crowd      = ref.watch(crowdProvider(spot.contentId));
    final timeColor  = _timeColor(totalMin);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            // Photo / Emoji panel
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              child: SizedBox(
                width: 90, height: 90,
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _emojiPanel())
                    : _emojiPanel(),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(spot.nameEn,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text1)),
                    const SizedBox(height: 2),
                    Text(spot.sub,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 12, color: AppColors.text2)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Bus ${spot.busRoutes[0]} · ${busWaitMinutes}m wait',
                            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.text3)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('→ Arrive $arriveAt',
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: timeColor)),
                        if (crowd.hasValue && crowd.value != null) ...[
                          const SizedBox(width: 8),
                          CrowdBadge(level: crowd.value!.level),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Rank
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                '$rank',
                style: GoogleFonts.outfit(
                  fontSize: 24, fontWeight: FontWeight.w800,
                  color: AppColors.separator,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emojiPanel() => Container(
    color: spot.bgColor,
    alignment: Alignment.center,
    child: Icon(_categoryIcon(), color: Colors.white, size: 32),
  );

  IconData _categoryIcon() {
    if (spot.category == SpotCategory.indoor) return Icons.museum_rounded;
    if (spot.category == SpotCategory.both) return Icons.attractions_rounded;
    return Icons.terrain_rounded;
  }

  Color _timeColor(int min) {
    if (min <= 15) return AppColors.green;
    if (min <= 30) return AppColors.yellow;
    return AppColors.text3;
  }
}
