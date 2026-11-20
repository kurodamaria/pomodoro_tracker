/// Domain models describing the local-only interval timer.
///
/// All classes in this file are immutable and free of any network or
/// authentication concerns.
library;

/// The three phases of a pomodoro interval cycle.
enum TimerPhase { pomodoro, shortBreak, longBreak }

/// The current run state of the interval timer.
enum TimerRunState { idle, running, paused }

/// User preference for the app-wide color theme.
enum ThemePreference { light, dark, system }

/// Safely resolves a [ThemePreference] from its serialized [name].
ThemePreference _themePreferenceFromName(String? name) {
  for (final ThemePreference value in ThemePreference.values) {
    if (value.name == name) {
      return value;
    }
  }
  return ThemePreference.system;
}

/// What the desktop window does when the user asks to close it.
enum CloseBehavior { ask, minimizeToTray, quit }

/// Safely resolves a [CloseBehavior] from its serialized [name].
CloseBehavior _closeBehaviorFromName(String? name) {
  for (final CloseBehavior value in CloseBehavior.values) {
    if (value.name == name) {
      return value;
    }
  }
  return CloseBehavior.ask;
}

/// A named, immutable timer configuration preset.
class TimerScheme {
  const TimerScheme({
    required this.id,
    required this.name,
    required this.pomodoroMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.longBreakDelay,
  });

  final String id;
  final String name;
  final int pomodoroMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  /// Number of pomodoros completed before a long break is offered.
  final int longBreakDelay;

  /// The built-in schemes available without any remote configuration.
  static const List<TimerScheme> presets = <TimerScheme>[
    TimerScheme(
      id: 'classic',
      name: 'Classic',
      pomodoroMinutes: 25,
      shortBreakMinutes: 5,
      longBreakMinutes: 15,
      longBreakDelay: 4,
    ),
    TimerScheme(
      id: 'personal',
      name: 'Personal',
      pomodoroMinutes: 30,
      shortBreakMinutes: 2,
      longBreakMinutes: 25,
      longBreakDelay: 4,
    ),
    TimerScheme(
      id: 'work',
      name: 'Work',
      pomodoroMinutes: 50,
      shortBreakMinutes: 10,
      longBreakMinutes: 20,
      longBreakDelay: 2,
    ),
  ];

  TimerScheme copyWith({
    String? id,
    String? name,
    int? pomodoroMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? longBreakDelay,
  }) {
    return TimerScheme(
      id: id ?? this.id,
      name: name ?? this.name,
      pomodoroMinutes: pomodoroMinutes ?? this.pomodoroMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      longBreakDelay: longBreakDelay ?? this.longBreakDelay,
    );
  }
}

/// Immutable, local-only timer and app preferences.
class TimerSettings {
  const TimerSettings({
    this.pomodoroMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.longBreakDelay = 4,
    this.dailyGoal = 8,
    this.autoStartPomodoros = false,
    this.autoStartBreaks = true,
    this.volume = 0.4,
    this.playAlarmSound = true,
    this.playTickingSound = false,
    this.notifyOneMinuteLeft = false,
    this.clearDoneDaily = true,
    this.addNewTasksToTop = true,
    this.removeCompletedFromTodo = true,
    this.themePreference = ThemePreference.system,
    this.miniModeAlwaysOnTop = true,
    this.closeBehavior = CloseBehavior.ask,
  });

  final int pomodoroMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int longBreakDelay;
  final int dailyGoal;
  final bool autoStartPomodoros;
  final bool autoStartBreaks;

  /// Alarm volume, always normalised to the `0.0 .. 1.0` range.
  final double volume;

  final bool playAlarmSound;
  final bool playTickingSound;
  final bool notifyOneMinuteLeft;
  final bool clearDoneDaily;
  final bool addNewTasksToTop;
  final bool removeCompletedFromTodo;
  final ThemePreference themePreference;

  /// Whether Mini Mode keeps the window above all others.
  final bool miniModeAlwaysOnTop;

  /// Desktop behavior when the window is closed.
  final CloseBehavior closeBehavior;

