import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/haptics_service.dart';
import '../services/phantom_core_service.dart';
import '../theme/game_theme.dart';

class HapticSurgeTab extends StatefulWidget {
  const HapticSurgeTab({super.key});

  @override
  State<HapticSurgeTab> createState() => _HapticSurgeTabState();
}

class _HapticSurgeTabState extends State<HapticSurgeTab> with SingleTickerProviderStateMixin {
  final HapticsService _haptics = HapticsService.instance;
  final ThemeService _theme = ThemeService.instance;
  final LocalizationService _loc = LocalizationService.instance;

  late AnimationController _anim;
  Offset? _touchPos;
  double _currentAmplitudeRatio = 0.0;
  String _activePresetName = '';
  bool _isThrottleHolding = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _theme.addListener(_onUpdate);
    _loc.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _haptics.cancel();
    _anim.dispose();
    _theme.removeListener(_onUpdate);
    _loc.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _onTouchWave(Offset localPos, Size size) {
    _touchPos = localPos;
    // Y軸で滑らかに強度（振幅）が0.0〜1.0へ変化（上が最大、下が最小）
    final ratio = (1.0 - (localPos.dy / size.height)).clamp(0.05, 1.0);
    _currentAmplitudeRatio = ratio;

    final targetAmp = (ratio * 255).round();
    _haptics.setContinuous(targetAmp);
    _activePresetName = 'LIVE STREAM: ${(ratio * 100).round()}%';
    setState(() {});
  }

  void _onTouchEnd() {
    _touchPos = null;
    _currentAmplitudeRatio = 0.0;
    _activePresetName = '';
    _haptics.cancel();
    setState(() {});
  }

  void _playSwell() {
    setState(() => _activePresetName = 'OCEAN SWELL (うねり)');
    _haptics.vibrateRamp(startAmplitude: 15, endAmplitude: 255, durationMs: 1400, curve: 'swell');
    PhantomCoreService.instance.recordUserInteraction();
  }

