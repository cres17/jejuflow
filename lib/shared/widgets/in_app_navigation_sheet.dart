import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/colors.dart';
import '../../providers/app_providers.dart';
import 'kakao_map_view.dart';

class NavigationTarget {
  const NavigationTarget({
    required this.name,
    required this.nameKo,
    required this.lat,
    required this.lng,
  });

  final String name;
  final String nameKo;
  final double lat;
  final double lng;
}

Future<void> showInAppNavigationSheet({
  required BuildContext context,
  required NavigationTarget target,
  required AppLanguage lang,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.48,
      maxChildSize: 0.94,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.separator,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.navigation_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(lang),
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      target.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          KakaoMapView(
            lat: target.lat,
            lng: target.lng,
            name: target.name,
            nameKo: target.nameKo,
            height: 340,
            showRoute: true,
          ),
          const SizedBox(height: 18),
          _GuidanceCard(lang: lang, target: target),
        ],
      ),
    ),
  );
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({required this.lang, required this.target});

  final AppLanguage lang;
  final NavigationTarget target;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (Icons.my_location_rounded, _currentLocation(lang)),
      (Icons.translate_rounded, _koreanDestination(lang, target.nameKo)),
      (Icons.route_rounded, _routePreview(lang)),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(row.$1, color: AppColors.accent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        row.$2,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

String _title(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '인앱 네비게이션',
      AppLanguage.en => 'In-app navigation',
      AppLanguage.ja => 'アプリ内ナビ',
      AppLanguage.zh => '应用内导航',
    };

String _currentLocation(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '위치 권한을 허용하면 현재 위치에서 목적지까지 바로 표시합니다.',
      AppLanguage.en =>
        'Allow location access to show the route from your current position.',
      AppLanguage.ja => '位置情報を許可すると、現在地から目的地まで表示します。',
      AppLanguage.zh => '允许位置权限后，会显示从当前位置到目的地的路线。',
    };

String _koreanDestination(AppLanguage lang, String nameKo) => switch (lang) {
      AppLanguage.ko => '목적지는 카카오맵이 인식하기 쉬운 한국어 표기 "$nameKo"로 전달합니다.',
      AppLanguage.en =>
        'The destination is passed to Kakao Map in Korean as "$nameKo".',
      AppLanguage.ja => '目的地はカカオマップ用に韓国語「$nameKo」で渡します。',
      AppLanguage.zh => '目的地会以韩语“$nameKo”传给 Kakao Map。',
    };

String _routePreview(AppLanguage lang) => switch (lang) {
      AppLanguage.ko =>
        '현재 단계는 인앱 지도와 경로 프리뷰입니다. 실제 턴바이턴 길안내는 카카오 Mobility/길찾기 API 연결 후 확장할 수 있습니다.',
      AppLanguage.en =>
        'This is an in-app map and route preview. Turn-by-turn guidance can be added after connecting Kakao Mobility/Directions API.',
      AppLanguage.ja =>
        '現在はアプリ内地図とルートプレビューです。ターンバイターン案内は Kakao Mobility/Directions API 接続後に拡張できます。',
      AppLanguage.zh =>
        '当前是应用内地图和路线预览。接入 Kakao Mobility/Directions API 后可扩展逐步导航。',
    };
