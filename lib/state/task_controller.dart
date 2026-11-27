import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/task_models.dart';
import '../models/timer_models.dart';
import '../services/local_storage_service.dart';

/// Local-only owner of the user's [PomodoroTask] list.
///
/// Holds no network concerns: tasks are persisted on-device and never synced
/// or shared.
class TaskController extends ChangeNotifier {
  TaskController({this._storage});

  final LocalStorageService? _storage;
  final List<PomodoroTask> _tasks = <PomodoroTask>[];
  TaskCategory? _categoryFilter;
  bool _addNewTasksToTop = true;
  bool _removeCompletedFromTodo = true;
  int _idSeed = 0;
  bool _disposed = false;

  TaskCategory? get categoryFilter => _categoryFilter;

  /// Loads persisted tasks, if any, then notifies listeners.
  Future<void> hydrate() async {
    final List<PomodoroTask> stored =
        await _storage?.loadTasks() ?? const <PomodoroTask>[];
    if (_disposed) {
      return;
    }
    _tasks
      ..clear()
      ..addAll(stored);
    notifyListeners();
  }

  String _nextId() {
    _idSeed += 1;
    return '${DateTime.now().microsecondsSinceEpoch}-$_idSeed';
  }

  /// The tasks shown in the TODO section for today.
  List<PomodoroTask> get todayTasks {
    return _tasks.where((PomodoroTask task) {
      if (task.bucket != TaskBucket.today) {
        return false;
      }
      if (_removeCompletedFromTodo && task.isCompleted) {
        return false;
      }
      if (_categoryFilter != null && task.category != _categoryFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Uncompleted tasks in [bucket], in insertion order.
  List<PomodoroTask> tasksForBucket(TaskBucket bucket) {
    return _tasks
        .where((PomodoroTask task) => task.bucket == bucket && !task.isCompleted)
        .toList();
  }

  /// The first uncompleted today task, ignoring the category filter.
  PomodoroTask? get activeTask {
    for (final PomodoroTask task in _tasks) {
      if (task.bucket == TaskBucket.today && !task.isCompleted) {
        return task;
      }
    }
    return null;
  }

  /// Number of active today tasks in [category].
  int countForCategory(TaskCategory category) {
    return _tasks
        .where((PomodoroTask task) =>
            task.bucket == TaskBucket.today &&
            !task.isCompleted &&
            task.category == category)
        .length;
  }

  /// Estimated remaining focus minutes across uncompleted today tasks.
  int remainingMinutesToday(int pomodoroMinutes) {
    int total = 0;
    for (final PomodoroTask task in _tasks) {
      if (task.bucket != TaskBucket.today || task.isCompleted) {
        continue;
      }
      final int remaining =
          (task.estimatedPomodoros - task.completedPomodoros).clamp(0, 999).toInt();
      total += remaining * pomodoroMinutes;
    }
    return total;
  }

  /// Cumulative wall-clock finish time for every uncompleted today task.
  ///
  /// Tasks are walked in queue order (ignoring the active category filter so
  /// a filtered view still reflects everything ahead of it), accumulating the
  /// same per-pomodoro basis used by [remainingMinutesToday]. The last entry
  /// therefore matches the section's overall `FINISH TIME`.
  Map<String, DateTime> estimatedFinishTimesToday({
    required int pomodoroMinutes,
    DateTime? now,
  }) {
    final DateTime base = now ?? DateTime.now();
    final Map<String, DateTime> result = <String, DateTime>{};
    int accumulated = 0;
    for (final PomodoroTask task in _tasks) {
      if (task.bucket != TaskBucket.today || task.isCompleted) {
        continue;
      }
      final int remaining =
          (task.estimatedPomodoros - task.completedPomodoros).clamp(0, 999).toInt();
      accumulated += remaining * pomodoroMinutes;
      result[task.id] = base.add(Duration(minutes: accumulated));
    }
    return result;
  }

  void addTask({
    required String title,
    TaskBucket bucket = TaskBucket.today,
    TaskCategory category = TaskCategory.personal,
    int estimatedPomodoros = 1,
  }) {
    final String trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final PomodoroTask task = PomodoroTask(
      id: _nextId(),
      title: trimmed,
      bucket: bucket,
      category: category,
      estimatedPomodoros: estimatedPomodoros < 1 ? 1 : estimatedPomodoros,
      createdAt: DateTime.now(),
    );

    if (_addNewTasksToTop) {
      _tasks.insert(0, task);
    } else {
      _tasks.add(task);
    }
    _persist();
    notifyListeners();
  }

  void incrementEstimate(String id) {
    final int index = _indexOf(id);
    if (index == -1) {
      return;
    }
    final PomodoroTask task = _tasks[index];
    _tasks[index] = task.copyWith(
      estimatedPomodoros: task.estimatedPomodoros + 1,
    );
    _persist();
    notifyListeners();
  }

  void decrementEstimate(String id) {
    final int index = _indexOf(id);
    if (index == -1) {
      return;
    }
    final PomodoroTask task = _tasks[index];
    if (task.estimatedPomodoros <= 1) {
      return;
    }
    _tasks[index] = task.copyWith(
      estimatedPomodoros: task.estimatedPomodoros - 1,
    );
    _persist();
    notifyListeners();
  }

  /// Applies one completed pomodoro to the current [activeTask].
  void recordCompletedPomodoroOnActiveTask() {
    final PomodoroTask? active = activeTask;
    if (active == null) {
      return;
    }
    final int index = _indexOf(active.id);
    if (index == -1) {
      return;
    }
    final PomodoroTask task = _tasks[index];
    final int completed = task.completedPomodoros + 1;
    _tasks[index] = task.copyWith(
      completedPomodoros: completed,
      isCompleted: completed >= task.estimatedPomodoros,
    );
    _persist();
    notifyListeners();
  }

  void toggleComplete(String id) {
    final int index = _indexOf(id);
    if (index == -1) {
      return;
    }
    final PomodoroTask task = _tasks[index];
    _tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
    _persist();
    notifyListeners();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((PomodoroTask task) => task.id == id);
    _persist();
    notifyListeners();
  }

  void moveTaskToBucket(String id, TaskBucket targetBucket) {
    final int index = _indexOf(id);
    if (index == -1) {
      return;
    }
    _tasks[index] = _tasks[index].copyWith(bucket: targetBucket);
    _persist();
    notifyListeners();
  }

  void updateTask(
    String id, {
    required String title,
    required TaskCategory category,
  }) {
    final String trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final int index = _indexOf(id);
    if (index == -1) {
      return;
    }
    _tasks[index] = _tasks[index].copyWith(
      title: trimmed,
      category: category,
    );
    _persist();
    notifyListeners();
  }

  /// Splits a task into two roughly equal halves, keeping bucket/category.
  void splitTask(String id) {
    final int index = _indexOf(id);
    if (index == -1) {
      return;
    }
    final PomodoroTask task = _tasks[index];
    final int total = task.estimatedPomodoros;
    if (total <= 1) {
      return;
    }

    final int first = (total + 1) ~/ 2;
    final int second = total ~/ 2;

    _tasks[index] = task.copyWith(
      estimatedPomodoros: first,
      completedPomodoros: task.completedPomodoros.clamp(0, first),
    );

    final PomodoroTask sibling = PomodoroTask(
      id: _nextId(),
      title: task.title,
      bucket: task.bucket,
      category: task.category,
      estimatedPomodoros: second,
      createdAt: DateTime.now(),
    );
    _tasks.insert(index + 1, sibling);
    _persist();
    notifyListeners();
  }

  /// Reorders the visible today tasks, mapping back to the backing list.
  void reorderTodayTask(int oldIndex, int newIndex) {
    final List<PomodoroTask> visible = todayTasks;
    if (oldIndex < 0 || oldIndex >= visible.length) {
      return;
    }
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (newIndex < 0 || newIndex >= visible.length) {
      return;
    }

    final PomodoroTask moved = visible[oldIndex];
    _tasks.removeWhere((PomodoroTask task) => task.id == moved.id);

    if (newIndex >= visible.length) {
      _tasks.add(moved);
    } else {
      final PomodoroTask anchor = visible[newIndex];
      final int anchorIndex = _tasks.indexOf(anchor);
      _tasks.insert(anchorIndex == -1 ? _tasks.length : anchorIndex, moved);
    }
    _persist();
    notifyListeners();
  }

  void setCategoryFilter(TaskCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  /// Applies persisted [TimerSettings] that affect task behaviour.
  void syncSettings(TimerSettings settings) {
    _addNewTasksToTop = settings.addNewTasksToTop;
    _removeCompletedFromTodo = settings.removeCompletedFromTodo;
    notifyListeners();
  }

  void _persist() {
    unawaited(_storage?.saveTasks(_tasks));
  }

  int _indexOf(String id) {
    return _tasks.indexWhere((PomodoroTask task) => task.id == id);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
