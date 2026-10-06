import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

class OscilloscopeView extends StatefulWidget {
  final double activityLevel;
  final Color? glowColor;
  final double height;

  const OscilloscopeView({
    super.key,
    this.activityLevel = 0.0,
    this.glowColor,
    this.height = 70.0,
  });

  @override
  State<OscilloscopeView> createState() => _OscilloscopeViewState();
}

class _OscilloscopeViewState extends State<OscilloscopeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDark;
    final theme = GameTheme(isDark);
    final waveColor = widget.glowColor ?? theme.blue;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: theme.gameCard(
            customBg: isDark ? const Color(0xFF141720) : const Color(0xFFF7FAFD),
            radius: 16,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: CustomPaint(
              painter: _OscilloscopePainter(
                progress: _anim.value,
                activity: widget.activityLevel,
                color: waveColor,
                isDark: isDark,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

class _OscilloscopePainter extends CustomPainter {
  final double progress;
  final double activity;
  final Color color;
  final bool isDark;

  _OscilloscopePainter({
    required this.progress,
    required this.activity,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final centerPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );

    final wavePaint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.45 : 0.25)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final path = Path();
    final midY = size.height / 2;
    final amp = 6.0 + activity * (size.height * 0.40);

    for (double x = 0; x <= size.width; x += 3) {
      final t = (x / size.width) * 4 * math.pi + progress * 2 * math.pi;
      final y = midY +
          math.sin(t) * amp * 0.7 +
          math.sin(t * 2.5 + progress * math.pi) * (amp * 0.3) +
          (activity > 0.3 ? (math.Random(x.toInt()).nextDouble() - 0.5) * activity * 10 : 0);

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _OscilloscopePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activity != activity ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}
