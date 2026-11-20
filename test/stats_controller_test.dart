import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_tracker/models/task_models.dart';
import 'package:pomodoro_tracker/models/timer_models.dart';
import 'package:pomodoro_tracker/state/stats_controller.dart';

void main() {
  group('StatsController', () {
    test('recordSession appends records newest-first', () {
      final controller = StatsController();
      final DateTime base = DateTime(2026, 1, 1, 9);

      controller.recordSession(
        phase: TimerPhase.pomodoro,
        durationMinutes: 25,
        completedAt: base,
      );
      controller.recordSession(
        phase: TimerPhase.shortBreak,
        durationMinutes: 5,
        completedAt: base.add(const Duration(hours: 1)),
      );

      expect(controller.recentRecords.length, 2);
      expect(controller.recentRecords.first.phase, TimerPhase.shortBreak);
      expect(controller.recentRecords.last.phase, TimerPhase.pomodoro);
    });

    test('pomodorosOnDate counts only pomodoros on the local day', () {
      final controller = StatsController();
      controller.recordSession(
        phase: TimerPhase.pomodoro,
        durationMinutes: 25,
        completedAt: DateTime(2026, 3, 10, 8),
      );
      controller.recordSession(
        phase: TimerPhase.pomodoro,
        durationMinutes: 25,
        completedAt: DateTime(2026, 3, 10, 18),
      );
      controller.recordSession(
        phase: TimerPhase.shortBreak,
        durationMinutes: 5,
        completedAt: DateTime(2026, 3, 10, 9),
      );
      controller.recordSession(
        phase: TimerPhase.pomodoro,
        durationMinutes: 25,
        completedAt: DateTime(2026, 3, 11, 8),
      );

      expect(controller.pomodorosOnDate(DateTime(2026, 3, 10)), 2);
      expect(controller.focusMinutesOnDate(DateTime(2026, 3, 10)), 50);
    });

    test('dailyPomodorosSeries returns days entries oldest-first', () {
      final controller = StatsController();
      final DateTime now = DateTime(2026, 3, 10, 12);

      controller.recordSession(
        phase: TimerPhase.pomodoro,
        durationMinutes: 25,
        completedAt: DateTime(2026, 3, 10, 8),
      );
      controller.recordSession(
        phase: TimerPhase.pomodoro,
        durationMinutes: 25,
        completedAt: DateTime(2026, 3, 10, 9),
      );
      controller.recordSession(
        phase: TimerPhase.pomodoro,
        durationMinutes: 25,
        completedAt: DateTime(2026, 3, 8, 9),
      );

      final List<MapEntry<DateTime, int>> series =
          controller.dailyPomodorosSeries(7, now: now);

      expect(series.length, 7);
      expect(series.first.key, DateTime(2026, 3, 4));
      expect(series.last.key, DateTime(2026, 3, 10));
      expect(series.last.value, 2);
      expect(series[4].value, 1);
    });

    test('toCsv escapes double quotes in task titles', () {
      final controller = StatsController();
      controller.recordSession(
        phase: TimerPhase.pomodoro,
        durationMinutes: 25,
        taskTitle: 'Say "hi"',
        category: TaskCategory.work,
        completedAt: DateTime(2026, 3, 10, 8),
      );

      final String csv = controller.toCsv();
      final List<String> lines = csv.trim().split('\n');

      expect(
        lines.first,
        'id,completed_at,phase,duration_minutes,category,task_title',
      );
      expect(lines.length, 2);
      expect(lines[1], endsWith(',work,"Say ""hi"""'));
    });

    test('clearHistory removes every record', () {
      final controller = StatsController();
      controller.recordSession(
        phase: TimerPhase.pomodoro,
        durationMinutes: 25,
      );
      controller.clearHistory();
      expect(controller.recentRecords, isEmpty);
    });
  });
}
