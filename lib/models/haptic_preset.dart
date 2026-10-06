import 'haptic_step.dart';

class HapticPreset {
  final String id;
  final String title;
  final String subtitle;
  final int bpm;
  final List<HapticStep> steps;

  const HapticPreset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.bpm,
    required this.steps,
  });

  static List<HapticPreset> get defaultPresets {
    return [
      HapticPreset(
        id: 'cyber_groove',
        title: 'CYBER GROOVE',
        subtitle: '四つ打ちキックとハイハットの小気味良いビート',
        bpm: 128,
        steps: [
          HapticStep(active: true, type: 'thud', amplitude: 255, pitch: 0.9),
          HapticStep(active: false),
          HapticStep(active: true, type: 'tick', amplitude: 120, pitch: 1.5),
          HapticStep(active: false),
          HapticStep(active: true, type: 'click', amplitude: 200, pitch: 1.2),
          HapticStep(active: false),
          HapticStep(active: true, type: 'tick', amplitude: 120, pitch: 1.5),
          HapticStep(active: false),
          HapticStep(active: true, type: 'thud', amplitude: 240, pitch: 0.9),
          HapticStep(active: false),
          HapticStep(active: true, type: 'tick', amplitude: 140, pitch: 1.6),
          HapticStep(active: true, type: 'glitch', amplitude: 160, pitch: 1.1),
          HapticStep(active: true, type: 'click', amplitude: 220, pitch: 1.2),
          HapticStep(active: false),
          HapticStep(active: true, type: 'tick', amplitude: 130, pitch: 1.5),
          HapticStep(active: true, type: 'pop', amplitude: 170, pitch: 1.4),
        ],
      ),
      HapticPreset(
        id: 'machine_gun',
        title: 'OVERDRIVE BLASTER',
        subtitle: '連射ガトリングガンの強烈な反動と排莢',
        bpm: 180,
        steps: List.generate(
          16,
          (i) => HapticStep(
            active: true,
            type: i % 2 == 0 ? 'thud' : 'click',
            amplitude: i % 4 == 0 ? 255 : 200,
            pitch: 1.0 + (i % 3) * 0.2,
          ),
        ),
      ),
      HapticPreset(
        id: 'heartbeat',
        title: 'BIO HEARTBEAT',
        subtitle: 'ドクン…ドクン…と脈打つ生体の鼓動',
        bpm: 72,
        steps: [
          HapticStep(active: true, type: 'thud', amplitude: 220, pitch: 0.7),
          HapticStep(active: true, type: 'thud', amplitude: 160, pitch: 0.8),
          HapticStep(active: false),
          HapticStep(active: false),
          HapticStep(active: false),
          HapticStep(active: false),
          HapticStep(active: false),
          HapticStep(active: false),
          HapticStep(active: true, type: 'thud', amplitude: 230, pitch: 0.7),
          HapticStep(active: true, type: 'thud', amplitude: 170, pitch: 0.8),
          HapticStep(active: false),
          HapticStep(active: false),
          HapticStep(active: false),
          HapticStep(active: false),
          HapticStep(active: false),
          HapticStep(active: false),
        ],
      ),
      HapticPreset(
        id: 'warp_engine',
        title: 'WARP ENGINE',
        subtitle: '時空跳躍の加速と空間歪曲パルス',
        bpm: 140,
        steps: [
          HapticStep(active: true, type: 'warp', amplitude: 255, pitch: 1.0),
          HapticStep(active: false),
          HapticStep(active: true, type: 'laser', amplitude: 190, pitch: 1.4),
          HapticStep(active: false),
          HapticStep(active: true, type: 'pop', amplitude: 160, pitch: 1.6),
          HapticStep(active: true, type: 'pop', amplitude: 180, pitch: 1.8),
          HapticStep(active: true, type: 'glitch', amplitude: 220, pitch: 0.9),
          HapticStep(active: false),
          HapticStep(active: true, type: 'drop', amplitude: 255, pitch: 0.6),
          HapticStep(active: false),
          HapticStep(active: true, type: 'tick', amplitude: 140, pitch: 1.5),
          HapticStep(active: false),
          HapticStep(active: true, type: 'glitch', amplitude: 200, pitch: 1.2),
          HapticStep(active: true, type: 'laser', amplitude: 230, pitch: 1.7),
          HapticStep(active: false),
          HapticStep(active: true, type: 'warp', amplitude: 240, pitch: 1.1),
        ],
      ),
      HapticPreset(
        id: 'purring_cat',
        title: 'FELINE PURR',
        subtitle: '猫が喉をゴロゴロ鳴らす安らぎの微細連続振動',
        bpm: 110,
        steps: List.generate(
          16,
          (i) => HapticStep(
            active: i % 4 != 3,
            type: 'tick',
            amplitude: (80 + 30 * (i % 3)),
            pitch: 0.6 + 0.1 * (i % 2),
          ),
        ),
      ),
      HapticPreset(
        id: 'earthquake',
        title: 'SEISMIC RUMBLE',
        subtitle: '大地の轟音と震動のランダム波形',
        bpm: 160,
        steps: [
          HapticStep(active: true, type: 'thud', amplitude: 240, pitch: 0.6),
          HapticStep(active: true, type: 'glitch', amplitude: 210, pitch: 0.7),
          HapticStep(active: true, type: 'thud', amplitude: 255, pitch: 0.5),
          HapticStep(active: false),
          HapticStep(active: true, type: 'glitch', amplitude: 230, pitch: 0.8),
          HapticStep(active: true, type: 'thud', amplitude: 220, pitch: 0.6),
          HapticStep(active: false),
          HapticStep(active: true, type: 'drop', amplitude: 250, pitch: 0.6),
          HapticStep(active: true, type: 'thud', amplitude: 245, pitch: 0.7),
          HapticStep(active: true, type: 'glitch', amplitude: 220, pitch: 0.8),
          HapticStep(active: false),
          HapticStep(active: true, type: 'thud', amplitude: 255, pitch: 0.5),
          HapticStep(active: true, type: 'drop', amplitude: 230, pitch: 0.6),
          HapticStep(active: false),
          HapticStep(active: true, type: 'glitch', amplitude: 240, pitch: 0.7),
          HapticStep(active: true, type: 'thud', amplitude: 250, pitch: 0.5),
        ],
      ),
    ];
  }
}
