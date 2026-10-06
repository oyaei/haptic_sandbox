import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/haptics_service.dart';
import '../services/phantom_core_service.dart';
import '../theme/game_theme.dart';

class CoreStatusBar extends StatefulWidget {
  const CoreStatusBar({super.key});

  @override
  State<CoreStatusBar> createState() => _CoreStatusBarState();
}

class _CoreStatusBarState extends State<CoreStatusBar> {
  final HapticsService _haptics = HapticsService.instance;
  final PhantomCoreService _core = PhantomCoreService.instance;
  final ThemeService _theme = ThemeService.instance;
  final LocalizationService _loc = LocalizationService.instance;

  @override
  void initState() {
    super.initState();
    _core.addListener(_onUpdate);
    _theme.addListener(_onUpdate);
    _loc.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _core.removeListener(_onUpdate);
    _theme.removeListener(_onUpdate);
    _loc.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _showLanguagePicker() {
    _haptics.vibratePredefined('click');
    showModalBottomSheet(
      context: context,
      backgroundColor: _theme.isDark ? GameColors.darkSurface : GameColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.language_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'SELECT LANGUAGE / 言語選択',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: _theme.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: AppLanguage.values.map((lang) {
                    final isSel = _loc.currentLanguage == lang;
                    return ListTile(
                      title: Text(
                        lang.label,
                        style: TextStyle(
                          fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                          color: isSel
                              ? GameColors.joyconBlue
                              : (_theme.isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      trailing: isSel
                          ? const Icon(Icons.check_circle_rounded, color: GameColors.joyconBlue)
                          : null,
                      onTap: () {
                        _loc.setLanguage(lang);
                        _haptics.vibratePredefined('tick');
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _theme.isDark;
    final gameTheme = GameTheme(isDark);
    final s = _loc.strings;

    final moodColor = switch (_core.mood) {
      CoreMood.dormant => GameColors.joyconBlue,
      CoreMood.attracted => GameColors.joyconRed,
      CoreMood.excited => GameColors.joyconGreen,
      CoreMood.flowing => GameColors.joyconYellow,
    };

    final moodLabel = switch (_core.mood) {
      CoreMood.dormant => s.coreStatusSynced,
      CoreMood.attracted => s.coreStatusEngaged,
      CoreMood.excited => s.coreStatusResonating,
      CoreMood.flowing => s.coreStatusDrifting,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: gameTheme.surface,
        border: Border(
          bottom: BorderSide(color: gameTheme.border, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          // 任天堂Switch Joy-Con風のツートンバッジ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE8EEF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: gameTheme.border, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 左Joy-Con Blue
                Container(
                  width: 5,
                  height: 12,
                  decoration: BoxDecoration(
                    color: GameColors.joyconBlue,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 3),
                // 右Joy-Con Red
                Container(
                  width: 5,
                  height: 12,
                  decoration: BoxDecoration(
                    color: GameColors.joyconRed,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: moodColor,
                    boxShadow: [
                      BoxShadow(
                        color: moodColor.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  moodLabel,
                  style: TextStyle(
                    color: gameTheme.textMain,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_core.heartbeatBpm.round()} BPM',
                  style: TextStyle(
                    color: gameTheme.textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // 🌐 言語切替ボタン
          InkWell(
            onTap: _showLanguagePicker,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE8EEF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: gameTheme.border, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language_rounded, size: 16, color: GameColors.joyconBlue),
                  const SizedBox(width: 4),
                  Text(
                    _loc.currentLanguage.code.toUpperCase(),
                    style: TextStyle(
                      color: gameTheme.textMain,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ☀️/🌙 テーマ切替ボタン
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
              color: isDark ? GameColors.joyconYellow : GameColors.joyconPurple,
            ),
            tooltip: s.switchTheme,
            visualDensity: VisualDensity.compact,
            onPressed: () {
              _theme.toggleTheme();
              _haptics.vibratePredefined('click');
            },
          ),

          // 📳 ハプティクストグルボタン
          IconButton(
            icon: Icon(
              _haptics.hapticsEnabled ? Icons.vibration : Icons.mobile_off,
              size: 20,
              color: _haptics.hapticsEnabled ? GameColors.joyconRed : gameTheme.textDim,
            ),
            tooltip: 'Haptic Vibration',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              setState(() {
                _haptics.hapticsEnabled = !_haptics.hapticsEnabled;
              });
              if (_haptics.hapticsEnabled) {
                _haptics.vibratePredefined('click');
              }
            },
          ),
        ],
      ),
    );
  }
}
