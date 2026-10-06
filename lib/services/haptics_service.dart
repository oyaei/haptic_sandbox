import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HapticsService {
  HapticsService._();
  static final HapticsService instance = HapticsService._();

  static const MethodChannel _channel = MethodChannel('com.oyaiz.apps.hapbox/haptics');

  bool hapticsEnabled = true;

  final bool _isAndroid = defaultTargetPlatform == TargetPlatform.android;

  /// 単発の振動（持続時間ms、強度1〜255）
  Future<void> vibrateOneShot(int durationMs, int amplitude) async {
    if (!hapticsEnabled) return;
    if (_isAndroid) {
      try {
        await _channel.invokeMethod('vibrateOneShot', {
          'duration': durationMs.clamp(20, 2000),
          'amplitude': amplitude.clamp(1, 255),
        });
        return;
      } catch (e) {
        debugPrint('HapticsService vibrateOneShot error: $e');
      }
    }

    if (amplitude > 180) {
      await HapticFeedback.heavyImpact();
    } else if (amplitude > 90) {
      await HapticFeedback.mediumImpact();
    } else {
      await HapticFeedback.lightImpact();
    }
  }

  /// 定義済みハプティクス（click, double_click, heavy_click, tick, pop, thud, laser, warp, drop, glitch）
  Future<void> vibratePredefined(String type, {int? amplitude}) async {
    if (!hapticsEnabled) return;
    if (_isAndroid) {
      try {
        final args = <String, dynamic>{'type': type};
        if (amplitude != null) {
          args['amplitude'] = amplitude;
        }
        await _channel.invokeMethod('vibratePredefined', args);
        return;
      } catch (e) {
        debugPrint('HapticsService vibratePredefined error: $e');
      }
    }

    switch (type) {
      case 'tick':
        await HapticFeedback.selectionClick();
        break;
      case 'click':
        await HapticFeedback.lightImpact();
        break;
      case 'double_click':
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 60));
        await HapticFeedback.mediumImpact();
        break;
      case 'heavy_click':
      case 'thud':
        await HapticFeedback.heavyImpact();
        break;
      default:
        await HapticFeedback.mediumImpact();
    }
  }

  /// 波形振動（timings: 各ステップの持続ms, amplitudes: 各ステップの強度0-255）
  Future<void> vibrateWaveform(List<int> timings, List<int> amplitudes, {int repeat = -1}) async {
    if (!hapticsEnabled) return;
    if (_isAndroid) {
      try {
        await _channel.invokeMethod('vibrateWaveform', {
          'timings': timings,
          'amplitudes': amplitudes,
          'repeat': repeat,
        });
        return;
      } catch (e) {
        debugPrint('HapticsService vibrateWaveform error: $e');
      }
    }

    for (int i = 0; i < timings.length; i++) {
      if (amplitudes[i] > 0) {
        await HapticFeedback.selectionClick();
      }
      await Future.delayed(Duration(milliseconds: timings[i]));
    }
  }

  /// 高度なコンポジション振動 (Android 11+ / Pixel 等の精密触覚プリミティブ)
  Future<void> vibrateComposition(List<Map<String, dynamic>> primitives) async {
    if (!hapticsEnabled) return;
    if (_isAndroid) {
      try {
        await _channel.invokeMethod('vibrateComposition', {'primitives': primitives});
        return;
      } catch (e) {
        debugPrint('HapticsService vibrateComposition error: $e');
      }
    }

    await HapticFeedback.lightImpact();
  }

  /// 滑らかな連続強度変化（スウェル、クレッシェンド、デクレッシェンド）
  Future<void> vibrateRamp({
    int startAmplitude = 10,
    int endAmplitude = 255,
    int durationMs = 600,
    String curve = 'linear', // 'linear', 'easeIn', 'easeOut', 'easeInOut', 'swell', 'surge'
  }) async {
    if (!hapticsEnabled) return;
    if (_isAndroid) {
      try {
        await _channel.invokeMethod('vibrateRamp', {
          'startAmplitude': startAmplitude.clamp(0, 255),
          'endAmplitude': endAmplitude.clamp(0, 255),
          'durationMs': durationMs.clamp(50, 4000),
          'curve': curve,
        });
        return;
      } catch (e) {
        debugPrint('HapticsService vibrateRamp error: $e');
      }
    }
  }

  /// リアルタイム持続振動（指の移動やドラッグに追従して滑らかに強度を変化）
  Future<void> setContinuous(int amplitude) async {
    if (!hapticsEnabled) return;
    if (_isAndroid) {
      try {
        await _channel.invokeMethod('setContinuous', {
          'amplitude': amplitude.clamp(0, 255),
        });
        return;
      } catch (e) {
        debugPrint('HapticsService setContinuous error: $e');
      }
    }
  }

  /// 振動を即座に停止
  Future<void> cancel() async {
    if (_isAndroid) {
      try {
        await _channel.invokeMethod('cancel');
      } catch (e) {
        debugPrint('HapticsService cancel error: $e');
      }
    }
  }

  /// 複合ハプティクストリガー（スピーカー音は出さず、バイブレーションのみ）
  Future<void> triggerHapticFeedback({
    required String type,
    int durationMs = 30,
    int amplitude = 200,
    double soundPitch = 1.0,
    bool withSound = false,
  }) async {
    switch (type.toLowerCase()) {
      case 'click':
      case 'tick':
      case 'pop':
      case 'thud':
      case 'laser':
      case 'warp':
      case 'drop':
      case 'glitch':
      case 'double_click':
      case 'heavy_click':
      case 'engine_rev':
      case 'ocean_swell':
      case 'power_charge':
      case 'laser_beam':
      case 'purr':
        await vibratePredefined(type, amplitude: amplitude);
        break;
      case 'swell':
        await vibrateRamp(startAmplitude: 15, endAmplitude: amplitude, durationMs: 1200, curve: 'swell');
        break;
      case 'surge':
        await vibrateRamp(startAmplitude: 20, endAmplitude: amplitude, durationMs: 1500, curve: 'surge');
        break;
      case 'ramp_up':
        await vibrateRamp(startAmplitude: 10, endAmplitude: amplitude, durationMs: durationMs, curve: 'easein');
        break;
      case 'ramp_down':
        await vibrateRamp(startAmplitude: amplitude, endAmplitude: 10, durationMs: durationMs, curve: 'easeout');
        break;
      default:
        await vibrateOneShot(durationMs, amplitude);
    }
  }
}
