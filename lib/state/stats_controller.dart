import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/stats_models.dart';
import '../models/task_models.dart';
import '../models/timer_models.dart';
import '../services/local_storage_service.dart';

/// Local-only store of completed focus sessions.
///
/// Sessions are persisted on-device only: no login, sync, or remote
/// leaderboard is involved.
class StatsController extends ChangeNotifier {
  StatsController({this._storage});

  final LocalStorageService? _storage;
  final List<PomodoroSessionRecord> _records = <PomodoroSessionRecord>[];
  int _idSeed = 0;
  bool _disposed = false;

  /// Loads persisted sessions, if any, then notifies listeners.
  Future<void> hydrate() async {
    final List<PomodoroSessionRecord> stored =
        await _storage?.loadStats() ?? const <PomodoroSessionRecord>[];
    if (_disposed) {
      return;
    }
    _records
      ..clear()
      ..addAll(stored);
    notifyListeners();
  }

  /// All recorded sessions, newest first.
  List<PomodoroSessionRecord> get recentRecords {
    final List<PomodoroSessionRecord> sorted =
        List<PomodoroSessionRecord>.from(_records)
          ..sort((PomodoroSessionRecord a, PomodoroSessionRecord b) =>
              b.completedAt.compareTo(a.completedAt));
    return List<PomodoroSessionRecord>.unmodifiable(sorted);
  }

  /// Appends a completed session and notifies listeners.
  void recordSession({
    required TimerPhase phase,
    required int durationMinutes,
    String? taskId,
    String? taskTitle,
    TaskCategory? category,
    DateTime? completedAt,
  }) {
    _idSeed += 1;
    _records.add(
      PomodoroSessionRecord(
        id: '${DateTime.now().microsecondsSinceEpoch}-$_idSeed',
        completedAt: completedAt ?? DateTime.now(),
        durationMinutes: durationMinutes,
        phase: phase,
        taskId: taskId,
        taskTitle: taskTitle,
        category: category,
      ),
    );
    _persist();
    notifyListeners();
  }

  /// Count of pomodoro sessions completed on the local [date].
  int pomodorosOnDate(DateTime date) {
    return _records
        .where((PomodoroSessionRecord record) =>
            record.phase == TimerPhase.pomodoro &&
            _isSameDay(record.completedAt, date))
        .length;
  }

  /// Focus minutes from pomodoro sessions completed on the local [date].
  int focusMinutesOnDate(DateTime date) {
    return _records
        .where((PomodoroSessionRecord record) =>
            record.phase == TimerPhase.pomodoro &&
            _isSameDay(record.completedAt, date))
        .fold<int>(0, (int sum, PomodoroSessionRecord r) =>
            sum + r.durationMinutes);
  }

  /// Pomodoro sessions in the last [days] local days (today inclusive).
  int pomodorosInLastDays(int days, {DateTime? now}) {
    final Set<String> keys = _dayKeys(days, now);
    return _records
        .where((PomodoroSessionRecord record) =>
            record.phase == TimerPhase.pomodoro &&
            keys.contains(_dayKey(record.completedAt)))
        .length;
  }

  /// Focus minutes in the last [days] local days (today inclusive).
  int focusMinutesInLastDays(int days, {DateTime? now}) {
    final Set<String> keys = _dayKeys(days, now);
    return _records
        .where((PomodoroSessionRecord record) =>
            record.phase == TimerPhase.pomodoro &&
            keys.contains(_dayKey(record.completedAt)))
        .fold<int>(0, (int sum, PomodoroSessionRecord r) =>
            sum + r.durationMinutes);
  }

  /// A per-day pomodoro count series, oldest first, spanning [days] days.
  List<MapEntry<DateTime, int>> dailyPomodorosSeries(
    int days, {
    DateTime? now,
  }) {
    final DateTime base = now ?? DateTime.now();
    return <MapEntry<DateTime, int>>[
      for (int i = days - 1; i >= 0; i--)
        MapEntry<DateTime, int>(
          DateTime(base.year, base.month, base.day - i),
          pomodorosOnDate(DateTime(base.year, base.month, base.day - i)),
        ),
    ];
  }

  /// Pomodoro counts grouped by [TaskCategory] over the last [days] days.
  Map<TaskCategory, int> categoryBreakdown(int days, {DateTime? now}) {
    final Set<String> keys = _dayKeys(days, now);
    final Map<TaskCategory, int> result = <TaskCategory, int>{};
    for (final PomodoroSessionRecord record in _records) {
      if (record.phase != TimerPhase.pomodoro) {
        continue;
      }
      if (record.category == null) {
        continue;
      }
      if (!keys.contains(_dayKey(record.completedAt))) {
        continue;
      }
      final TaskCategory category = record.category!;
      result[category] = (result[category] ?? 0) + 1;
    }
    return result;
  }

  /// Serialises all records as CSV with quote-escaped task titles.
  String toCsv() {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('id,completed_at,phase,duration_minutes,category,task_title');
    for (final PomodoroSessionRecord record in _records) {
      final String title = record.taskTitle == null
          ? ''
          : '"${record.taskTitle!.replaceAll('"', '""')}"';
      buffer.writeln(
        '${record.id},${record.completedAt.toIso8601String()},'
        '${record.phase.name},${record.durationMinutes},'
        '${record.category?.name ?? ''},$title',
      );
    }
    return buffer.toString();
  }

  /// Removes every recorded session.
  void clearHistory() {
    _records.clear();
    _persist();
    notifyListeners();
  }

  void _persist() {
    unawaited(_storage?.saveStats(_records));
  }

  Set<String> _dayKeys(int days, DateTime? now) {
    final DateTime base = now ?? DateTime.now();
    return <String>{
      for (int i = 0; i < days; i++)
        _dayKey(DateTime(base.year, base.month, base.day - i)),
    };
  }

  String _dayKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
