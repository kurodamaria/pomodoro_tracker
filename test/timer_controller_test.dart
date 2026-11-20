import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_tracker/models/timer_models.dart';
import 'package:pomodoro_tracker/state/timer_controller.dart';

void main() {
  group('TimerController', () {
    test('starts idle at 25:00 in the pomodoro phase', () {
      final controller = TimerController();

      expect(controller.phase, TimerPhase.pomodoro);
      expect(controller.runState, TimerRunState.idle);
      expect(controller.formattedTime, '25 : 00');
      expect(controller.completedToday, 0);
      expect(controller.completedInCycle, 0);
      expect(controller.phaseHeaderLabel, 'POMODORO 1 (1)');

      controller.dispose();
    });

    test('start -> pause -> resume -> stop state transitions', () {
      final controller = TimerController();

      controller.start();
      expect(controller.runState, TimerRunState.running);

      controller.pause();
      expect(controller.runState, TimerRunState.paused);

      controller.resume();
      expect(controller.runState, TimerRunState.running);

      controller.stop();
      expect(controller.runState, TimerRunState.idle);
      expect(controller.formattedTime, '25 : 00');

      controller.dispose();
    });

    test('tick() countdown auto-transitions pomodoro -> shortBreak', () {
      final controller = TimerController(
        settings: const TimerSettings(
          pomodoroMinutes: 1,
          shortBreakMinutes: 1,
          autoStartBreaks: false,
        ),
      );

      controller.start();
      for (int i = 0; i < 60; i++) {
        controller.tick();
      }

      expect(controller.phase, TimerPhase.shortBreak);
      expect(controller.runState, TimerRunState.idle);
      expect(controller.completedToday, 1);
      expect(controller.completedInCycle, 1);
      expect(controller.formattedTime, '01 : 00');
      expect(controller.phaseHeaderLabel, 'SHORT BREAK');

      controller.dispose();
    });

    test('reaches longBreak after longBreakDelay pomodoros', () {
      final controller = TimerController(
        settings: const TimerSettings(
          pomodoroMinutes: 1,
          shortBreakMinutes: 1,
          longBreakMinutes: 2,
          longBreakDelay: 2,
          autoStartBreaks: false,
          autoStartPomodoros: false,
        ),
      );

      // First pomodoro -> short break.
      controller.start();
      for (int i = 0; i < 60; i++) {
        controller.tick();
      }
      expect(controller.phase, TimerPhase.shortBreak);
      expect(controller.completedInCycle, 1);

      // Second pomodoro -> long break (delay reached, cycle resets).
      controller.selectPhase(TimerPhase.pomodoro);
      controller.start();
      for (int i = 0; i < 60; i++) {
        controller.tick();
      }

      expect(controller.phase, TimerPhase.longBreak);
      expect(controller.completedToday, 2);
      expect(controller.completedInCycle, 0);
      expect(controller.formattedTime, '02 : 00');

      controller.dispose();
    });

    test('onPhaseCompleted fires with the finished phase and duration', () {
      final controller = TimerController(
        settings: const TimerSettings(
          pomodoroMinutes: 1,
          autoStartBreaks: false,
        ),
      );

      TimerPhase? reportedPhase;
      int? reportedDuration;
      controller.onPhaseCompleted = (phase, durationMinutes) {
        reportedPhase = phase;
        reportedDuration = durationMinutes;
      };

      controller.start();
      for (int i = 0; i < 60; i++) {
        controller.tick();
      }

      expect(reportedPhase, TimerPhase.pomodoro);
      expect(reportedDuration, 1);

      controller.dispose();
    });
  });
}
