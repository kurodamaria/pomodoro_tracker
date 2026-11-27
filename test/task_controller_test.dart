import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_tracker/models/task_models.dart';
import 'package:pomodoro_tracker/state/task_controller.dart';

void main() {
  group('TaskController', () {
    test('addTask trims, ignores blanks, and inserts newest first', () {
      final controller = TaskController();

      controller.addTask(title: '  First  ');
      controller.addTask(title: '   ');
      controller.addTask(title: 'Second', category: TaskCategory.work);

      final List<PomodoroTask> tasks = controller.todayTasks;
      expect(tasks.length, 2);
      expect(tasks.first.title, 'Second');
      expect(tasks.last.title, 'First');
      expect(tasks.last.category, TaskCategory.personal);
    });

    test('incrementEstimate and decrementEstimate clamp at one', () {
      final controller = TaskController();
      controller.addTask(title: 'Task', estimatedPomodoros: 2);
      final String id = controller.todayTasks.single.id;

      controller.incrementEstimate(id);
      expect(controller.todayTasks.single.estimatedPomodoros, 3);

      controller.decrementEstimate(id);
      controller.decrementEstimate(id);
      controller.decrementEstimate(id);
      expect(controller.todayTasks.single.estimatedPomodoros, 1);
    });

    test('splitTask divides a multi-pomodoro task in two', () {
      final controller = TaskController();
      controller.addTask(title: 'Big', estimatedPomodoros: 5);
      final String id = controller.todayTasks.single.id;

      controller.splitTask(id);

      final List<PomodoroTask> tasks = controller.todayTasks;
      expect(tasks.length, 2);
      expect(tasks[0].estimatedPomodoros, 3);
      expect(tasks[1].estimatedPomodoros, 2);
      expect(tasks[1].bucket, TaskBucket.today);

      // A single-pomodoro task is left untouched.
      controller.addTask(title: 'Small');
      final String smallId = controller.todayTasks.first.id;
      controller.splitTask(smallId);
      expect(controller.todayTasks.length, 3);
    });

    test('moveTaskToBucket relocates a task', () {
      final controller = TaskController();
      controller.addTask(title: 'Move me');
      final String id = controller.todayTasks.single.id;

      controller.moveTaskToBucket(id, TaskBucket.tomorrow);

      expect(controller.todayTasks, isEmpty);
      expect(controller.tasksForBucket(TaskBucket.tomorrow).single.id, id);
    });

    test('recordCompletedPomodoroOnActiveTask tracks and completes', () {
      final controller = TaskController();
      controller.addTask(title: 'Focus', estimatedPomodoros: 2);

      controller.recordCompletedPomodoroOnActiveTask();
      expect(controller.todayTasks.single.completedPomodoros, 1);
      expect(controller.todayTasks.single.isCompleted, isFalse);

      controller.recordCompletedPomodoroOnActiveTask();
      // The task reached its estimate and is hidden from today by default.
      expect(controller.todayTasks, isEmpty);
      expect(controller.tasksForBucket(TaskBucket.today), isEmpty);
    });

    test('setCategoryFilter narrows todayTasks', () {
      final controller = TaskController();
      controller.addTask(title: 'Personal');
      controller.addTask(title: 'Work', category: TaskCategory.work);

      controller.setCategoryFilter(TaskCategory.work);
      expect(controller.todayTasks.length, 1);
      expect(controller.todayTasks.single.category, TaskCategory.work);
      expect(controller.countForCategory(TaskCategory.personal), 1);

      controller.setCategoryFilter(null);
      expect(controller.todayTasks.length, 2);
    });

    test('estimatedFinishTimesToday accumulates in queue order', () {
      final controller = TaskController();
      final DateTime now = DateTime(2026, 5, 1, 9);

      // Newest goes to the top, so the queue is: Long task, Short task.
      controller.addTask(title: 'Short task', estimatedPomodoros: 3);
      controller.addTask(title: 'Long task', estimatedPomodoros: 4);

      final PomodoroTask longTask = controller.todayTasks[0];
      final PomodoroTask shortTask = controller.todayTasks[1];
      expect(longTask.title, 'Long task');

      final Map<String, DateTime> finishTimes =
          controller.estimatedFinishTimesToday(pomodoroMinutes: 25, now: now);
      expect(finishTimes[longTask.id], now.add(const Duration(minutes: 100)));
      expect(finishTimes[shortTask.id], now.add(const Duration(minutes: 175)));

      controller.toggleComplete(longTask.id);
      final Map<String, DateTime> after = controller
          .estimatedFinishTimesToday(pomodoroMinutes: 25, now: now);
      expect(after.containsKey(longTask.id), isFalse);
      expect(after.length, 1);
      expect(after[shortTask.id], now.add(const Duration(minutes: 75)));
    });
  });
}
