import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/phantom_core_service.dart';
import '../services/sensor_service.dart';
import '../theme/game_theme.dart';

class PhantomCoreTab extends StatefulWidget {
  const PhantomCoreTab({super.key});

  @override
  State<PhantomCoreTab> createState() => _PhantomCoreTabState();
}

class _PhantomCoreTabState extends State<PhantomCoreTab> with SingleTickerProviderStateMixin {
  final PhantomCoreService _core = PhantomCoreService.instance;
  final SensorService _sensors = SensorService.instance;
  final ThemeService _theme = ThemeService.instance;
  final LocalizationService _loc = LocalizationService.instance;

  late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _core.isCoreTabActive = true;
    _core.addListener(_onUpdate);
    _theme.addListener(_onUpdate);
    _loc.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    _core.isCoreTabActive = false;
    _core.removeListener(_onUpdate);
    _theme.removeListener(_onUpdate);
    _loc.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _onManualDrag(DragUpdateDetails details, Size size) {
    final tiltX = (details.localPosition.dx / size.width) * 2.0 - 1.0;
    final tiltY = (details.localPosition.dy / size.height) * 2.0 - 1.0;
    _sensors.setManualTilt(tiltX, tiltY);
  }

  void _onManualDragEnd(DragEndDetails details) {
    _sensors.resetManualTilt();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _theme.isDark;
    final gameTheme = GameTheme(isDark);
    final s = _loc.strings;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final corePixelX = ((_core.posX + 1.0) / 2.0) * (w - 70) + 35;
        final corePixelY = ((_core.posY + 1.0) / 2.0) * (h - 120) + 60;

        final fingerPixelX = ((_core.touchTargetX + 1.0) / 2.0) * w;
        final fingerPixelY = ((_core.touchTargetY + 1.0) / 2.0) * h;

        return Container(
          color: gameTheme.bg,
          child: Stack(
            children: [
              // 背景の重力グリッド & 張力テンドン
              CustomPaint(
                size: Size(w, h),
                painter: _CoreGravityPainter(
                  corePos: Offset(corePixelX, corePixelY),
                  fingerPos: _core.isHoldingTouch ? Offset(fingerPixelX, fingerPixelY) : null,
                  touchDistance: _core.touchDistance,
                  pulseValue: _pulseAnim.value,
                  isDark: isDark,
                ),
              ),

              // 全画面インタラクティブ・ジェスチャーエリア（ボタンなし・全域タッチ）
              GestureDetector(
                onPanStart: (d) {
                  final normX = (d.localPosition.dx / w) * 2.0 - 1.0;
                  final normY = (d.localPosition.dy / h) * 2.0 - 1.0;
                  _core.onTouchStart(normX, normY);
                },
                onPanUpdate: (d) {
                  final normX = (d.localPosition.dx / w) * 2.0 - 1.0;
                  final normY = (d.localPosition.dy / h) * 2.0 - 1.0;
                  _core.onTouchMove(normX, normY);
                  _onManualDrag(d, Size(w, h));
                },
                onPanEnd: (d) {
                  _core.onTouchEnd();
                  _onManualDragEnd(d);
                },
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),

              // 仮想質量コア本体（タップや長押しで鼓動・パルスが手の中に直接響く）
              Positioned(
                left: corePixelX - 35,
                top: corePixelY - 35,
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white,
                          GameColors.joyconPurple,
                          GameColors.joyconBlue.withValues(alpha: 0.8),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: GameColors.joyconPurple.withValues(
                            alpha: _core.isHoldingTouch ? 0.75 : 0.45 + _pulseAnim.value * 0.25,
                          ),
                          blurRadius: _core.isHoldingTouch ? 30 : 16 + _pulseAnim.value * 12,
                          spreadRadius: _core.isHoldingTouch ? 6 : 2 + _pulseAnim.value * 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 下部：感覚的・直感的な1行ガイダンス（ボタンを全廃し「触れば判るUX」を実現）
              Positioned(
                bottom: 16,
                left: 20,
                right: 20,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: gameTheme.gameCard(radius: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.touch_app_rounded, color: GameColors.joyconPurple, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            s.ghostCorePureHint,
                            style: TextStyle(
                              color: gameTheme.textMain,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CoreGravityPainter extends CustomPainter {
  final Offset corePos;
  final Offset? fingerPos;
  final double touchDistance;
  final double pulseValue;
  final bool isDark;

  _CoreGravityPainter({
    required this.corePos,
    required this.fingerPos,
    required this.touchDistance,
    required this.pulseValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 重力場の等高線リップル
    final rippleRadius = 60.0 + pulseValue * 30.0;
    final ripplePaint = Paint()
      ..color = GameColors.joyconPurple.withValues(alpha: isDark ? 0.15 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(corePos, rippleRadius, ripplePaint);
    canvas.drawCircle(corePos, rippleRadius * 1.6, ripplePaint..strokeWidth = 1.0);

    // 引っ張りテンションのゴム状テンドン（指とコアを繋ぎ、伸びるほど赤く光る）
    if (fingerPos != null && touchDistance > 0.08) {
      final stretchRatio = (touchDistance / 1.0).clamp(0.0, 1.0);
      final tendonColor = Color.lerp(GameColors.joyconPurple, GameColors.joyconRed, stretchRatio)!;

      final tendonPaint = Paint()
        ..color = tendonColor.withValues(alpha: 0.7)
        ..strokeWidth = 4.0 + (1.0 - stretchRatio) * 4.0
        ..strokeCap = StrokeCap.round;

      final glowPaint = Paint()
        ..color = tendonColor.withValues(alpha: 0.4)
        ..strokeWidth = 12.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawLine(corePos, fingerPos!, glowPaint);
      canvas.drawLine(corePos, fingerPos!, tendonPaint);

      // 指のタッチ位置
      final fingerRing = Paint()
        ..color = tendonColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(fingerPos!, 18, fingerRing);
    }
  }

  @override
  bool shouldRepaint(covariant _CoreGravityPainter oldDelegate) => true;
}
