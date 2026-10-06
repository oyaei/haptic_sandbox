class HapticStep {
  bool active;
  String type; // 'click', 'tick', 'thud', 'pop', 'glitch', 'warp', 'drop'
  int amplitude; // 1 ~ 255
  int durationMs; // 5 ~ 150
  double pitch; // 0.5 ~ 2.0

  HapticStep({
    this.active = false,
    this.type = 'click',
    this.amplitude = 180,
    this.durationMs = 25,
    this.pitch = 1.0,
  });

  HapticStep copyWith({
    bool? active,
    String? type,
    int? amplitude,
    int? durationMs,
    double? pitch,
  }) {
    return HapticStep(
      active: active ?? this.active,
      type: type ?? this.type,
      amplitude: amplitude ?? this.amplitude,
      durationMs: durationMs ?? this.durationMs,
      pitch: pitch ?? this.pitch,
    );
  }
}
