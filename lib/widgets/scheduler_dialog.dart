import 'package:flutter/material.dart';

import '../models/task_models.dart';
import '../state/task_controller.dart';
import '../theme/app_theme.dart';

/// Modal that surfaces the non-today buckets: inbox, tomorrow, week, later.
class SchedulerDialog extends StatefulWidget {
  const SchedulerDialog({super.key, required this.taskController});

  final TaskController taskController;

  @override
  State<SchedulerDialog> createState() => _SchedulerDialogState();
}

class _SchedulerDialogState extends State<SchedulerDialog> {
  static const List<TaskBucket> _buckets = <TaskBucket>[
    TaskBucket.inbox,
    TaskBucket.tomorrow,
    TaskBucket.week,
    TaskBucket.later,
  ];

  static const List<String> _labels = <String>[
    'Inbox',
    'Tomorrow',
    'Week',
    'Later',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: DefaultTabController(
          length: _buckets.length,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TabBar(
                isScrollable: true,
                tabs: <Widget>[
                  for (final String label in _labels) Tab(text: label),
                ],
              ),
              Flexible(
                child: TabBarView(
                  children: <Widget>[
                    for (final TaskBucket bucket in _buckets)
                      _BucketTab(
                        taskController: widget.taskController,
                        bucket: bucket,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('CLOSE'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BucketTab extends StatefulWidget {
  const _BucketTab({required this.taskController, required this.bucket});

  final TaskController taskController;
  final TaskBucket bucket;

  @override
  State<_BucketTab> createState() => _BucketTabState();
}

class _BucketTabState extends State<_BucketTab> {
  final TextEditingController _textController = TextEditingController();
  TaskCategory _category = TaskCategory.personal;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _add() {
    widget.taskController.addTask(
      title: _textController.text,
      bucket: widget.bucket,
      category: _category,
    );
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.taskController,
      builder: (BuildContext context, Widget? _) {
        final List<PomodoroTask> tasks =
            widget.taskController.tasksForBucket(widget.bucket);

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  DropdownButton<TaskCategory>(
                    value: _category,
                    underline: const SizedBox.shrink(),
                    onChanged: (TaskCategory? value) {
                      if (value != null) {
                        setState(() => _category = value);
                      }
                    },
                    items: const <DropdownMenuItem<TaskCategory>>[
                      DropdownMenuItem<TaskCategory>(
                        value: TaskCategory.personal,
                        child: Text('personal'),
                      ),
                      DropdownMenuItem<TaskCategory>(
                        value: TaskCategory.work,
                        child: Text('work'),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Short description',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                  IconButton(
                    onPressed: _add,
                    tooltip: 'Add task',
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: tasks.isEmpty
                    ? const Center(child: Text('The list is empty'))
                    : ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (BuildContext context, int index) {
                          final PomodoroTask task = tasks[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              task.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(task.category.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  tooltip: 'Move to Today',
                                  onPressed: () => widget.taskController
                                      .moveTaskToBucket(
                                          task.id, TaskBucket.today),
                                  icon: const Icon(Icons.today),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => widget.taskController
                                      .deleteTask(task.id),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
