import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/haptics_service.dart';
import '../services/phantom_core_service.dart';
import '../theme/game_theme.dart';
import '../widgets/game_button.dart';

class HapticVaultTab extends StatefulWidget {
  const HapticVaultTab({super.key});

  @override
  State<HapticVaultTab> createState() => _HapticVaultTabState();
}

class _HapticVaultTabState extends State<HapticVaultTab> {
  final HapticsService _haptics = HapticsService.instance;
  final PhantomCoreService _core = PhantomCoreService.instance;
  final ThemeService _theme = ThemeService.instance;
  final LocalizationService _loc = LocalizationService.instance;

  double _rotationAngle = 0.0;
  int _currentNumber = 0;
  int _prevNotifiedNumber = -1;

  final List<int> _targetCombination = [37, 72, 18];
  int _currentStage = 0;
  final List<bool> _stageSolved = [false, false, false];
  bool _isVaultUnlocked = false;

  Offset? _dialCenter;
  double? _initialTouchAngle;
  double? _initialRotationAngle;

  @override
  void initState() {
    super.initState();
    _theme.addListener(_onUpdate);
    _loc.addListener(_onUpdate);
    _generateRandomCombination();
  }

  @override
  void dispose() {
    _theme.removeListener(_onUpdate);
    _loc.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _generateRandomCombination() {
    final rand = math.Random();
    _targetCombination[0] = 10 + rand.nextInt(80);
    _targetCombination[1] = 10 + rand.nextInt(80);
    _targetCombination[2] = 10 + rand.nextInt(80);
    _currentStage = 0;
    _stageSolved.fillRange(0, 3, false);
    _isVaultUnlocked = false;
    _currentNumber = 0;
    _rotationAngle = 0.0;
  }

  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    _dialCenter = Offset(constraints.maxWidth / 2, constraints.maxHeight * 0.42);
    final touchOffset = details.localPosition - _dialCenter!;
    _initialTouchAngle = math.atan2(touchOffset.dy, touchOffset.dx);
    _initialRotationAngle = _rotationAngle;
    _core.recordUserInteraction();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dialCenter == null || _initialTouchAngle == null || _initialRotationAngle == null) return;
    if (_isVaultUnlocked) return;

    final touchOffset = details.localPosition - _dialCenter!;
    final currentTouchAngle = math.atan2(touchOffset.dy, touchOffset.dx);
    final deltaAngle = currentTouchAngle - _initialTouchAngle!;

    setState(() {
      _rotationAngle = _initialRotationAngle! + deltaAngle;
      final normAngle = (_rotationAngle / (2 * math.pi)) % 1.0;
      _currentNumber = ((normAngle < 0 ? normAngle + 1.0 : normAngle) * 100).round() % 100;
    });

