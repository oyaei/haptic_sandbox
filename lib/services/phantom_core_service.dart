import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'haptics_service.dart';
import 'sensor_service.dart';

enum CoreMood {
  dormant,
  attracted,
  excited,
  flowing,
}

class PhantomCoreService {
  PhantomCoreService._() {
    _startPulseLoop();
    _startPhysicsLoop();
  }
  static final PhantomCoreService instance = PhantomCoreService._();

  final HapticsService _haptics = HapticsService.instance;
  final SensorService _sensors = SensorService.instance;

  bool isCoreTabActive = false;

  CoreMood _mood = CoreMood.dormant;
  CoreMood get mood => _mood;

  double _posX = 0.0;
  double _posY = 0.0;
  double _velX = 0.0;
  double _velY = 0.0;
  double get posX => _posX;
  double get posY => _posY;

  bool _isHoldingTouch = false;
  bool get isHoldingTouch => _isHoldingTouch;
  double _touchTargetX = 0.0;
  double _touchTargetY = 0.0;
  double get touchTargetX => _touchTargetX;
  double get touchTargetY => _touchTargetY;
  DateTime? _touchStartTime;

  double get touchDistance {
    if (!_isHoldingTouch) return 0.0;
    final dx = _touchTargetX - _posX;
    final dy = _touchTargetY - _posY;
    return math.sqrt(dx * dx + dy * dy);
  }

  Timer? _heartbeatTimer;
  double _heartbeatRateBpm = 68.0;
  double get heartbeatBpm => _heartbeatRateBpm;

  DateTime? _lastImpactTime;

  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);
  void _notify() {
    for (final cb in _listeners) {
      cb();
    }
  }

  void recordUserInteraction() {
    _heartbeatRateBpm = (_heartbeatRateBpm + 3.0).clamp(60.0, 150.0);
  }

  void onTouchStart(double normalizedX, double normalizedY) {
    _isHoldingTouch = true;
    _touchTargetX = normalizedX.clamp(-1.0, 1.0);
    _touchTargetY = normalizedY.clamp(-1.0, 1.0);
    _touchStartTime = DateTime.now();
    _mood = CoreMood.attracted;
    recordUserInteraction();
    _notify();
  }

  void onTouchMove(double normalizedX, double normalizedY) {
    _touchTargetX = normalizedX.clamp(-1.0, 1.0);
    _touchTargetY = normalizedY.clamp(-1.0, 1.0);
  }

  void onTouchEnd() {
    if (_isHoldingTouch) {
      final holdMs = _touchStartTime != null
          ? DateTime.now().difference(_touchStartTime!).inMilliseconds
          : 0;

      final dx = _touchTargetX - _posX;
      final dy = _touchTargetY - _posY;
      final dist = math.sqrt(dx * dx + dy * dy);

      _isHoldingTouch = false;
      _touchStartTime = null;
      _haptics.cancel();

      // 引っ張って離した瞬間に、パチンと弾けるスリングショット反動
      if (dist > 0.25 && isCoreTabActive) {
        _haptics.vibratePredefined('drop');
      } else if (holdMs > 350 && isCoreTabActive) {
        _haptics.vibratePredefined('pop');
      }
      _mood = CoreMood.dormant;
      _notify();
    }
  }

  /// ユーザーが意図的にコアをパルスさせたときのトリガー
  void triggerPulse() {
    _mood = CoreMood.excited;
    _haptics.triggerHapticFeedback(type: 'warp');
    _notify();
    Future.delayed(const Duration(milliseconds: 500), () {
      _mood = CoreMood.dormant;
      _notify();
    });
  }

  void _startPulseLoop() {
    _scheduleNextHeartbeat();
  }

  void _scheduleNextHeartbeat() {
    final intervalMs = ((60.0 / _heartbeatRateBpm) * 1000).round();
    _heartbeatTimer = Timer(Duration(milliseconds: intervalMs), () async {
      // ⚠️ 何も触っていない・操作していない時は絶対に自動振動しない
      // コアに指を触れている時、かつ引っ張っていない時に心拍が手の中でドク…ドク…と脈打つ
      if (_isHoldingTouch && isCoreTabActive && touchDistance <= 0.18) {
        await _haptics.vibrateWaveform([0, 18, 110, 26], [0, 140, 0, 190]);
      }

      if (_heartbeatRateBpm > 68.0) {
        _heartbeatRateBpm -= 1.0;
      }
      _notify();

      _scheduleNextHeartbeat();
    });
  }

  void _startPhysicsLoop() {
    Timer.periodic(const Duration(milliseconds: 20), (timer) {
      // ゴーストコアタブ以外の画面では計算および衝突振動を行わない
      if (!isCoreTabActive) return;

      final motion = _sensors.latestMotion;

      // 加速度センサーによる重力ベクトル
      double gx = -motion.x * 0.08;
      double gy = motion.y * 0.08;

      if (_isHoldingTouch) {
        final dx = _touchTargetX - _posX;
        final dy = _touchTargetY - _posY;
        final dist = math.sqrt(dx * dx + dy * dy);
        gx += dx * 0.35;
        gy += dy * 0.35;

        // ゴムのように引っ張るほど、滑らかに連続振動が強くなる（張力ハプティクス）
        if (dist > 0.18) {
          final tensionAmp = ((dist / 1.1).clamp(0.0, 1.0) * 230).round();
          _haptics.setContinuous(tensionAmp);
        }
      }

      _velX = (_velX + gx) * 0.88;
      _velY = (_velY + gy) * 0.88;

      _posX += _velX * 0.12;
      _posY += _velY * 0.12;

      final now = DateTime.now();
      final canImpact = _lastImpactTime == null || now.difference(_lastImpactTime!).inMilliseconds > 200;
      bool hitWall = false;

      // X軸の壁衝突判定（十分な勢いがある衝突のみトリガーし、静止時の無限バウンド振動を防止）
      if (_posX > 0.95) {
        _posX = 0.95;
        if (_velX > 0.40 && canImpact) {
          hitWall = true;
          _lastImpactTime = now;
        }
        _velX = 0.0;
      } else if (_posX < -0.95) {
        _posX = -0.95;
        if (_velX < -0.40 && canImpact) {
          hitWall = true;
          _lastImpactTime = now;
        }
        _velX = 0.0;
      }

      // Y軸の壁衝突判定
      if (_posY > 0.95) {
        _posY = 0.95;
        if (_velY > 0.40 && canImpact) {
          hitWall = true;
          _lastImpactTime = now;
        }
        _velY = 0.0;
      } else if (_posY < -0.95) {
        _posY = -0.95;
        if (_velY < -0.40 && canImpact) {
          hitWall = true;
          _lastImpactTime = now;
        }
        _velY = 0.0;
      }

      if (hitWall) {
        _haptics.vibratePredefined('thud');
      }

      _notify();
    });
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _listeners.clear();
  }
}
