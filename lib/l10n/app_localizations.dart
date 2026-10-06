import 'package:flutter/material.dart';

enum AppLanguage {
  ja('日本語', 'ja'),
  en('English', 'en'),
  zh('简体中文', 'zh'),
  es('Español', 'es'),
  fr('Français', 'fr'),
  de('Deutsch', 'de'),
  ko('한국어', 'ko'),
  pt('Português', 'pt');

  final String label;
  final String code;
  const AppLanguage(this.label, this.code);
}

class AppStrings {
  final Map<String, String> _map;
  const AppStrings(this._map);

  String get(String key) => _map[key] ?? key;

  // 便利ゲッター
  String get appTitle => get('appTitle');
  String get tabStudio => get('tabStudio');
  String get tabSurge => get('tabSurge');
  String get tabTouchLab => get('tabTouchLab');
  String get tabGhostCore => get('tabGhostCore');
  String get tabSequencer => get('tabSequencer');
  String get studioStrength => get('studioStrength');
  String get studioLength => get('studioLength');
  String get studioRepeat => get('studioRepeat');
  String get studioTestHaptics => get('studioTestHaptics');
  String get play => get('play');
  String get stop => get('stop');
  String get tempo => get('tempo');
  String get surgeHint => get('surgeHint');
  String get oceanSwell => get('oceanSwell');
  String get throttle => get('throttle');
  String get powerCharge => get('powerCharge');
  String get purr => get('purr');
  String get ghostCorePureHint => get('ghostCorePureHint');
  String get touchHint => get('touchHint');
  String get modeLight => get('modeLight');
  String get modeDark => get('modeDark');
  String get switchTheme => get('switchTheme');
  String get soundOffVibeOnly => get('soundOffVibeOnly');
  String get coreStatusSynced => get('coreStatusSynced');
  String get coreStatusEngaged => get('coreStatusEngaged');
  String get coreStatusResonating => get('coreStatusResonating');
  String get coreStatusDrifting => get('coreStatusDrifting');
  String get vaultTitle => get('vaultTitle');
  String get vaultSubtitle => get('vaultSubtitle');
  String get unlockStage => get('unlockStage');
  String get vaultSuccess => get('vaultSuccess');
}

class LocalizationService extends ChangeNotifier {
  LocalizationService._();
  static final LocalizationService instance = LocalizationService._();

  AppLanguage _currentLanguage = AppLanguage.ja;
  AppLanguage get currentLanguage => _currentLanguage;

  AppStrings get strings => _localizedValues[_currentLanguage] ?? _localizedValues[AppLanguage.ja]!;

  void setLanguage(AppLanguage lang) {
    if (_currentLanguage != lang) {
      _currentLanguage = lang;
      notifyListeners();
    }
  }

