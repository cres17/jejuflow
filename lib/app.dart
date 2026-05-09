import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/colors.dart';
import 'features/now/now_screen.dart';
import 'features/move/move_screen.dart';
import 'features/routes/routes_screen.dart';
import 'features/settings/settings_screen.dart';
import 'providers/app_providers.dart';

// Returns a language-aware display font style for headings/titles.
TextStyle appHeadingStyle(AppLanguage lang,
    {double fontSize = 22,
    FontWeight fontWeight = FontWeight.w800,
    Color? color,
    double? height}) {
  final c = color ?? AppColors.text1;
  return switch (lang) {
    AppLanguage.ko => GoogleFonts.notoSansKr(
        fontSize: fontSize, fontWeight: fontWeight, color: c, height: height),
    AppLanguage.ja => GoogleFonts.notoSansJp(
        fontSize: fontSize, fontWeight: fontWeight, color: c, height: height),
    AppLanguage.zh => GoogleFonts.notoSansSc(
        fontSize: fontSize, fontWeight: fontWeight, color: c, height: height),
    AppLanguage.en => GoogleFonts.montserrat(
        fontSize: fontSize, fontWeight: fontWeight, color: c, height: height),
  };
}

// Returns a language-aware body font style.
TextStyle appBodyStyle(AppLanguage lang,
    {double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height}) {
  final c = color ?? AppColors.text1;
  return switch (lang) {
    AppLanguage.ko => GoogleFonts.notoSansKr(
        fontSize: fontSize, fontWeight: fontWeight, color: c, height: height),
    AppLanguage.ja => GoogleFonts.notoSansJp(
        fontSize: fontSize, fontWeight: fontWeight, color: c, height: height),
    AppLanguage.zh => GoogleFonts.notoSansSc(
        fontSize: fontSize, fontWeight: fontWeight, color: c, height: height),
    AppLanguage.en => GoogleFonts.inter(
        fontSize: fontSize, fontWeight: fontWeight, color: c, height: height),
  };
}

class JejuFlowApp extends ConsumerWidget {
  const JejuFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final baseTextTheme = switch (lang) {
      AppLanguage.ko => GoogleFonts.notoSansKrTextTheme(),
      AppLanguage.ja => GoogleFonts.notoSansJpTextTheme(),
      AppLanguage.zh => GoogleFonts.notoSansScTextTheme(),
      AppLanguage.en => GoogleFonts.interTextTheme(),
    };
    final heading = switch (lang) {
      AppLanguage.ko => GoogleFonts.notoSansKr(fontWeight: FontWeight.w800),
      AppLanguage.ja => GoogleFonts.notoSansJp(fontWeight: FontWeight.w800),
      AppLanguage.zh => GoogleFonts.notoSansSc(fontWeight: FontWeight.w800),
      AppLanguage.en => GoogleFonts.montserrat(fontWeight: FontWeight.w700),
    };
    return MaterialApp(
      title: 'JejuFlow',
      debugShowCheckedModeBanner: false,
      locale: switch (lang) {
        AppLanguage.ko => const Locale('ko'),
        AppLanguage.ja => const Locale('ja'),
        AppLanguage.zh => const Locale('zh'),
        AppLanguage.en => const Locale('en'),
      },
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
        Locale('ja'),
        Locale('zh'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: AppColors.accent,
          onPrimary: Colors.white,
          secondary: AppColors.secondary,
          tertiary: AppColors.tertiary,
          surface: AppColors.surface,
          onSurface: AppColors.text1,
          outline: AppColors.separator,
        ),
        textTheme: baseTextTheme.copyWith(
          headlineLarge: heading,
          headlineMedium: heading,
          headlineSmall: heading,
          titleLarge: heading,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999)),
          ),
        ),
        useMaterial3: true,
      ),
      home: ref.watch(languageSelectedProvider)
          ? const MainShell()
          : const LanguageSelectScreen(),
    );
  }
}

class LanguageSelectScreen extends ConsumerWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = [
      (AppLanguage.ko, '한국어', '제주 여행을 한국어로 시작합니다'),
      (AppLanguage.en, 'English', 'Start JejuFlow in English'),
      (AppLanguage.ja, '日本語', '日本語でJejuFlowを始めます'),
      (AppLanguage.zh, '中文', '使用中文开始 JejuFlow'),
    ];
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 42, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'JejuFlow',
                style: GoogleFonts.montserrat(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your language',
                style: GoogleFonts.inter(fontSize: 15, color: AppColors.text2),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => persistAppLanguage(ref, option.$1),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.separator.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.greenBg,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                option.$1.name.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.$2,
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.text1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    option.$3,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.text2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.text3),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;
  late final PageController _pageController;

  final _screens = const [
    NowScreen(),
    MoveScreen(),
    RoutesScreen(),
    SettingsScreen()
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        ref.read(appInitProvider.future);
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _setTab(int i) {
    setState(() => _index = i);
    ref.read(tabIndexProvider.notifier).state = i;
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        i,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    ref.listen(tabIndexProvider, (_, next) {
      if (_index != next) {
        setState(() => _index = next);
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_index != 0) {
          _setTab(0);
          return;
        }
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              'Exit App',
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700, color: AppColors.text1),
            ),
            content: Text('Exit JejuFlow?',
                style: GoogleFonts.inter(color: AppColors.text2)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancel',
                    style: GoogleFonts.inter(color: AppColors.text3)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'Exit',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, color: AppColors.accent),
                ),
              ),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() => _index = page);
                ref.read(tabIndexProvider.notifier).state = page;
              },
              children: _screens,
            ),
            Positioned(
              left: 22,
              right: 22,
              bottom: 14,
              child: SafeArea(
                top: false,
                child: _FloatingDock(index: _index, lang: lang, onTap: _setTab),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingDock extends StatelessWidget {
  const _FloatingDock({
    required this.index,
    required this.lang,
    required this.onTap,
  });

  final int index;
  final AppLanguage lang;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (Icons.home_rounded, tr(lang, 'now')),
      (Icons.search_rounded, tr(lang, 'move')),
      (Icons.route_rounded, tr(lang, 'routes')),
      (Icons.tune_rounded, tr(lang, 'settings')),
    ];

    return Container(
      height: 66,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.inverseSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
              color: AppColors.softShadow,
              blurRadius: 34,
              offset: Offset(0, 16)),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 54,
                decoration: BoxDecoration(
                  color: active ? AppColors.bg : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tabs[i].$1,
                      size: 21,
                      color: active
                          ? AppColors.text1
                          : AppColors.inverseText.withValues(alpha: 0.62),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      child: active
                          ? Padding(
                              padding: const EdgeInsets.only(left: 7),
                              child: Text(
                                tabs[i].$2,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text1,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
