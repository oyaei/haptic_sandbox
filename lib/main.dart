import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'services/haptics_service.dart';
import 'services/phantom_core_service.dart';
import 'theme/game_theme.dart';
import 'views/haptic_studio_tab.dart';
import 'views/haptic_surge_tab.dart';
import 'views/phantom_core_tab.dart';
import 'views/sequencer_tab.dart';
import 'views/touch_canvas_tab.dart';
import 'widgets/core_status_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const HapticSandboxApp());
}

class HapticSandboxApp extends StatefulWidget {
  const HapticSandboxApp({super.key});

  @override
  State<HapticSandboxApp> createState() => _HapticSandboxAppState();
}

class _HapticSandboxAppState extends State<HapticSandboxApp> {
  final ThemeService _themeService = ThemeService.instance;
  final LocalizationService _locService = LocalizationService.instance;

  @override
  void initState() {
    super.initState();
    _themeService.addListener(_onStateChange);
    _locService.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onStateChange);
    _locService.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeService.isDark;
    final gameTheme = GameTheme(isDark);

    return MaterialApp(
      title: 'HAPBOX',
      debugShowCheckedModeBanner: false,
      locale: Locale(_locService.currentLanguage.code),
      supportedLocales: AppLanguage.values.map((l) => Locale(l.code)).toList(),
      // ignore: deprecated_member_use
      localizationsDelegates: const [
        // ignore: deprecated_member_use
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        // ignore: deprecated_member_use
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: gameTheme.bg,
        colorScheme: isDark
            ? const ColorScheme.dark(
                primary: GameColors.joyconBlue,
                secondary: GameColors.joyconRed,
                surface: GameColors.darkSurface,
              )
            : const ColorScheme.light(
                primary: GameColors.joyconBlue,
                secondary: GameColors.joyconRed,
                surface: GameColors.lightSurface,
              ),
        fontFamily: 'Roboto',
      ),
      home: const MainGameConsoleScreen(),
    );
  }
}

class MainGameConsoleScreen extends StatefulWidget {
  const MainGameConsoleScreen({super.key});

  @override
  State<MainGameConsoleScreen> createState() => _MainGameConsoleScreenState();
}

class _MainGameConsoleScreenState extends State<MainGameConsoleScreen> {
  int _currentIndex = 0;
  final HapticsService _haptics = HapticsService.instance;
  final ThemeService _themeService = ThemeService.instance;
  final LocalizationService _locService = LocalizationService.instance;

  @override
  void initState() {
    super.initState();
    PhantomCoreService.instance.isCoreTabActive = (_currentIndex == 3);
    _themeService.addListener(_onUpdate);
    _locService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onUpdate);
    _locService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      _haptics.cancel();
      setState(() => _currentIndex = index);
      PhantomCoreService.instance.isCoreTabActive = (index == 3);
      _haptics.triggerHapticFeedback(
        type: switch (index) {
          0 => 'tick',
          1 => 'surge',
          2 => 'pop',
          3 => 'warp',
          4 => 'click',
          _ => 'click',
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeService.isDark;
    final gameTheme = GameTheme(isDark);

    return Scaffold(
      backgroundColor: gameTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Switch風ステータスバー
            const CoreStatusBar(),

            // メインタブコンテンツ
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  HapticStudioTab(isActive: _currentIndex == 0),
                  const HapticSurgeTab(),
                  const TouchCanvasTab(),
                  const PhantomCoreTab(),
                  SequencerTab(isActive: _currentIndex == 4),
                ],
              ),
            ),

            // 任天堂Switch/DS風ボトムナビゲーションバー
            _buildBottomNav(gameTheme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(GameTheme gameTheme, bool isDark) {
    final s = _locService.strings;
    final navItems = [
      {'icon': Icons.tune_rounded, 'label': s.tabStudio, 'color': GameColors.joyconGreen},
      {'icon': Icons.waves_rounded, 'label': s.tabSurge, 'color': GameColors.joyconBlue},
      {'icon': Icons.touch_app_rounded, 'label': s.tabTouchLab, 'color': GameColors.joyconRed},
      {'icon': Icons.blur_circular_rounded, 'label': s.tabGhostCore, 'color': GameColors.joyconPurple},
      {'icon': Icons.grid_view_rounded, 'label': s.tabSequencer, 'color': GameColors.joyconYellow},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: gameTheme.surface,
        border: Border(
          top: BorderSide(color: gameTheme.border, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          final item = navItems[index];
          final isSel = _currentIndex == index;
          final color = item['color'] as Color;

          return InkWell(
            onTap: () => _onTabSelected(index),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: isSel
                  ? BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.25 : 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color, width: 1.6),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    )
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 20,
                    color: isSel ? color : gameTheme.textDim,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: isSel ? (isDark ? Colors.white : color) : gameTheme.textDim,
                      fontSize: 9.5,
                      fontWeight: isSel ? FontWeight.w900 : FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
