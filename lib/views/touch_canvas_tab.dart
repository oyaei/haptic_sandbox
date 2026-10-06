import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/haptics_service.dart';
import '../services/phantom_core_service.dart';
import '../theme/game_theme.dart';

enum TextureMode {
  bubbleWrap,
  magnetic,
  gears,
}

class TouchCanvasTab extends StatefulWidget {
  const TouchCanvasTab({super.key});

  @override
  State<TouchCanvasTab> createState() => _TouchCanvasTabState();
}

class _TouchCanvasTabState extends State<TouchCanvasTab> {
  final HapticsService _haptics = HapticsService.instance;
  final PhantomCoreService _core = PhantomCoreService.instance;
  final ThemeService _theme = ThemeService.instance;
  final LocalizationService _loc = LocalizationService.instance;

  TextureMode _mode = TextureMode.bubbleWrap;
  final List<Offset> _trail = [];
  Offset? _currentPos;
  DateTime? _lastHapticTime;

  // 4x5 = 20個のプチプチ
  final List<bool> _poppedBubbles = List.filled(20, false);

  // 歯車用の回転角
  double _gearAngle = 0.0;
  double _prevGearAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _theme.addListener(_onUpdate);
    _loc.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _haptics.cancel();
    _theme.removeListener(_onUpdate);
    _loc.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    final local = details.localPosition;
    _currentPos = local;
    _trail.clear();
    _trail.add(local);

    if (_mode == TextureMode.gears) {
      final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
      _prevGearAngle = math.atan2(local.dy - center.dy, local.dx - center.dx);
    } else {
      _triggerTextureHaptics(local, 0.0);
    }
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    final local = details.localPosition;
    final prev = _currentPos ?? local;
    _currentPos = local;

    _trail.add(local);
    if (_trail.length > 20) {
      _trail.removeAt(0);
    }

    final dist = (local - prev).distance;

