import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/timer_models.dart';
import '../services/local_storage_service.dart';

/// Owns the local, persisted application preferences.
///
/// Keeps no network or account state: every change stays on-device and is
/// mirrored into the timer and task controllers via the app shell.
class SettingsController extends ChangeNotifier {
  SettingsController({this._storage});

  final LocalStorageService? _storage;
  TimerSettings _settings = const TimerSettings();
  String? _activeSchemeId = 'classic';
  bool _disposed = false;

  TimerSettings get settings => _settings;
  String? get activeSchemeId => _activeSchemeId;

  /// Loads persisted settings, if any, then notifies listeners.
  Future<void> hydrate() async {
    final TimerSettings? stored = await _storage?.loadSettings();
    if (_disposed) {
      return;
    }
    if (stored != null) {
      _settings = stored;
      _activeSchemeId = _matchingSchemeId(stored);
    }
    notifyListeners();
  }

  /// Applies a built-in [TimerScheme], preserving all other preferences.
  void applyScheme(TimerScheme scheme) {
    _settings = _settings.copyWith(
      pomodoroMinutes: scheme.pomodoroMinutes,
      shortBreakMinutes: scheme.shortBreakMinutes,
      longBreakMinutes: scheme.longBreakMinutes,
      longBreakDelay: scheme.longBreakDelay,
    );
    _activeSchemeId = scheme.id;
    _persist();
    notifyListeners();
  }

  /// Updates individual durations, clamping each to a safe range.
  ///
  /// Any manual change detaches the settings from the active scheme.
  void updateDurations({
    int? pomodoroMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? longBreakDelay,
    int? dailyGoal,
  }) {
    _settings = _settings.copyWith(
      pomodoroMinutes: pomodoroMinutes?.clamp(1, 180).toInt(),
      shortBreakMinutes: shortBreakMinutes?.clamp(1, 60).toInt(),
      longBreakMinutes: longBreakMinutes?.clamp(1, 120).toInt(),
      longBreakDelay: longBreakDelay?.clamp(1, 12).toInt(),
      dailyGoal: dailyGoal?.clamp(1, 40).toInt(),
    );
    _activeSchemeId = null;
    _persist();
    notifyListeners();
  }

  /// Replaces the whole settings object wholesale.
  void updateSettings(TimerSettings next) {
    _settings = next;
    _persist();
    notifyListeners();
  }

  void updateThemePreference(ThemePreference preference) {
    _settings = _settings.copyWith(themePreference: preference);
    _persist();
    notifyListeners();
  }

  /// Restores the factory defaults and re-selects the classic scheme.
  void resetToDefaults() {
    _settings = const TimerSettings();
    _activeSchemeId = 'classic';
    _persist();
    notifyListeners();
  }

  void _persist() {
    unawaited(_storage?.saveSettings(_settings));
  }

  String? _matchingSchemeId(TimerSettings settings) {
    for (final TimerScheme scheme in TimerScheme.presets) {
      if (scheme.pomodoroMinutes == settings.pomodoroMinutes &&
          scheme.shortBreakMinutes == settings.shortBreakMinutes &&
          scheme.longBreakMinutes == settings.longBreakMinutes &&
          scheme.longBreakDelay == settings.longBreakDelay) {
        return scheme.id;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