  TimerSettings copyWith({
    int? pomodoroMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? longBreakDelay,
    int? dailyGoal,
    bool? autoStartPomodoros,
    bool? autoStartBreaks,
    double? volume,
    bool? playAlarmSound,
    bool? playTickingSound,
    bool? notifyOneMinuteLeft,
    bool? clearDoneDaily,
    bool? addNewTasksToTop,
    bool? removeCompletedFromTodo,
    ThemePreference? themePreference,
    bool? miniModeAlwaysOnTop,
    CloseBehavior? closeBehavior,
  }) {
    return TimerSettings(
      pomodoroMinutes: pomodoroMinutes ?? this.pomodoroMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      longBreakDelay: longBreakDelay ?? this.longBreakDelay,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      autoStartPomodoros: autoStartPomodoros ?? this.autoStartPomodoros,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      volume: (volume ?? this.volume).clamp(0.0, 1.0).toDouble(),
      playAlarmSound: playAlarmSound ?? this.playAlarmSound,
      playTickingSound: playTickingSound ?? this.playTickingSound,
      notifyOneMinuteLeft: notifyOneMinuteLeft ?? this.notifyOneMinuteLeft,
      clearDoneDaily: clearDoneDaily ?? this.clearDoneDaily,
      addNewTasksToTop: addNewTasksToTop ?? this.addNewTasksToTop,
      removeCompletedFromTodo:
          removeCompletedFromTodo ?? this.removeCompletedFromTodo,
      themePreference: themePreference ?? this.themePreference,
      miniModeAlwaysOnTop: miniModeAlwaysOnTop ?? this.miniModeAlwaysOnTop,
      closeBehavior: closeBehavior ?? this.closeBehavior,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'pomodoroMinutes': pomodoroMinutes,
        'shortBreakMinutes': shortBreakMinutes,
        'longBreakMinutes': longBreakMinutes,
        'longBreakDelay': longBreakDelay,
        'dailyGoal': dailyGoal,
        'autoStartPomodoros': autoStartPomodoros,
        'autoStartBreaks': autoStartBreaks,
        'volume': volume,
        'playAlarmSound': playAlarmSound,
        'playTickingSound': playTickingSound,
        'notifyOneMinuteLeft': notifyOneMinuteLeft,
        'clearDoneDaily': clearDoneDaily,
        'addNewTasksToTop': addNewTasksToTop,
        'removeCompletedFromTodo': removeCompletedFromTodo,
        'themePreference': themePreference.name,
        'miniModeAlwaysOnTop': miniModeAlwaysOnTop,
        'closeBehavior': closeBehavior.name,
      };

  factory TimerSettings.fromJson(Map<String, dynamic> json) {
    return TimerSettings(
      pomodoroMinutes: (json['pomodoroMinutes'] as num?)?.toInt() ?? 25,
      shortBreakMinutes: (json['shortBreakMinutes'] as num?)?.toInt() ?? 5,
      longBreakMinutes: (json['longBreakMinutes'] as num?)?.toInt() ?? 15,
      longBreakDelay: (json['longBreakDelay'] as num?)?.toInt() ?? 4,
      dailyGoal: (json['dailyGoal'] as num?)?.toInt() ?? 8,
      autoStartPomodoros: json['autoStartPomodoros'] as bool? ?? false,
      autoStartBreaks: json['autoStartBreaks'] as bool? ?? true,
      volume: ((json['volume'] as num?)?.toDouble() ?? 0.4)
          .clamp(0.0, 1.0)
          .toDouble(),
      playAlarmSound: json['playAlarmSound'] as bool? ?? true,
      playTickingSound: json['playTickingSound'] as bool? ?? false,
      notifyOneMinuteLeft: json['notifyOneMinuteLeft'] as bool? ?? false,
      clearDoneDaily: json['clearDoneDaily'] as bool? ?? true,
      addNewTasksToTop: json['addNewTasksToTop'] as bool? ?? true,
      removeCompletedFromTodo:
          json['removeCompletedFromTodo'] as bool? ?? true,
      themePreference:
          _themePreferenceFromName(json['themePreference'] as String?),
      miniModeAlwaysOnTop: json['miniModeAlwaysOnTop'] as bool? ?? true,
      closeBehavior:
          _closeBehaviorFromName(json['closeBehavior'] as String?),
    );
  }
}
