import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_theme.dart';

class ThemeState {
  final ThemeMode mode;
  final AppAccentColor accent;
  final bool reduceMotion;

  const ThemeState({
    this.mode = ThemeMode.system,
    this.accent = AppAccentColor.indigo,
    this.reduceMotion = false,
  });

  ThemeState copyWith({
    ThemeMode? mode,
    AppAccentColor? accent,
    bool? reduceMotion,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      accent: accent ?? this.accent,
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeState>((ref) {
  return ThemeController();
});

class ThemeController extends StateNotifier<ThemeState> {
  static const String _keyThemeMode = 'priora_theme_mode';
  static const String _keyAccentColor = 'priora_accent_color';
  static const String _keyReduceMotion = 'priora_reduce_motion';

  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryFallback = {};

  ThemeController({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(const ThemeState()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final modeStr = await _storage.read(key: _keyThemeMode) ?? _memoryFallback[_keyThemeMode];
      final accentStr = await _storage.read(key: _keyAccentColor) ?? _memoryFallback[_keyAccentColor];
      final reduceMotionStr = await _storage.read(key: _keyReduceMotion) ?? _memoryFallback[_keyReduceMotion];

      ThemeMode mode = ThemeMode.system;
      if (modeStr == 'light') mode = ThemeMode.light;
      if (modeStr == 'dark') mode = ThemeMode.dark;

      final accent = AppAccentColor.fromString(accentStr);
      final reduceMotion = reduceMotionStr == 'true';

      state = state.copyWith(
        mode: mode,
        accent: accent,
        reduceMotion: reduceMotion,
      );
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    _memoryFallback[_keyThemeMode] = mode.name;
    try {
      await _storage.write(key: _keyThemeMode, value: mode.name);
    } catch (_) {}
  }

  Future<void> setAccentColor(AppAccentColor accent) async {
    state = state.copyWith(accent: accent);
    _memoryFallback[_keyAccentColor] = accent.name;
    try {
      await _storage.write(key: _keyAccentColor, value: accent.name);
    } catch (_) {}
  }

  Future<void> setReduceMotion(bool reduceMotion) async {
    state = state.copyWith(reduceMotion: reduceMotion);
    _memoryFallback[_keyReduceMotion] = '$reduceMotion';
    try {
      await _storage.write(key: _keyReduceMotion, value: '$reduceMotion');
    } catch (_) {}
  }
}
