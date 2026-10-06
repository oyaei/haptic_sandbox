import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MotionData {
  final double x; // 横方向傾き (-9.8 ~ +9.8)
  final double y; // 縦方向傾き (-9.8 ~ +9.8)
  final double z; // 垂直方向
  final double pitch; // 前後傾斜度
  final double roll;  // 左右傾斜度

  const MotionData({
    this.x = 0.0,
    this.y = 0.0,
    this.z = 9.8,
    this.pitch = 0.0,
    this.roll = 0.0,
  });
}

class SensorService {
  SensorService._() {
    _initSensorStream();
  }
  static final SensorService instance = SensorService._();

  static const EventChannel _eventChannel = EventChannel('com.oyaiz.apps.hapbox/sensors');

  StreamController<MotionData>? _motionStreamController;
  StreamSubscription? _subscription;

  MotionData _latestMotion = const MotionData();
  MotionData get latestMotion => _latestMotion;

  // 仮想チルト（シミュレータ用や手動デバッグ用）
  double _manualTiltX = 0.0;
  double _manualTiltY = 0.0;
  bool _useManualTilt = false;

  void setManualTilt(double tiltX, double tiltY) {
    _useManualTilt = true;
    _manualTiltX = tiltX.clamp(-1.0, 1.0);
    _manualTiltY = tiltY.clamp(-1.0, 1.0);
    final data = MotionData(
      x: -_manualTiltX * 9.8,
      y: _manualTiltY * 9.8,
      z: 9.8,
      pitch: _manualTiltY * 45.0,
      roll: -_manualTiltX * 45.0,
    );
    _latestMotion = data;
    _motionStreamController?.add(data);
  }

  void resetManualTilt() {
    _useManualTilt = false;
  }

  Stream<MotionData> get motionStream {
    _motionStreamController ??= StreamController<MotionData>.broadcast();
    return _motionStreamController!.stream;
  }

  void _initSensorStream() {
    _motionStreamController = StreamController<MotionData>.broadcast();

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        _subscription = _eventChannel.receiveBroadcastStream().listen(
          (dynamic event) {
            if (_useManualTilt) return;
            if (event is Map) {
              final rawX = (event['x'] as num?)?.toDouble() ?? 0.0;
              final rawY = (event['y'] as num?)?.toDouble() ?? 0.0;
              final rawZ = (event['z'] as num?)?.toDouble() ?? 9.8;

              // スムージングとピッチ・ロール計算
              final data = MotionData(
                x: rawX,
                y: rawY,
                z: rawZ,
                pitch: rawY * 9.0,
                roll: rawX * 9.0,
              );
              _latestMotion = data;
              _motionStreamController?.add(data);
            }
          },
          onError: (dynamic error) {
            debugPrint('SensorService error: $error');
          },
        );
      } catch (e) {
        debugPrint('SensorService stream setup failed: $e');
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _motionStreamController?.close();
  }
}
