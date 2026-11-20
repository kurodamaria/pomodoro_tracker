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
  });
}
