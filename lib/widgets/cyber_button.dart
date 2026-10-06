import 'package:flutter/material.dart';
import '../services/haptics_service.dart';
import '../services/phantom_core_service.dart';
import '../theme/cyber_theme.dart';

class CyberButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color color;
  final double height;
  final double? width;
  final bool isSecondary;
  final String hapticType;

  const CyberButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color = CyberTheme.cyan,
    this.height = 48.0,
    this.width,
    this.isSecondary = false,
    this.hapticType = 'click',
  });

  @override
  State<CyberButton> createState() => _CyberButtonState();
}

class _CyberButtonState extends State<CyberButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = true);

    // ハプティクス＆サウンド発火
    HapticsService.instance.triggerHapticFeedback(
      type: widget.hapticType,
      soundPitch: widget.color == CyberTheme.magenta ? 1.3 : 1.0,
    );

    // 生体コアにインタラクション伝達
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
    final effectiveColor = widget.onPressed == null ? CyberTheme.textDim : widget.color;

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
                    ? effectiveColor.withValues(alpha: 0.2)
                    : CyberTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: effectiveColor.withValues(alpha: _isPressed ? 0.9 : 0.4),
                  width: 1.2,
                ),
              )
            : CyberTheme.arcadeButton(
                color: effectiveColor,
                isPressed: _isPressed,
                radius: 10.0,
              ),
        child: Center(
          child: widget.child,
        ),
      ),
    );
  }
}