  void _playCharge() {
    setState(() => _activePresetName = 'POWER CHARGE (チャージ)');
    _haptics.vibrateRamp(startAmplitude: 15, endAmplitude: 255, durationMs: 1000, curve: 'easein');
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _haptics.vibratePredefined('pop');
      }
    });
    PhantomCoreService.instance.recordUserInteraction();
  }

  void _playPurr() {
    setState(() => _activePresetName = 'PURR (呼吸と鼓動)');
    _haptics.vibrateRamp(startAmplitude: 30, endAmplitude: 180, durationMs: 1600, curve: 'surge');
    PhantomCoreService.instance.recordUserInteraction();
  }

  void _onThrottleDown() {
    _isThrottleHolding = true;
    setState(() => _activePresetName = 'THROTTLE (連続加速中)');
    _haptics.vibrateRamp(startAmplitude: 25, endAmplitude: 255, durationMs: 1100, curve: 'easein');
  }

  void _onThrottleUp() {
    if (_isThrottleHolding) {
      _isThrottleHolding = false;
      _haptics.cancel();
      _haptics.vibratePredefined('tick');
      setState(() => _activePresetName = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _theme.isDark;
    final gameTheme = GameTheme(isDark);
    final s = _loc.strings;

    return Container(
      color: gameTheme.bg,
      child: Column(
        children: [
          // 上部HUDカード（直感的なステータス表示）
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: gameTheme.gameCard(radius: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _touchPos != null || _activePresetName.isNotEmpty
                                  ? GameColors.joyconGreen
                                  : GameColors.joyconBlue,
                              boxShadow: [
                                BoxShadow(
                                  color: GameColors.joyconGreen.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.tabSurge,
                            style: TextStyle(
                              color: gameTheme.textMain,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _activePresetName.isNotEmpty ? _activePresetName : s.surgeHint,
                        style: TextStyle(
                          color: _activePresetName.isNotEmpty ? GameColors.joyconBlue : gameTheme.textDim,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_currentAmplitudeRatio > 0.0)
                    Text(
                      '${(_currentAmplitudeRatio * 100).round()}%',
                      style: const TextStyle(
                        color: GameColors.joyconBlue,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // メイン：インタラクティブ触覚ウェーブキャンバス（なぞるだけで連続＆滑らかな強弱変化）
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);
                    return GestureDetector(
                      onPanStart: (d) => _onTouchWave(d.localPosition, size),
                      onPanUpdate: (d) => _onTouchWave(d.localPosition, size),
                      onPanEnd: (_) => _onTouchEnd(),
                      onPanCancel: () => _onTouchEnd(),
                      child: AnimatedBuilder(
                        animation: _anim,
                        builder: (context, child) {
                          return CustomPaint(
                            size: size,
                            painter: _FluidWavePainter(
                              animationValue: _anim.value,
                              touchPos: _touchPos,
                              amplitudeRatio: _currentAmplitudeRatio,
                              isDark: isDark,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 下部：4つの大型タッチオーブ（触れるだけで長時間連続＆滑らかな振動が体感できる）
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                _buildSensoryOrb(
                  label: s.oceanSwell,
                  color: GameColors.joyconBlue,
                  icon: Icons.waves_rounded,
                  onTap: _playSwell,
                  isDark: isDark,
                  gameTheme: gameTheme,
                ),
                const SizedBox(width: 8),
                _buildSensoryOrb(
                  label: s.throttle,
                  color: GameColors.joyconRed,
                  icon: Icons.speed_rounded,
                  onTapDown: _onThrottleDown,
                  onTapUp: _onThrottleUp,
                  isDark: isDark,
                  gameTheme: gameTheme,
                ),
                const SizedBox(width: 8),
                _buildSensoryOrb(
                  label: s.powerCharge,
                  color: GameColors.joyconYellow,
                  icon: Icons.electric_bolt_rounded,
                  onTap: _playCharge,
                  isDark: isDark,
                  gameTheme: gameTheme,
                ),
                const SizedBox(width: 8),
                _buildSensoryOrb(
                  label: s.purr,
                  color: GameColors.joyconPurple,
                  icon: Icons.favorite_rounded,
                  onTap: _playPurr,
                  isDark: isDark,
                  gameTheme: gameTheme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensoryOrb({
    required String label,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
    VoidCallback? onTapDown,
    VoidCallback? onTapUp,
    required bool isDark,
    required GameTheme gameTheme,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        onTapDown: onTapDown != null ? (_) => onTapDown() : null,
        onTapUp: onTapUp != null ? (_) => onTapUp() : null,
        onTapCancel: onTapUp,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.45 : 0.35),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white : color,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FluidWavePainter extends CustomPainter {
  final double animationValue;
  final Offset? touchPos;
  final double amplitudeRatio;
  final bool isDark;

  _FluidWavePainter({
    required this.animationValue,
    required this.touchPos,
    required this.amplitudeRatio,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF151922) : const Color(0xFFE8EEF8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // グリッド線（オシロスコープ感）
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..strokeWidth = 1.0;
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final midY = size.height * 0.5;
    final waveAmp = 20.0 + amplitudeRatio * (size.height * 0.38);

    // 流体波形の描画（2層のオーロラ風ウェーブ）
    for (int layer = 0; layer < 2; layer++) {
      final path = Path();
      final phaseOffset = animationValue * math.pi * 2 + (layer * math.pi * 0.5);
      final color = layer == 0 ? GameColors.joyconBlue : GameColors.joyconPurple;

      path.moveTo(0, midY);
      for (double x = 0; x <= size.width; x += 4) {
        final normX = x / size.width;
        final y = midY +
            math.sin(normX * math.pi * 3 + phaseOffset) * waveAmp * (1.0 - (layer * 0.25)) +
            math.sin(normX * math.pi * 5 - phaseOffset * 0.5) * (waveAmp * 0.3);
        path.lineTo(x, y);
      }

      final wavePaint = Paint()
        ..color = color.withValues(alpha: layer == 0 ? 0.85 : 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = layer == 0 ? 3.5 : 2.0
        ..strokeCap = StrokeCap.round;

      if (layer == 0) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawPath(path, glowPaint);
      }

      canvas.drawPath(path, wavePaint);
    }

    // 指のタッチ位置の波紋 & 振幅インジケーター
    if (touchPos != null) {
      final touchGlow = Paint()
        ..color = GameColors.joyconBlue.withValues(alpha: 0.25 + amplitudeRatio * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawCircle(touchPos!, 40 + amplitudeRatio * 30, touchGlow);

      final touchRing = Paint()
        ..color = GameColors.joyconBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(touchPos!, 28, touchRing);

      final corePoint = Paint()..color = Colors.white;
      canvas.drawCircle(touchPos!, 6, corePoint);
    }
  }

  @override
  bool shouldRepaint(covariant _FluidWavePainter oldDelegate) => true;
}
