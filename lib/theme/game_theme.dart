import 'package:flutter/material.dart';

enum GameThemeMode {
  light,
  dark,
}

class ThemeService extends ChangeNotifier {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  GameThemeMode _themeMode = GameThemeMode.light; // 初期はワクワクするNintendoライクなライトモード
  GameThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == GameThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == GameThemeMode.light ? GameThemeMode.dark : GameThemeMode.light;
    notifyListeners();
  }

  void setTheme(GameThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }
}

class GameColors {
  // Nintendo Joy-Con 代表カラー
  static const Color joyconRed = Color(0xFFFF3B30);
  static const Color joyconBlue = Color(0xFF00C3E3);
  static const Color joyconYellow = Color(0xFFFFCC00);
  static const Color joyconGreen = Color(0xFF34C759);
  static const Color joyconPurple = Color(0xFFAF52DE);

  // ライトモード (Switch White)
  static const Color lightBg = Color(0xFFEBEFF4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF3F6FA);
  static const Color lightBorder = Color(0xFFD2D9E4);
  static const Color lightTextMain = Color(0xFF1E2530);
  static const Color lightTextDim = Color(0xFF758295);

  // ダークモード (Switch Black)
  static const Color darkBg = Color(0xFF181B22);
  static const Color darkSurface = Color(0xFF222630);
  static const Color darkCard = Color(0xFF2C3240);
  static const Color darkBorder = Color(0xFF3A4255);
  static const Color darkTextMain = Color(0xFFF5F7FA);
  static const Color darkTextDim = Color(0xFF8E9BAE);
}

class GameTheme {
  final bool isDark;

  const GameTheme(this.isDark);

  Color get bg => isDark ? GameColors.darkBg : GameColors.lightBg;
  Color get surface => isDark ? GameColors.darkSurface : GameColors.lightSurface;
  Color get card => isDark ? GameColors.darkCard : GameColors.lightCard;
  Color get border => isDark ? GameColors.darkBorder : GameColors.lightBorder;
  Color get textMain => isDark ? GameColors.darkTextMain : GameColors.lightTextMain;
  Color get textDim => isDark ? GameColors.darkTextDim : GameColors.lightTextDim;

  Color get red => GameColors.joyconRed;
  Color get blue => GameColors.joyconBlue;
  Color get yellow => GameColors.joyconYellow;
  Color get green => GameColors.joyconGreen;
  Color get purple => GameColors.joyconPurple;

  // 任天堂ハード風のぷっくり立体ボタンデコレーション
  BoxDecoration gameButton({
    required Color color,
    bool isPressed = false,
    double radius = 16.0,
  }) {
    return BoxDecoration(
      color: isPressed ? color.withValues(alpha: 0.85) : color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.4),
          blurRadius: isPressed ? 2 : 8,
          offset: Offset(0, isPressed ? 1 : 4),
        ),
        if (!isPressed)
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
      ],
      border: Border.all(
        color: Colors.white.withValues(alpha: isDark ? 0.25 : 0.4),
        width: 1.5,
      ),
    );
  }

  // 任天堂風の丸みカード
  BoxDecoration gameCard({
    Color? customBg,
    Color? customBorder,
    double radius = 18.0,
  }) {
    return BoxDecoration(
      color: customBg ?? surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: customBorder ?? border,
        width: 1.8,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