    if (_currentNumber != _prevNotifiedNumber) {
      _prevNotifiedNumber = _currentNumber;
      _checkDialFeedback(_currentNumber);
    }
  }

  void _checkDialFeedback(int number) {
    if (_currentStage >= 3) return;
    final target = _targetCombination[_currentStage];
    final diff = (number - target).abs().clamp(0, 50);

    if (diff == 0) {
      _haptics.vibratePredefined('pop');
    } else if (diff <= 1) {
      _haptics.vibratePredefined('double_click');
    } else if (diff <= 3) {
      _haptics.vibratePredefined('click');
    } else {
      _haptics.vibratePredefined('tick');
    }
  }

  void _tryUnlockStage() {
    if (_isVaultUnlocked) return;
    final target = _targetCombination[_currentStage];

    if (_currentNumber == target) {
      setState(() {
        _stageSolved[_currentStage] = true;
        _currentStage++;
        if (_currentStage >= 3) {
          _isVaultUnlocked = true;
        }
      });

      if (_isVaultUnlocked) {
        _haptics.triggerHapticFeedback(type: 'warp');
        Future.delayed(const Duration(milliseconds: 300), () {
          _haptics.triggerHapticFeedback(type: 'laser');
        });
      } else {
        _haptics.triggerHapticFeedback(type: 'pop');
      }
    } else {
      _haptics.triggerHapticFeedback(type: 'thud');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _theme.isDark;
    final gameTheme = GameTheme(isDark);
    final s = _loc.strings;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: gameTheme.bg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // タイトルとステータス
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.vaultTitle,
                        style: TextStyle(
                          color: GameColors.joyconRed,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.vaultSubtitle,
                        style: TextStyle(color: gameTheme.textDim, fontSize: 11),
                      ),
                    ],
                  ),
                  GameButton(
                    width: 44,
                    height: 38,
                    isSecondary: true,
                    color: GameColors.joyconBlue,
                    radius: 12,
                    onPressed: () {
                      setState(() => _generateRandomCombination());
                      _haptics.triggerHapticFeedback(type: 'warp');
                    },
                    child: const Icon(Icons.refresh_rounded, color: GameColors.joyconBlue, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3つのロックインジケーター (Nintendo ステージクリアバッジ風)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final isDone = _stageSolved[index];
                  final isCurrent = _currentStage == index && !_isVaultUnlocked;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: gameTheme.gameCard(
                      customBg: isDone
                          ? GameColors.joyconGreen.withValues(alpha: isDark ? 0.25 : 0.15)
                          : (isCurrent
                              ? GameColors.joyconYellow.withValues(alpha: isDark ? 0.25 : 0.18)
                              : gameTheme.card),
                      customBorder: isDone
                          ? GameColors.joyconGreen
                          : (isCurrent ? GameColors.joyconYellow : gameTheme.border),
                      radius: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDone ? Icons.lock_open_rounded : Icons.lock_rounded,
                          size: 18,
                          color: isDone
                              ? GameColors.joyconGreen
                              : (isCurrent ? (isDark ? GameColors.joyconYellow : Colors.orange.shade800) : gameTheme.textDim),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDone ? '${_targetCombination[index]}' : '??',
                          style: TextStyle(
                            color: isDone
                                ? GameColors.joyconGreen
                                : (isCurrent ? gameTheme.textMain : gameTheme.textDim),
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const Spacer(),

              // 回転金庫ダイヤル (Switch / DS タッチホイール風)
              GestureDetector(
                onPanStart: (d) => _onPanStart(d, constraints),
                onPanUpdate: _onPanUpdate,
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: _rotationAngle,
                        child: CustomPaint(
                          size: const Size(250, 250),
                          painter: _VaultDialPainter(isDark: isDark),
                        ),
                      ),
                      // センターノブ
                      Container(
                        width: 106,
                        height: 106,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: gameTheme.surface,
                          border: Border.all(
                            color: _isVaultUnlocked ? GameColors.joyconGreen : GameColors.joyconRed,
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isVaultUnlocked ? GameColors.joyconGreen : GameColors.joyconRed)
                                  .withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$_currentNumber',
                            style: TextStyle(
                              color: _isVaultUnlocked ? GameColors.joyconGreen : gameTheme.textMain,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                      // ダイヤル上部の赤い照準
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 5,
                          height: 18,
                          decoration: BoxDecoration(
                            color: GameColors.joyconRed,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: GameColors.joyconRed.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // 解錠確定ボタン
              if (!_isVaultUnlocked)
                GameButton(
                  color: GameColors.joyconRed,
                  height: 54,
                  radius: 18,
                  onPressed: _tryUnlockStage,
                  child: Text(
                    'STAGE ${_currentStage + 1} ${s.unlockStage}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 15,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: GameColors.joyconGreen.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: GameColors.joyconGreen, width: 2.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_open_rounded, color: GameColors.joyconGreen, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        s.vaultSuccess,
                        style: const TextStyle(
                          color: GameColors.joyconGreen,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _VaultDialPainter extends CustomPainter {
  final bool isDark;

  _VaultDialPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius - 4, ringPaint);

    final tickPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3)
      ..strokeWidth = 1.5;

    final majorTickPaint = Paint()
      ..color = GameColors.joyconBlue
      ..strokeWidth = 3.0;

    for (int i = 0; i < 100; i++) {
      final angle = (i / 100.0) * 2 * math.pi;
      final isMajor = i % 10 == 0;
      final tickLength = isMajor ? 14.0 : 7.0;

      final startX = center.dx + (radius - 8) * math.cos(angle);
      final startY = center.dy + (radius - 8) * math.sin(angle);
      final endX = center.dx + (radius - 8 - tickLength) * math.cos(angle);
      final endY = center.dy + (radius - 8 - tickLength) * math.sin(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        isMajor ? majorTickPaint : tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VaultDialPainter oldDelegate) => oldDelegate.isDark != isDark;
}