    if (_mode == TextureMode.gears) {
      final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
      final currentAngle = math.atan2(local.dy - center.dy, local.dx - center.dx);
      double deltaAngle = currentAngle - _prevGearAngle;
      if (deltaAngle > math.pi) deltaAngle -= 2 * math.pi;
      if (deltaAngle < -math.pi) deltaAngle += 2 * math.pi;
      _gearAngle += deltaAngle;
      _prevGearAngle = currentAngle;

      // 歯車の歯が噛み合うピッチ（約18度ごと）にクリック
      final toothStep = math.pi / 10;
      if (deltaAngle.abs() > toothStep * 0.4) {
        _haptics.vibratePredefined('click');
        _core.recordUserInteraction();
      }
    } else {
      _triggerTextureHaptics(local, dist);
    }

    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    _currentPos = null;
    if (_mode == TextureMode.magnetic) {
      _haptics.cancel();
    }
    setState(() {});
  }

  void _triggerTextureHaptics(Offset pos, double speed) {
    final now = DateTime.now();

    switch (_mode) {
      case TextureMode.bubbleWrap:
        break;

      case TextureMode.magnetic:
        // 磁性流体：指の速度と磁極からの距離に応じて連続した滑らかな抵抗振動
        final gridX = (pos.dx % 80.0) - 40.0;
        final gridY = (pos.dy % 80.0) - 40.0;
        final distToPole = math.sqrt(gridX * gridX + gridY * gridY);
        final proximityRatio = (1.0 - (distToPole / 40.0)).clamp(0.0, 1.0);
        final speedRatio = (speed / 20.0).clamp(0.1, 1.0);

        final targetAmp = ((proximityRatio * 0.7 + speedRatio * 0.3) * 220).round();
        _haptics.setContinuous(targetAmp);

        if (distToPole < 10.0) {
          if (_lastHapticTime == null || now.difference(_lastHapticTime!).inMilliseconds > 90) {
            _lastHapticTime = now;
            _haptics.vibratePredefined('pop');
          }
        }
        break;

      case TextureMode.gears:
        break;
    }
  }

  void _popBubble(int index) {
    if (!_poppedBubbles[index]) {
      setState(() => _poppedBubbles[index] = true);
      _haptics.vibratePredefined('pop');
      _core.recordUserInteraction();

      if (_poppedBubbles.every((b) => b)) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) {
            setState(() {
              _poppedBubbles.fillRange(0, _poppedBubbles.length, false);
            });
            _haptics.triggerHapticFeedback(type: 'warp');
          }
        });
      }
    }
  }

  void _checkBubbleSwipe(Offset localPos, BoxConstraints constraints) {
    final colWidth = constraints.maxWidth / 4;
    final rowHeight = constraints.maxHeight / 5;
    final col = (localPos.dx / colWidth).floor().clamp(0, 3);
    final row = (localPos.dy / rowHeight).floor().clamp(0, 4);
    final index = row * 4 + col;
    if (index >= 0 && index < _poppedBubbles.length) {
      _popBubble(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _theme.isDark;
    final gameTheme = GameTheme(isDark);

    return Column(
      children: [
        // 洗練されたNintendo Switch風の質感切替セグメントバー（ボタン過多を排除）
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: gameTheme.surface,
          child: Row(
            children: [
              _buildModePill(
                mode: TextureMode.bubbleWrap,
                title: '🫧 BUBBLE',
                color: GameColors.joyconRed,
                isDark: isDark,
                gameTheme: gameTheme,
              ),
              const SizedBox(width: 8),
              _buildModePill(
                mode: TextureMode.magnetic,
                title: '🧲 MAGNET',
                color: GameColors.joyconPurple,
                isDark: isDark,
                gameTheme: gameTheme,
              ),
              const SizedBox(width: 8),
              _buildModePill(
                mode: TextureMode.gears,
                title: '⚙️ GEAR',
                color: GameColors.joyconBlue,
                isDark: isDark,
                gameTheme: gameTheme,
              ),
            ],
          ),
        ),

        // キャンバス本体
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (_mode == TextureMode.bubbleWrap) {
                return GestureDetector(
                  onPanDown: (d) => _checkBubbleSwipe(d.localPosition, constraints),
                  onPanUpdate: (d) => _checkBubbleSwipe(d.localPosition, constraints),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    color: gameTheme.bg,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _poppedBubbles.length,
                      itemBuilder: (context, index) {
                        final popped = _poppedBubbles[index];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: popped
                                ? (isDark ? const Color(0xFF1E222D) : const Color(0xFFDCE2EC))
                                : GameColors.joyconRed,
                            boxShadow: popped
                                ? null
                                : [
                                    BoxShadow(
                                      color: GameColors.joyconRed.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      blurRadius: 2,
                                      offset: const Offset(-2, -2),
                                    ),
                                  ],
                            border: Border.all(
                              color: popped
                                  ? gameTheme.border
                                  : Colors.white.withValues(alpha: 0.8),
                              width: popped ? 1.0 : 2.5,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              popped ? Icons.radio_button_unchecked : Icons.bubble_chart_rounded,
                              color: popped ? gameTheme.textDim : Colors.white,
                              size: 28,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }

              // 磁界または歯車キャンバス
              return GestureDetector(
                onPanStart: (d) => _onPanStart(d, constraints),
                onPanUpdate: (d) => _onPanUpdate(d, constraints),
                onPanEnd: _onPanEnd,
                child: Container(
                  color: gameTheme.bg,
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _TextureCanvasPainter(
                      mode: _mode,
                      trail: _trail,
                      currentPos: _currentPos,
                      gearAngle: _gearAngle,
                      isDark: isDark,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModePill({
    required TextureMode mode,
    required String title,
    required Color color,
    required bool isDark,
    required GameTheme gameTheme,
  }) {
    final isSel = _mode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _mode = mode);
          _haptics.triggerHapticFeedback(type: 'click');
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSel
                ? color.withValues(alpha: isDark ? 0.3 : 0.18)
                : (isDark ? const Color(0xFF232834) : const Color(0xFFEAEEF6)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSel ? color : gameTheme.border,
              width: isSel ? 2.0 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSel ? (isDark ? Colors.white : color) : gameTheme.textDim,
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TextureCanvasPainter extends CustomPainter {
  final TextureMode mode;
  final List<Offset> trail;
  final Offset? currentPos;
  final double gearAngle;
  final bool isDark;

  _TextureCanvasPainter({
    required this.mode,
    required this.trail,
    required this.currentPos,
    required this.gearAngle,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (mode == TextureMode.magnetic) {
      final polePaint = Paint()
        ..color = GameColors.joyconPurple.withValues(alpha: isDark ? 0.35 : 0.22)
        ..style = PaintingStyle.fill;
      for (double x = 40; x < size.width; x += 80) {
        for (double y = 40; y < size.height; y += 80) {
          canvas.drawCircle(Offset(x, y), 5, polePaint);
        }
      }
    }

    if (mode == TextureMode.gears) {
      final center = Offset(size.width / 2, size.height / 2);
      final radius = math.min(size.width, size.height) * 0.38;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(gearAngle);

      final gearPaint = Paint()
        ..color = GameColors.joyconBlue.withValues(alpha: isDark ? 0.25 : 0.18)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, radius, gearPaint);

      final teethCount = 18;
      final toothPaint = Paint()
        ..color = GameColors.joyconBlue
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < teethCount; i++) {
        final angle = (i * 2 * math.pi) / teethCount;
        final p1 = Offset(math.cos(angle) * (radius - 12), math.sin(angle) * (radius - 12));
        final p2 = Offset(math.cos(angle) * (radius + 12), math.sin(angle) * (radius + 12));
        canvas.drawLine(p1, p2, toothPaint);
      }

      final centerCircle = Paint()..color = isDark ? GameColors.darkSurface : GameColors.lightSurface;
      canvas.drawCircle(Offset.zero, radius * 0.35, centerCircle);
      canvas.restore();
    }

    if (trail.length > 1) {
      final path = Path();
      path.moveTo(trail.first.dx, trail.first.dy);
      for (int i = 1; i < trail.length; i++) {
        path.lineTo(trail[i].dx, trail[i].dy);
      }

      final color = mode == TextureMode.magnetic ? GameColors.joyconPurple : GameColors.joyconBlue;
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TextureCanvasPainter oldDelegate) => true;
}
