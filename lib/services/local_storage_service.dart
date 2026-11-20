import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/stats_models.dart';
import '../models/task_models.dart';
import '../models/timer_models.dart';

/// Thin `shared_preferences` wrapper for the app's local-only data.
///
/// Every read is defensive: corrupt or missing entries return safe defaults
/// (`null` or `const []`) instead of throwing, so a bad blob can never break
/// startup.
class LocalStorageService {
  static const String settingsKey = 'pomodoro_settings_v1';
  static const String tasksKey = 'pomodoro_tasks_v1';
  static const String statsKey = 'pomodoro_stats_v1';

  Future<TimerSettings?> loadSettings() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(settingsKey);
      if (raw == null) {
        return null;
      }
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return TimerSettings.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSettings(TimerSettings settings) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(settingsKey, jsonEncode(settings.toJson()));
  }

  Future<List<PomodoroTask>> loadTasks() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(tasksKey);
      if (raw == null) {
        return const <PomodoroTask>[];
      }
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <PomodoroTask>[];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PomodoroTask.fromJson)
          .toList();
    } catch (_) {
      return const <PomodoroTask>[];
    }
  }

  Future<void> saveTasks(List<PomodoroTask> tasks) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      tasksKey,
      jsonEncode(tasks.map((PomodoroTask task) => task.toJson()).toList()),
    );
  }

  Future<List<PomodoroSessionRecord>> loadStats() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(statsKey);
      if (raw == null) {
        return const <PomodoroSessionRecord>[];
      }
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <PomodoroSessionRecord>[];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PomodoroSessionRecord.fromJson)
          .toList();
    } catch (_) {
      return const <PomodoroSessionRecord>[];
    }
  }

  Future<void> saveStats(List<PomodoroSessionRecord> records) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      statsKey,
      jsonEncode(
        records
            .map((PomodoroSessionRecord record) => record.toJson())
            .toList(),
      ),
    );
  }
}
