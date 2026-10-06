import 'package:flutter/material.dart';

class CyberTheme {
  static const Color background = Color(0xFF08090F);
  static const Color surface = Color(0xFF10131E);
  static const Color surfaceLight = Color(0xFF181C2C);
  static const Color card = Color(0xFF1C2237);

  // ネオンパレット
  static const Color cyan = Color(0xFF00F0FF);
  static const Color magenta = Color(0xFFFF0077);
  static const Color green = Color(0xFF00FF66);
  static const Color yellow = Color(0xFFFFD700);
  static const Color orange = Color(0xFFFF6B00);
  static const Color purple = Color(0xFF9D00FF);

  // テキストカラー
  static const Color textMain = Color(0xFFF0F4FF);
  static const Color textDim = Color(0xFF7A88A8);

  // ネオングローデコレーション
  static BoxDecoration neonBox({
    Color glowColor = cyan,
    Color bgColor = surface,
    double borderRadius = 12.0,
    double borderWidth = 1.5,
    bool glow = true,
  }) {
    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: glowColor, width: borderWidth),
      boxShadow: glow
          ? [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: glowColor.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ]
          : null,
    );
  }

  // ゲーミングボタンスタイル
  static BoxDecoration arcadeButton({
    required Color color,
    bool isPressed = false,
    double radius = 10.0,
  }) {
    return BoxDecoration(
      color: isPressed ? color.withValues(alpha: 0.3) : surfaceLight,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isPressed ? color : color.withValues(alpha: 0.6),
        width: isPressed ? 2.0 : 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: isPressed ? 0.6 : 0.2),
          blurRadius: isPressed ? 14 : 6,
          offset: Offset(0, isPressed ? 0 : 2),
        ),
      ],
    );
  }
}
