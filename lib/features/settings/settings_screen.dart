import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/colors.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/app_ui.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _visitor = 'kr';

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    final routeReminders = ref.watch(routeRemindersEnabledProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 130),
          children: [
            Text(
              _settingsKicker(language),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
                color: AppColors.text2,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _preferencesLabel(language),
              style: GoogleFonts.montserrat(
                fontSize: 40,
                height: 1.05,
                fontWeight: FontWeight.w900,
                color: AppColors.text1,
              ),
            ),
            const SizedBox(height: 28),
            _Section(
              label: _languageLabel(language),
              child: _TonalList(
                children: [
                  ('ko', '한국어', _countryKorea(language)),
                  ('en', 'English', _countryEnglish(language)),
                  ('ja', '日本語', _countryJapan(language)),
                  ('zh', '中文', _countryChina(language)),
                ]
                    .map(
                      (lang) => _SelectRow(
                        title: lang.$2,
                        subtitle: lang.$3,
                        selected: language.name == lang.$1,
                        onTap: () => persistAppLanguage(
                          ref,
                          AppLanguage.values
                              .firstWhere((value) => value.name == lang.$1),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            _Section(
              label: _visitorLabel(language),
              child: Row(
                children: [
                  Expanded(
                    child: _VisitorCard(
                      title: _domesticLabel(language),
                      code: _domesticCode(language),
                      subtitle: _domesticSub(language),
                      selected: _visitor == 'kr',
                      onTap: () => setState(() => _visitor = 'kr'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _VisitorCard(
                      title: _foreignLabel(language),
                      code: 'EN',
                      subtitle: _foreignSub(language),
                      selected: _visitor == 'global',
                      onTap: () => setState(() => _visitor = 'global'),
                    ),
                  ),
                ],
              ),
            ),
            _Section(
              label: _alertsLabel(language),
              child: _TonalList(
                children: [
                  _SwitchRow(
                      title: _routeRemindersLabel(language),
                      value: routeReminders,
                      onChanged: (v) =>
                          _toggleRouteReminders(context, language, v)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleRouteReminders(
      BuildContext context, AppLanguage language, bool enabled) async {
    final changed = await setRouteRemindersEnabled(ref, enabled);
    if (!changed && context.mounted) {
      _showPermissionSnack(context, language);
    }
  }

  void _showPermissionSnack(BuildContext context, AppLanguage language) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_notificationPermissionLabel(language)),
        backgroundColor: AppColors.accent,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: AppColors.text3,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _TonalList extends StatelessWidget {
  const _TonalList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: children),
    );
  }
}

class _SelectRow extends StatelessWidget {
  const _SelectRow(
      {required this.title,
      required this.subtitle,
      required this.selected,
      required this.onTap});

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
            color: selected ? AppColors.greenBg : Colors.transparent),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.montserrat(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.text3)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.accent : AppColors.separator,
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitorCard extends StatelessWidget {
  const _VisitorCard({
    required this.title,
    required this.code,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String code;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppChip(label: code, active: selected, tone: AppChipTone.outline),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.text1,
              ),
            ),
            const SizedBox(height: 2),
            Text(subtitle,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: selected ? Colors.white70 : AppColors.text3)),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow(
      {required this.title, required this.value, required this.onChanged});

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Expanded(
              child: Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.bg,
            activeTrackColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

String _settingsKicker(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '설정',
      AppLanguage.en => 'SETTINGS',
      AppLanguage.ja => '設定',
      AppLanguage.zh => '设置',
    };

String _notificationPermissionLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '알림 권한을 허용해야 사용할 수 있어요.',
      AppLanguage.en => 'Notification permission is required.',
      AppLanguage.ja => '通知の許可が必要です。',
      AppLanguage.zh => '需要允许通知权限。',
    };

String _preferencesLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '환경 설정',
      AppLanguage.en => 'Preferences',
      AppLanguage.ja => '環境設定',
      AppLanguage.zh => '偏好设置',
    };

String _languageLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '언어',
      AppLanguage.en => 'Language',
      AppLanguage.ja => '言語',
      AppLanguage.zh => '语言',
    };

String _visitorLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '방문자',
      AppLanguage.en => 'Visitor',
      AppLanguage.ja => '訪問者',
      AppLanguage.zh => '访客',
    };

String _alertsLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '알림',
      AppLanguage.en => 'Alerts',
      AppLanguage.ja => '通知',
      AppLanguage.zh => '提醒',
    };

String _countryKorea(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '대한민국',
      AppLanguage.en => 'South Korea',
      AppLanguage.ja => '韓国',
      AppLanguage.zh => '韩国',
    };

String _countryEnglish(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '영어권',
      AppLanguage.en => 'United States',
      AppLanguage.ja => '英語圏',
      AppLanguage.zh => '英语地区',
    };

String _countryJapan(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '일본',
      AppLanguage.en => 'Japan',
      AppLanguage.ja => '日本',
      AppLanguage.zh => '日本',
    };

String _countryChina(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '중국어권',
      AppLanguage.en => 'Chinese',
      AppLanguage.ja => '中国語',
      AppLanguage.zh => '中文',
    };

String _domesticLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '국내',
      AppLanguage.en => 'Domestic',
      AppLanguage.ja => '国内',
      AppLanguage.zh => '国内',
    };

String _domesticCode(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '국내',
      AppLanguage.en => 'KR',
      AppLanguage.ja => '韓国',
      AppLanguage.zh => '韩国',
    };

String _domesticSub(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '한국어 우선 안내',
      AppLanguage.en => 'Korean-first guide',
      AppLanguage.ja => '韓国語優先ガイド',
      AppLanguage.zh => '韩语优先指南',
    };

String _foreignLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '해외',
      AppLanguage.en => 'Foreign',
      AppLanguage.ja => '海外',
      AppLanguage.zh => '海外',
    };

String _foreignSub(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '다국어 안내',
      AppLanguage.en => 'Multilingual guide',
      AppLanguage.ja => '多言語ガイド',
      AppLanguage.zh => '多语言指南',
    };

// ignore: unused_element
String _weatherAlertsLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '날씨 알림',
      AppLanguage.en => 'Weather alerts',
      AppLanguage.ja => '天気通知',
      AppLanguage.zh => '天气提醒',
    };

// ignore: unused_element
String _busArrivalLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '버스 도착',
      AppLanguage.en => 'Bus arrival',
      AppLanguage.ja => 'バス到着',
      AppLanguage.zh => '公交到站',
    };

String _routeRemindersLabel(AppLanguage lang) => switch (lang) {
      AppLanguage.ko => '일정 알림',
      AppLanguage.en => 'Route reminders',
      AppLanguage.ja => '日程リマインダー',
      AppLanguage.zh => '行程提醒',
    };