  static final Map<AppLanguage, AppStrings> _localizedValues = {
    AppLanguage.ja: const AppStrings({
      'appTitle': 'HAPBOX',
      'tabStudio': '触覚スタジオ',
      'tabSurge': 'うねり (SURGE)',
      'tabTouchLab': '触感ラボ',
      'tabGhostCore': 'ゴーストコア',
      'tabSequencer': 'ビート',
      'studioStrength': '⚡ 強さ (STRENGTH)',
      'studioLength': '⏱️ 長さ (LENGTH)',
      'studioRepeat': '🔁 リピート設定',
      'studioTestHaptics': '触覚テスト',
      'play': '再生',
      'stop': '停止',
      'tempo': 'テンポ',
      'surgeHint': 'なぞって波をあやつる • 上下に動かすと強さが滑らかに変化',
      'oceanSwell': '🌊 SWELL',
      'throttle': '🏎️ THROTTLE',
      'powerCharge': '⚡ CHARGE',
      'purr': '🐱 PURR',
      'ghostCorePureHint': '触れて感じる心拍 • 傾けて感じる重力 • 引っ張って弾く張力',
      'touchHint': 'なぞって触感を体感',
      'modeLight': 'ライト',
      'modeDark': 'ダーク',
      'switchTheme': 'テーマ切替',
      'soundOffVibeOnly': '触覚バイブレーションのみ駆動中',
      'coreStatusSynced': 'SYNCED',
    }),
    AppLanguage.en: const AppStrings({
      'appTitle': 'HAPBOX',
      'tabStudio': 'STUDIO',
      'tabSurge': 'SURGE',
      'tabTouchLab': 'TOUCH LAB',
      'tabGhostCore': 'GHOST CORE',
      'tabSequencer': 'BEATS',
      'studioStrength': '⚡ STRENGTH',
      'studioLength': '⏱️ LENGTH',
      'studioRepeat': '🔁 REPEAT SETTING',
      'studioTestHaptics': 'TEST VIBRATION',
      'play': 'PLAY',
      'stop': 'STOP',
      'tempo': 'TEMPO',
      'surgeHint': 'Drag to shape waves • Move vertically to smoothly swell intensity',
      'oceanSwell': '🌊 SWELL',
      'throttle': '🏎️ THROTTLE',
      'powerCharge': '⚡ CHARGE',
      'purr': '🐱 PURR',
      'ghostCorePureHint': 'Touch to feel heartbeat • Tilt to feel gravity • Pull to stretch',
      'touchHint': 'Swipe to feel textures',
      'modeLight': 'LIGHT',
      'modeDark': 'DARK',
      'switchTheme': 'THEME',
      'soundOffVibeOnly': 'Pure Haptic Vibration Mode',
      'coreStatusSynced': 'SYNCED',
    }),
    AppLanguage.zh: const AppStrings({
      'appTitle': 'HAPBOX',
      'tabStudio': '触感工坊',
      'tabSurge': '波动 (SURGE)',
      'tabTouchLab': '触感实验室',
      'tabGhostCore': '幽灵重力核',
      'tabSequencer': '节奏律动',
      'studioStrength': '⚡ 振动强度',
      'studioLength': '⏱️ 振动时长',
      'studioRepeat': '🔁 循环设置',
      'studioTestHaptics': '振动测试',
      'play': '播放',
      'stop': '停止',
      'tempo': '速度',
      'surgeHint': '滑动掌控波动 • 上下滑动平滑调节振动强度',
      'oceanSwell': '🌊 涌动',
      'throttle': '🏎️ 加速',
      'powerCharge': '⚡ 蓄能',
      'purr': '🐱 呼噜',
      'ghostCorePureHint': '触摸感受心跳 • 倾斜感受重力 • 拖曳感受张力',
      'touchHint': '滑动触摸纹理',
      'modeLight': '浅色',
      'modeDark': '深色',
      'switchTheme': '主题切换',
      'soundOffVibeOnly': '纯触觉振动模式',
      'coreStatusSynced': 'SYNCED',
    }),
    AppLanguage.es: const AppStrings({
      'appTitle': 'HAPBOX',
      'tabStudio': 'ESTUDIO',
      'tabSurge': 'ONDA',
      'tabTouchLab': 'LAB TÁCTIL',
      'tabGhostCore': 'NÚCLEO VIVO',
      'tabSequencer': 'RITMO',
      'studioStrength': '⚡ FUERZA',
      'studioLength': '⏱️ DURACIÓN',
      'studioRepeat': '🔁 REPETICIÓN',
      'studioTestHaptics': 'PROBAR HÁPTICA',
      'play': 'REPRODUCIR',
      'stop': 'DETENER',
      'tempo': 'TEMPO',
      'surgeHint': 'Desliza para sentir la ola • Mueve verticalmente para modular la fuerza',
      'oceanSwell': '🌊 OLEADA',
      'throttle': '🏎️ ACELERACIÓN',
      'powerCharge': '⚡ CARGA',
      'purr': '🐱 RONRONEO',
      'ghostCorePureHint': 'Toca para latidos • Inclina para gravedad • Tira para tensión',
      'touchHint': 'Desliza para sentir texturas',
      'modeLight': 'CLARO',
      'modeDark': 'OSCURO',
      'switchTheme': 'TEMA',
      'soundOffVibeOnly': 'Modo de Vibración Pura',
      'coreStatusSynced': 'SYNCED',
    }),
    AppLanguage.fr: const AppStrings({
      'appTitle': 'HAPBOX',
      'tabStudio': 'STUDIO',
      'tabSurge': 'ONDE',
      'tabTouchLab': 'LAB HAPTIQUE',
      'tabGhostCore': 'CŒUR FANTÔME',
      'tabSequencer': 'RYTHME',
      'studioStrength': '⚡ INTENSITÉ',
      'studioLength': '⏱️ DURÉE',
      'studioRepeat': '🔁 RÉPÉTITION',
      'studioTestHaptics': 'TESTER HAPTIQUE',
      'play': 'LECTURE',
      'stop': 'ARRÊTER',
      'tempo': 'TEMPO',
      'surgeHint': 'Glissez pour sculpter l\'onde • Bougez verticalement pour faire varier l\'intensité',
      'oceanSwell': '🌊 HOULE',
      'throttle': '🏎️ ACCÉLÉRATION',
      'powerCharge': '⚡ CHARGE',
      'purr': '🐱 RONRON',
      'ghostCorePureHint': 'Touchez pour le pouls • Inclinez pour gravité • Étirez pour tension',
      'touchHint': 'Glissez pour ressentir les textures',
      'modeLight': 'CLAIR',
      'modeDark': 'SOMBRE',
      'switchTheme': 'THÈME',
      'soundOffVibeOnly': 'Mode vibration haptique pure',
      'coreStatusSynced': 'SYNCED',
    }),
    AppLanguage.de: const AppStrings({
      'appTitle': 'HAPBOX',
      'tabStudio': 'STUDIO',
      'tabSurge': 'WELLE',
      'tabTouchLab': 'TAST-LABOR',
      'tabGhostCore': 'GEISTERKERN',
      'tabSequencer': 'BEAT',
      'studioStrength': '⚡ STÄRKE',
      'studioLength': '⏱️ DAUER',
      'studioRepeat': '🔁 WIEDERHOLUNG',
      'studioTestHaptics': 'HAPTIK-TEST',
      'play': 'START',
      'stop': 'STOPP',
      'tempo': 'TEMPO',
      'surgeHint': 'Wischen zum Formen der Welle • Vertikal bewegen für stufenlose Stärke',
      'oceanSwell': '🌊 DÜNUNG',
      'throttle': '🏎️ GASGEBEN',
      'powerCharge': '⚡ LADUNG',
      'purr': '🐱 SCHNURREN',
      'ghostCorePureHint': 'Berühren für Herzschlag • Neigen für Schwerkraft • Ziehen für Spannung',
      'touchHint': 'Wischen für Texturen',
      'modeLight': 'HELL',
      'modeDark': 'DUNKEL',
      'switchTheme': 'DESIGN',
      'soundOffVibeOnly': 'Reiner Haptik-Vibrationsmodus',
      'coreStatusSynced': 'SYNCED',
    }),
    AppLanguage.ko: const AppStrings({
      'appTitle': 'HAPBOX',
      'tabStudio': '스튜디오',
      'tabSurge': '파동 (SURGE)',
      'tabTouchLab': '터치 랩',
      'tabGhostCore': '고스트 코어',
      'tabSequencer': '비트',
      'studioStrength': '⚡ 진동 세기',
      'studioLength': '⏱️ 진동 길이',
      'studioRepeat': '🔁 반복 설정',
      'studioTestHaptics': '햅틱 테스트',
      'play': '재생',
      'stop': '정지',
      'tempo': '템포',
      'surgeHint': '쓸어넘겨 파동을 조작 • 상하로 움직여 강도를 부드럽게 조절',
      'oceanSwell': '🌊 파도',
      'throttle': '🏎️ 가속',
      'powerCharge': '⚡ 충전',
      'purr': '🐱 골골송',
      'ghostCorePureHint': '만져서 느끼는 심박 • 기울여 느끼는 중력 • 당겨서 튕기는 탄성',
      'touchHint': '문질러서 질감 체감',
      'modeLight': '라이트',
      'modeDark': '다크',
      'switchTheme': '테마 전환',
      'soundOffVibeOnly': '순수 햅틱 진動 모드',
      'coreStatusSynced': 'SYNCED',
    }),
    AppLanguage.pt: const AppStrings({
      'appTitle': 'HAPBOX',
      'tabStudio': 'ESTÚDIO',
      'tabSurge': 'ONDA',
      'tabTouchLab': 'LAB TÁTIL',
      'tabGhostCore': 'NÚCLEO VIVO',
      'tabSequencer': 'RITMO',
      'studioStrength': '⚡ INTENSIDADE',
      'studioLength': '⏱️ DURAÇÃO',
      'studioRepeat': '🔁 REPETIÇÃO',
      'studioTestHaptics': 'TESTAR HÁPTICO',
      'play': 'TOCAR',
      'stop': 'PARAR',
      'tempo': 'TEMPO',
      'surgeHint': 'Deslize para moldar a onda • Mova verticalmente para modular a intensidade',
      'oceanSwell': '🌊 VAGA',
      'throttle': '🏎️ ACELERAÇÃO',
      'powerCharge': '⚡ CARGA',
      'purr': '🐱 RONRONAR',
      'ghostCorePureHint': 'Toque para pulso • Incline para gravidade • Puxe para tensão',
      'touchHint': 'Deslize para sentir texturas',
      'modeLight': 'CLARO',
      'modeDark': 'ESCURO',
      'switchTheme': 'TEMA',
      'soundOffVibeOnly': 'Modo de Vibração Pura',
      'coreStatusSynced': 'SYNCED',
    }),
  };
}
