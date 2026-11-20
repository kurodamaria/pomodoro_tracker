import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/timer_models.dart';

/// Drives the local pomodoro interval timer.
///
/// The controller owns the single `Timer` used for ticking and is fully
/// local-first: it performs no persistence, network, or authentication work.
/// `tick()` is exposed publicly so the countdown can be advanced
/// deterministically in tests without waiting on wall-clock time.
class TimerController extends ChangeNotifier {
  TimerController({TimerSettings settings = const TimerSettings()})
      : _settings = settings,
        _remainingSeconds = settings.pomodoroMinutes * 60;

  TimerSettings _settings;
  TimerPhase _phase = TimerPhase.pomodoro;
  TimerRunState _runState = TimerRunState.idle;
  int _remainingSeconds;
  int _completedInCycle = 0;
  int _completedToday = 0;
  String? _activeTaskTitle;
  Timer? _ticker;

  /// Called when a phase finishes (naturally, early, or via skip).
  void Function(TimerPhase completedPhase, int durationMinutes)?
      onPhaseCompleted;

  /// Called exactly once when the running countdown reaches 60 seconds.
  VoidCallback? onOneMinuteLeft;

  /// Called on every running second that still has time remaining.
  VoidCallback? onTickSecond;

  TimerSettings get settings => _settings;
  TimerPhase get phase => _phase;
  TimerRunState get runState => _runState;
  int get remainingSeconds => _remainingSeconds;
  int get completedInCycle => _completedInCycle;
  int get completedToday => _completedToday;
  String? get activeTaskTitle => _activeTaskTitle;

  /// The countdown as `MM : SS` with two-digit zero padding.
  String get formattedTime {
    final int minutes = _remainingSeconds ~/ 60;
    final int seconds = _remainingSeconds % 60;
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');
    return '$mm : $ss';
  }

  /// The uppercase phase label shown at the top of the timer card.
  String get phaseHeaderLabel {
    switch (_phase) {
      case TimerPhase.pomodoro:
        return 'POMODORO ${_completedToday + 1} (${_completedInCycle + 1})';
      case TimerPhase.shortBreak:
        return 'SHORT BREAK';
      case TimerPhase.longBreak:
        return 'LONG BREAK';
    }
  }

  /// Duration in minutes configured for [phase].
  int durationMinutesFor(TimerPhase phase) {
    switch (phase) {
      case TimerPhase.pomodoro:
        return _settings.pomodoroMinutes;
      case TimerPhase.shortBreak:
        return _settings.shortBreakMinutes;
      case TimerPhase.longBreak:
        return _settings.longBreakMinutes;
    }
  }

  /// Projects the wall-clock time at which the next long break will begin.
  ///
  /// Starts from the current phase's remaining seconds and adds the duration
  /// of every subsequent pomodoro/short break needed to reach
  /// [TimerSettings.longBreakDelay].
  DateTime estimatedNextLongBreak(DateTime now) {
    int seconds = _remainingSeconds;
    TimerPhase simulatedPhase = _phase;
    int simulatedCompleted = _completedInCycle;

    while (true) {
      if (simulatedPhase == TimerPhase.pomodoro) {
        simulatedCompleted += 1;
        if (simulatedCompleted >= _settings.longBreakDelay) {
          break;
        }
        simulatedPhase = TimerPhase.shortBreak;
        seconds += _settings.shortBreakMinutes * 60;
      } else {
        simulatedPhase = TimerPhase.pomodoro;
        seconds += _settings.pomodoroMinutes * 60;
      }
    }

    return now.add(Duration(seconds: seconds));
  }

  void _resetRemainingForCurrentPhase() {
    _remainingSeconds = durationMinutesFor(_phase) * 60;
  }

  /// Starts ticking. No-op when already running.
  void start() {
    if (_runState == TimerRunState.running) {
      return;
    }
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    _runState = TimerRunState.running;
    notifyListeners();
  }

  /// Pauses the countdown. Only valid while running.
  void pause() {
    if (_runState != TimerRunState.running) {
      return;
    }
    _ticker?.cancel();
    _ticker = null;
    _runState = TimerRunState.paused;
    notifyListeners();
  }

  /// Resumes the countdown. Only valid while paused.
  void resume() {
    if (_runState != TimerRunState.paused) {
      return;
    }
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    _runState = TimerRunState.running;
    notifyListeners();
  }

  /// Stops and resets the current phase back to idle.
  void stop() {
    _ticker?.cancel();
    _ticker = null;
    _runState = TimerRunState.idle;
    _resetRemainingForCurrentPhase();
    notifyListeners();
  }

  /// Completes the current phase immediately. Valid while running or paused.
  void doneEarly() {
    if (_runState != TimerRunState.running && _runState != TimerRunState.paused) {
      return;
    }
    _ticker?.cancel();
    _ticker = null;
    _completePhase();
  }

  /// Advances to the next phase without counting a completed pomodoro.
  void skipPhase() {
    _ticker?.cancel();
    _ticker = null;

    if (_phase == TimerPhase.pomodoro) {
      final int nextCompleted = _completedInCycle + 1;
      _phase = nextCompleted >= _settings.longBreakDelay
          ? TimerPhase.longBreak
          : TimerPhase.shortBreak;
    } else {
      _phase = TimerPhase.pomodoro;
    }

    _runState = TimerRunState.idle;
    _resetRemainingForCurrentPhase();
    notifyListeners();
  }

  /// Jumps directly to [target] phase and resets to idle.
  void selectPhase(TimerPhase target) {
    _ticker?.cancel();
    _ticker = null;
    _phase = target;
    _runState = TimerRunState.idle;
    _resetRemainingForCurrentPhase();
    notifyListeners();
  }

  /// Replaces the active settings, resyncing the countdown when idle.
  void updateSettings(TimerSettings next) {
    _settings = next;
    if (_runState == TimerRunState.idle) {
      _resetRemainingForCurrentPhase();
    }
    notifyListeners();
  }

  /// Sets the optional title of the task currently being focused on.
  void setActiveTaskTitle(String? title) {
    _activeTaskTitle = title;
    notifyListeners();
  }

  /// Advances the countdown by one second.
  ///
  /// Public so tests can drive the timer without real time passing.
  void tick() {
    if (_runState != TimerRunState.running) {
      return;
    }

    _remainingSeconds -= 1;
    if (_remainingSeconds <= 0) {
      _ticker?.cancel();
      _ticker = null;
      _completePhase();
    } else {
      onTickSecond?.call();
      if (_remainingSeconds == 60) {
        onOneMinuteLeft?.call();
      }
      notifyListeners();
    }
  }

  void _completePhase() {
    final TimerPhase completedPhase = _phase;
    onPhaseCompleted?.call(completedPhase, durationMinutesFor(completedPhase));

    if (completedPhase == TimerPhase.pomodoro) {
      _completedToday += 1;
      _completedInCycle += 1;
      if (_completedInCycle >= _settings.longBreakDelay) {
        _completedInCycle = 0;
        _phase = TimerPhase.longBreak;
      } else {
        _phase = TimerPhase.shortBreak;
      }

      _remainingSeconds = durationMinutesFor(_phase) * 60;
      _runState = TimerRunState.idle;
      if (_settings.autoStartBreaks) {
        start();
      }
    } else {
      _phase = TimerPhase.pomodoro;
      _remainingSeconds = durationMinutesFor(_phase) * 60;
      _runState = TimerRunState.idle;
      if (_settings.autoStartPomodoros) {
        start();
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }
}
