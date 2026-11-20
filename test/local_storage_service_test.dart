import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_tracker/models/stats_models.dart';
import 'package:pomodoro_tracker/models/task_models.dart';
import 'package:pomodoro_tracker/models/timer_models.dart';
import 'package:pomodoro_tracker/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('settings round-trip through storage', () async {
    final LocalStorageService service = LocalStorageService();
    const TimerSettings settings = TimerSettings(
      pomodoroMinutes: 42,
      shortBreakMinutes: 7,
      themePreference: ThemePreference.dark,
      volume: 0.75,
      addNewTasksToTop: false,
    );

    await service.saveSettings(settings);
    final TimerSettings? loaded = await service.loadSettings();

    expect(loaded, isNotNull);
    expect(loaded!.pomodoroMinutes, 42);
    expect(loaded.shortBreakMinutes, 7);
    expect(loaded.themePreference, ThemePreference.dark);
    expect(loaded.volume, 0.75);
    expect(loaded.addNewTasksToTop, isFalse);
  });

  test('task list round-trip through storage', () async {
    final LocalStorageService service = LocalStorageService();
    final List<PomodoroTask> tasks = <PomodoroTask>[
      PomodoroTask(
        id: 'a',
        title: 'Alpha',
        bucket: TaskBucket.inbox,
        category: TaskCategory.work,
        estimatedPomodoros: 3,
        completedPomodoros: 1,
        createdAt: DateTime(2026, 1, 2, 3, 4, 5),
      ),
    ];

    await service.saveTasks(tasks);
    final List<PomodoroTask> loaded = await service.loadTasks();

    expect(loaded.length, 1);
    expect(loaded.single.id, 'a');
    expect(loaded.single.title, 'Alpha');
    expect(loaded.single.bucket, TaskBucket.inbox);
    expect(loaded.single.category, TaskCategory.work);
    expect(loaded.single.estimatedPomodoros, 3);
    expect(loaded.single.completedPomodoros, 1);
  });

  test('stats list round-trip through storage', () async {
    final LocalStorageService service = LocalStorageService();
    final List<PomodoroSessionRecord> records = <PomodoroSessionRecord>[
      PomodoroSessionRecord(
        id: 'r1',
        completedAt: DateTime(2026, 2, 3, 4, 5, 6),
        durationMinutes: 25,
        phase: TimerPhase.pomodoro,
        taskId: 'a',
        taskTitle: 'Alpha',
        category: TaskCategory.work,
      ),
    ];

    await service.saveStats(records);
    final List<PomodoroSessionRecord> loaded = await service.loadStats();

    expect(loaded.length, 1);
    expect(loaded.single.id, 'r1');
    expect(loaded.single.phase, TimerPhase.pomodoro);
    expect(loaded.single.taskTitle, 'Alpha');
    expect(loaded.single.category, TaskCategory.work);
  });

  test('corrupt or missing entries fall back safely', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      LocalStorageService.settingsKey: '{ not valid json',
      LocalStorageService.tasksKey: 'garbage',
      LocalStorageService.statsKey: 'also not json',
    });
    final LocalStorageService service = LocalStorageService();

    expect(await service.loadSettings(), isNull);
    expect(await service.loadTasks(), isEmpty);
    expect(await service.loadStats(), isEmpty);
  });

  test('unknown enum names fall back to defaults', () {
    final TimerSettings settings = TimerSettings.fromJson(
      <String, dynamic>{'themePreference': 'mystery'},
    );
    expect(settings.themePreference, ThemePreference.system);

    final PomodoroTask task = PomodoroTask.fromJson(
      <String, dynamic>{'bucket': 'nowhere', 'category': 'nonsense'},
    );
    expect(task.bucket, TaskBucket.today);
    expect(task.category, TaskCategory.personal);

    final PomodoroSessionRecord record = PomodoroSessionRecord.fromJson(
      <String, dynamic>{'phase': 'unknown'},
    );
    expect(record.phase, TimerPhase.pomodoro);
  });
}
