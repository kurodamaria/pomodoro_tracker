import 'package:flutter/material.dart';

import 'models/timer_models.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'services/local_storage_service.dart';
import 'services/sound_service.dart';
import 'state/settings_controller.dart';
import 'state/stats_controller.dart';
import 'state/task_controller.dart';
import 'state/timer_controller.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PomodoroTrackerApp());
}

/// Root application widget owning all local controllers and themes.
class PomodoroTrackerApp extends StatefulWidget {
  const PomodoroTrackerApp({super.key, this.soundService});

  /// Optional injected sound service, primarily for tests that must avoid the
  /// platform audio channel. When null, the app creates and owns its own.
  final SoundService? soundService;

  @override
  State<PomodoroTrackerApp> createState() => _PomodoroTrackerAppState();
}

class _PomodoroTrackerAppState extends State<PomodoroTrackerApp> {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  late final LocalStorageService _storage;
  late final SoundService _soundService;
  late final SettingsController _settingsController;
  late final TimerController _timerController;
  late final TaskController _taskController;
  late final StatsController _statsController;

  bool _ownsSoundService = false;

  @override
  void initState() {
    super.initState();
    _storage = LocalStorageService();
    _soundService = widget.soundService ?? SoundService();
    _ownsSoundService = widget.soundService == null;
    _settingsController = SettingsController(storage: _storage);
    _timerController = TimerController(settings: _settingsController.settings);
    _taskController = TaskController(storage: _storage);
    _statsController = StatsController(storage: _storage);
    _taskController.syncSettings(_settingsController.settings);
    _timerController.onPhaseCompleted = _handlePhaseCompleted;
    _timerController.onOneMinuteLeft = _handleOneMinuteLeft;
    _timerController.onTickSecond = _handleTickSecond;
    _taskController.addListener(_syncActiveTaskTitle);
    _settingsController.addListener(_syncSettings);
    _syncActiveTaskTitle();
    _hydrateAll();
  }

  Future<void> _hydrateAll() async {
    await _settingsController.hydrate();
    await _taskController.hydrate();
    await _statsController.hydrate();
    if (!mounted) {
      return;
    }
    _timerController.updateSettings(_settingsController.settings);
    _taskController.syncSettings(_settingsController.settings);
    _timerController.setActiveTaskTitle(_taskController.activeTask?.title);
  }

  @override
  void dispose() {
    _settingsController.removeListener(_syncSettings);
    _taskController.removeListener(_syncActiveTaskTitle);
    if (_ownsSoundService) {
      _soundService.dispose();
    }
    _statsController.dispose();
    _settingsController.dispose();
    _taskController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  void _handlePhaseCompleted(TimerPhase phase, int durationMinutes) {
    final activeTask = _taskController.activeTask;
    _statsController.recordSession(
      phase: phase,
      durationMinutes: durationMinutes,
      taskId: activeTask?.id,
      taskTitle: activeTask?.title,
      category: activeTask?.category,
    );
    if (phase == TimerPhase.pomodoro) {
      _taskController.recordCompletedPomodoroOnActiveTask();
    }
    if (_settingsController.settings.playAlarmSound) {
      _soundService.playAlarm(_settingsController.settings.volume);
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(_phaseAnnouncement(phase))),
      );
    }
  }

  void _handleOneMinuteLeft() {
    if (_settingsController.settings.notifyOneMinuteLeft) {
      _soundService.playOneMinuteWarning(_settingsController.settings.volume);
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('1 minute remaining')),
      );
    }
  }

  void _handleTickSecond() {
    if (_settingsController.settings.playTickingSound) {
      _soundService.playTick(_settingsController.settings.volume);
    }
  }

  String _phaseAnnouncement(TimerPhase phase) {
    switch (phase) {
      case TimerPhase.pomodoro:
        return 'Pomodoro complete! Time for a break.';
      case TimerPhase.shortBreak:
        return 'Short break complete! Time to focus.';
      case TimerPhase.longBreak:
        return 'Long break complete! Time to focus.';
    }
  }

  void _testNotification() {
    _soundService.playAlarm(_settingsController.settings.volume);
  }

  void _syncActiveTaskTitle() {
    _timerController
        .setActiveTaskTitle(_taskController.activeTask?.title);
  }

  void _syncSettings() {
    _timerController.updateSettings(_settingsController.settings);
    _taskController.syncSettings(_settingsController.settings);
  }

  ThemeMode get _themeMode {
    switch (_settingsController.settings.themePreference) {
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
      case ThemePreference.system:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsController,
      builder: (BuildContext context, Widget? _) {
        return MaterialApp(
          title: 'Pomodoro Tracker',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: _messengerKey,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _themeMode,
          home: AppShell(
            settingsController: _settingsController,
            timerController: _timerController,
            taskController: _taskController,
            statsController: _statsController,
            onTestNotification: _testNotification,
          ),
        );
      },
    );
  }
}

/// Root navigation shell holding the top app bar and the active section.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.settingsController,
    required this.timerController,
    required this.taskController,
    required this.statsController,
    required this.onTestNotification,
  });

  final SettingsController settingsController;
  final TimerController timerController;
  final TaskController taskController;
  final StatsController statsController;
  final VoidCallback onTestNotification;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _selectSection(int index) {
    setState(() => _index = index);
  }

  Widget _buildBody() {
    switch (_index) {
      case 0:
        return HomeScreen(
          controller: widget.timerController,
          taskController: widget.taskController,
          onOpenSettings: () => _selectSection(2),
        );
      case 1:
        return StatsScreen(
          statsController: widget.statsController,
          dailyGoal: widget.settingsController.settings.dailyGoal,
        );
      default:
        return SettingsScreen(
          controller: widget.settingsController,
          onTestNotification: widget.onTestNotification,
        );
    }
  }

  Color _navColor(BuildContext context, int index) => _index == index
      ? AppTheme.brandCrimson
      : Theme.of(context).colorScheme.onSurface;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 480;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Tracker'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: SizedBox(
            height: 1,
            child: ColoredBox(color: AppTheme.brandCrimson),
          ),
        ),
        actions: compact
            ? <Widget>[
                IconButton(
                  onPressed: () => _selectSection(0),
                  tooltip: 'Timer',
                  icon: Icon(
                    Icons.timer_outlined,
                    color: _navColor(context, 0),
                  ),
                ),
                IconButton(
                  onPressed: () => _selectSection(1),
                  tooltip: 'Stats',
                  icon: Icon(
                    Icons.bar_chart,
                    color: _navColor(context, 1),
                  ),
                ),
                IconButton(
                  onPressed: () => _selectSection(2),
                  tooltip: 'Settings',
                  icon: Icon(
                    Icons.settings_outlined,
                    color: _navColor(context, 2),
                  ),
                ),
              ]
            : <Widget>[
                TextButton(
                  onPressed: () => _selectSection(0),
                  child: Text(
                    'Timer',
                    style: TextStyle(color: _navColor(context, 0)),
                  ),
                ),
                TextButton(
                  onPressed: () => _selectSection(1),
                  child: Text(
                    'Stats',
                    style: TextStyle(color: _navColor(context, 1)),
                  ),
                ),
                TextButton(
                  onPressed: () => _selectSection(2),
                  child: Text(
                    'Settings',
                    style: TextStyle(color: _navColor(context, 2)),
                  ),
                ),
              ],
      ),
      body: _buildBody(),
    );
  }
}
