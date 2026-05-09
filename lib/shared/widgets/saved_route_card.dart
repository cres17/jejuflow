import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/spot_data.dart';
import '../../core/models/saved_route.dart';
import '../../core/models/weather.dart';
import '../../core/utils/route_utils.dart';
import '../../providers/app_providers.dart';

class SavedRouteCard extends StatelessWidget {
  const SavedRouteCard({
    super.key,
    required this.route,
    required this.currentWeather,
    required this.onUse,
    required this.onDelete,
    required this.lang,
    this.planItem,
    this.onNavigate,
    this.onSchedule,
  });

  final SavedRoute route;
  final WeatherData? currentWeather;
  final VoidCallback onUse;
  final VoidCallback onDelete;
  final AppLanguage lang;
  final DayPlanItem? planItem;
  final VoidCallback? onNavigate;
  final VoidCallback? onSchedule;

  @override
  Widget build(BuildContext context) {
    final spot = kSpotById[route.spotId];
    final title = spot == null ? route.spotName : spotDisplayName(spot, lang);
    final photoUrl = spot?.photoUrl ?? route.photoUrl;
    final weatherAffected =
        (spot?.isOutdoor ?? false) && (currentWeather?.isBad ?? false);
    final scheduledAt = planItem?.arrival ?? route.savedAt;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.separator.withValues(alpha: 0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? _RoutePhotoFallback(accent: route.accent)
                      : CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _RoutePhotoFallback(accent: route.accent),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${DateFormat('yyyy.MM.dd').format(scheduledAt)}  ${DateFormat('HH:mm').format(scheduledAt)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon:
                    const Icon(Icons.more_vert_rounded, color: AppColors.text3),
                onSelected: (value) {
                  if (value == 'use') onUse();
                  if (value == 'navigate') onNavigate?.call();
                  if (value == 'schedule') onSchedule?.call();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'use', child: Text(_openLabel(lang))),
                  PopupMenuItem(
                      value: 'navigate', child: Text(_navigationLabel(lang))),
                  PopupMenuItem(
                      value: 'schedule', child: Text(_scheduleLabel(lang))),
                  PopupMenuItem(
                      value: 'delete', child: Text(_deleteLabel(lang))),
                ],
              ),
            ],
          ),
          if (weatherAffected) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.yellowBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.tertiary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _weatherWarning(lang),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onUse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    _openLabel(lang),
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                tooltip: _scheduleLabel(lang),
                onPressed: onSchedule,
                icon: const Icon(Icons.event_rounded),
                color: AppColors.secondary,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.secondaryBg,
                  fixedSize: const Size(48, 48),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: _navigationLabel(lang),
                onPressed: onNavigate,
                icon: const Icon(Icons.navigation_rounded),
                color: AppColors.accent,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.greenBg,
                  fixedSize: const Size(48, 48),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.text3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _openLabel(AppLanguage lang) => switch (lang) {
        AppLanguage.ko => '상세 보기',
        AppLanguage.en => 'Open',
        AppLanguage.ja => '詳細',
        AppLanguage.zh => '查看',
      };

  String _navigationLabel(AppLanguage lang) => switch (lang) {
        AppLanguage.ko => '내비게이션',
        AppLanguage.en => 'Navigation',
        AppLanguage.ja => 'ナビ',
        AppLanguage.zh => '导航',
      };

  String _scheduleLabel(AppLanguage lang) => switch (lang) {
        AppLanguage.ko => '날짜 / 시간',
        AppLanguage.en => 'Date / Time',
        AppLanguage.ja => '日付 / 時間',
        AppLanguage.zh => '日期 / 时间',
      };

  String _deleteLabel(AppLanguage lang) => switch (lang) {
        AppLanguage.ko => '삭제',
        AppLanguage.en => 'Delete',
        AppLanguage.ja => '削除',
        AppLanguage.zh => '删除',
      };

  String _weatherWarning(AppLanguage lang) => switch (lang) {
        AppLanguage.ko => '날씨가 야외 일정에 영향을 줄 수 있어요',
        AppLanguage.en => 'Weather may affect this outdoor trip',
        AppLanguage.ja => '天気が屋外の日程に影響する可能性があります',
        AppLanguage.zh => '天气可能会影响户外行程',
      };
}

class _RoutePhotoFallback extends StatelessWidget {
  const _RoutePhotoFallback({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.greenBg,
            accent.withValues(alpha: 0.22),
          ],
        ),
      ),
      child: Icon(Icons.place_rounded, color: accent, size: 28),
    );
  }
}
