import 'package:flutter/material.dart';
import '../services/haptics_service.dart';
import '../services/phantom_core_service.dart';
import '../theme/game_theme.dart';

class GameButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final double height;
  final double? width;
  final bool isSecondary;
  final String hapticType;
  final double radius;

  const GameButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color,
    this.height = 48.0,
    this.width,
    this.isSecondary = false,
    this.hapticType = 'click',
    this.radius = 16.0,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = true);

    // 純粋なハプティクス振動のみを駆動（スピーカー音声なし）
    HapticsService.instance.triggerHapticFeedback(
      type: widget.hapticType,
    );

    PhantomCoreService.instance.recordUserInteraction();
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      widget.onPressed?.call();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDark;
    final theme = GameTheme(isDark);
    final buttonColor = widget.color ?? theme.blue;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        height: widget.height,
        width: widget.width,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: widget.isSecondary
            ? BoxDecoration(
                color: _isPressed
                    ? buttonColor.withValues(alpha: isDark ? 0.25 : 0.15)
                    : theme.card,
                borderRadius: BorderRadius.circular(widget.radius),
                border: Border.all(
                  color: _isPressed ? buttonColor : theme.border,
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : theme.gameButton(
                color: widget.onPressed == null ? theme.textDim : buttonColor,
                isPressed: _isPressed,
                radius: widget.radius,
              ),
        child: Center(
          child: widget.child,
        ),
      ),
    );
  }
}
