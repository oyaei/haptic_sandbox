import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/haptic_step.dart';
import '../services/haptics_service.dart';
import '../services/phantom_core_service.dart';
import '../theme/game_theme.dart';
import '../widgets/oscilloscope_view.dart';

class SequencerTab extends StatefulWidget {
  final bool isActive;
  const SequencerTab({super.key, this.isActive = true});

  @override
  State<SequencerTab> createState() => _SequencerTabState();
}

class _SequencerTabState extends State<SequencerTab> {
  final HapticsService _haptics = HapticsService.instance;
  final PhantomCoreService _core = PhantomCoreService.instance;
  final ThemeService _theme = ThemeService.instance;
  final LocalizationService _loc = LocalizationService.instance;

  @override
  void didUpdateWidget(covariant SequencerTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive && _isPlaying) {
      _stopPlayback();
    }
  }

  int _bpm = 120;
  bool _isPlaying = false;
  int _currentStepIndex = -1;
  Timer? _playbackTimer;
  double _activityLevel = 0.0;

  // 8ステップ構成（画面いっぱいに大きく配置して直感操作）
  late List<HapticStep> _steps;

  final List<String> _stepTypes = ['click', 'thud', 'pop', 'laser_beam', 'glitch'];

  @override
  void initState() {
    super.initState();
    _theme.addListener(_onThemeUpdate);
    _loc.addListener(_onThemeUpdate);
    _steps = [
      HapticStep(active: true, type: 'thud', amplitude: 255),
      HapticStep(active: false, type: 'click', amplitude: 160),
      HapticStep(active: true, type: 'click', amplitude: 180),
      HapticStep(active: false, type: 'click', amplitude: 140),
      HapticStep(active: true, type: 'laser_beam', amplitude: 240), // 連続持続ビーム
      HapticStep(active: false, type: 'click', amplitude: 140),
      HapticStep(active: true, type: 'pop', amplitude: 200),
      HapticStep(active: true, type: 'thud', amplitude: 220),
    ];
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _haptics.cancel();
    _theme.removeListener(_onThemeUpdate);
    _loc.removeListener(_onThemeUpdate);
    super.dispose();
  }

  void _onThemeUpdate() {
    if (mounted) setState(() {});
  }

  void _startPlayback() {
    _isPlaying = true;
    _currentStepIndex = -1;
    _scheduleNextStep();
    setState(() {});
  }

  void _stopPlayback() {
    _isPlaying = false;
    _playbackTimer?.cancel();
    _currentStepIndex = -1;
    _activityLevel = 0.0;
    _haptics.cancel();
    setState(() {});
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _stopPlayback();
      _haptics.vibratePredefined('tick');
    } else {
      _startPlayback();
      _haptics.vibratePredefined('click');
    }
  }

  void _scheduleNextStep() {
    if (!_isPlaying) return;
    final stepIntervalMs = ((60000.0 / _bpm) / 2).round().clamp(50, 1500);

    _playbackTimer = Timer(Duration(milliseconds: stepIntervalMs), () async {
      if (!_isPlaying) return;
      _currentStepIndex = (_currentStepIndex + 1) % _steps.length;

      final step = _steps[_currentStepIndex];
      if (step.active) {
        _activityLevel = 1.0;
        await _haptics.triggerHapticFeedback(
          type: step.type,
          durationMs: step.durationMs,
          amplitude: step.amplitude,
        );
        _core.recordUserInteraction();
      } else {
        _activityLevel = math.max(0.0, _activityLevel - 0.25);
      }

      if (mounted) {
        setState(() {});
      }
      _scheduleNextStep();
    });
  }

  void _toggleStep(int index) {
    setState(() {
      _steps[index].active = !_steps[index].active;
    });

    if (_steps[index].active) {
      _previewStep(_steps[index]);
    } else {
      _haptics.vibratePredefined('tick');
    }
  }

  void _cycleStepType(int index) {
    final current = _steps[index].type;
    final nextIdx = (_stepTypes.indexOf(current) + 1) % _stepTypes.length;
    final nextType = _stepTypes[nextIdx];
    setState(() {
      _steps[index].type = nextType;
      _steps[index].active = true;
    });
    _previewStep(_steps[index]);
  }

  void _previewStep(HapticStep step) {
    _activityLevel = 1.0;
    _haptics.triggerHapticFeedback(
      type: step.type,
      durationMs: step.durationMs,
      amplitude: step.amplitude,
    );
    _core.recordUserInteraction();
  }

  void _randomize() {
    final random = math.Random();
    setState(() {
      for (int i = 0; i < _steps.length; i++) {
        _steps[i].active = random.nextDouble() > 0.35;
        _steps[i].type = _stepTypes[random.nextInt(_stepTypes.length)];
        _steps[i].amplitude = 100 + random.nextInt(156);
      }
    });
    _haptics.triggerHapticFeedback(type: 'glitch');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _theme.isDark;
    final gameTheme = GameTheme(isDark);
    final s = _loc.strings;

    return Container(
      color: gameTheme.bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          // 上部：Switch風オシロスコープ波形モニター
          Container(
            height: 80,
            decoration: gameTheme.gameCard(radius: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: OscilloscopeView(
                activityLevel: _activityLevel,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // メイン：直感的な8ステップ・ビートマトリクス（パッドタップでON/OFF、長押しでタイプ切替、上下ドラッグで強度調整）
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                final isCurrent = _isPlaying && _currentStepIndex == index;
                final isBeam = step.type == 'laser_beam';

                return GestureDetector(
                  onTap: () => _toggleStep(index),
                  onLongPress: () => _cycleStepType(index),
                  onVerticalDragUpdate: (details) {
                    // 上下にスライドするだけで直感的に強度（amplitude）を滑らかに調整
                    final delta = -details.delta.dy * 2.5;
                    setState(() {
                      step.amplitude = (step.amplitude + delta).round().clamp(30, 255);
                      step.active = true;
                    });
                    _haptics.setContinuous(step.amplitude);
                  },
                  onVerticalDragEnd: (_) {
                    _haptics.cancel();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(
                      color: step.active
                          ? (isBeam
                              ? GameColors.joyconPurple.withValues(alpha: isDark ? 0.35 : 0.22)
                              : GameColors.joyconYellow.withValues(alpha: isDark ? 0.35 : 0.22))
                          : (isDark ? const Color(0xFF1E2330) : const Color(0xFFEAEEF5)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrent
                            ? Colors.white
                            : (step.active
                                ? (isBeam ? GameColors.joyconPurple : GameColors.joyconYellow)
                                : gameTheme.border),
                        width: isCurrent ? 3.0 : (step.active ? 2.0 : 1.0),
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: (isBeam ? GameColors.joyconPurple : GameColors.joyconYellow)
                                    .withValues(alpha: 0.6),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        // 強度（振幅）を示す縦バーインジケーター
                        if (step.active)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 6,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isBeam ? GameColors.joyconPurple : GameColors.joyconYellow,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),

                        // パッドコンテンツ
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: step.active ? gameTheme.textMain : gameTheme.textDim,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Icon(
                                isBeam
                                    ? Icons.bolt_rounded
                                    : (step.type == 'thud'
                                        ? Icons.radio_button_checked
                                        : (step.type == 'pop' ? Icons.bubble_chart : Icons.touch_app)),
                                color: step.active
                                    ? (isBeam ? GameColors.joyconPurple : GameColors.joyconYellow)
                                    : gameTheme.textDim,
                                size: 22,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isBeam ? 'BEAM' : step.type.toUpperCase(),
                                style: TextStyle(
                                  color: step.active
                                      ? (isBeam ? GameColors.joyconPurple : GameColors.joyconYellow)
                                      : gameTheme.textDim,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 下部コントロールバー（極力ボタンを削減し、1つの巨大PlayボタンとBPMスライダーに集約）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: gameTheme.gameCard(radius: 16),
            child: Row(
              children: [
                // 巨大な再生 / 停止ボタン（直感的に触れば判る）
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: _togglePlayback,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isPlaying ? GameColors.joyconRed : GameColors.joyconBlue,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (_isPlaying ? GameColors.joyconRed : GameColors.joyconBlue)
                                .withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isPlaying ? s.stop : s.play,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // BPM調整スライダー
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Text(
                        '${_bpm}BPM',
                        style: TextStyle(
                          color: gameTheme.textMain,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _bpm.toDouble(),
                          min: 60,
                          max: 200,
                          activeColor: GameColors.joyconYellow,
                          onChanged: (val) {
                            setState(() => _bpm = val.round());
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // ランダム生成ダイスボタン
                IconButton(
                  icon: const Icon(Icons.casino_rounded, color: GameColors.joyconYellow, size: 24),
                  tooltip: 'Shuffle',
                  onPressed: _randomize,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
