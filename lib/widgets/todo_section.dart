import 'package:flutter/material.dart';

import '../models/task_models.dart';
import '../state/task_controller.dart';
import '../state/timer_controller.dart';
import '../theme/app_theme.dart';
import 'scheduler_dialog.dart';

/// The TODO list for today, with quick-add, reordering, and filters.
class TodoSection extends StatefulWidget {
  const TodoSection({
    super.key,
    required this.taskController,
    required this.timerController,
  });

  final TaskController taskController;
  final TimerController timerController;

  @override
  State<TodoSection> createState() => _TodoSectionState();
}

class _TodoSectionState extends State<TodoSection> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  TaskCategory _category = TaskCategory.personal;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTask() {
    widget.taskController.addTask(
      title: _textController.text,
      category: _category,
    );
    _textController.clear();
    _focusNode.requestFocus();
  }

  Future<void> _openScheduler() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) =>
          SchedulerDialog(taskController: widget.taskController),
    );
  }

  Future<void> _editTask(PomodoroTask task) async {
    final TextEditingController titleController =
        TextEditingController(text: task.title);
    TaskCategory selectedCategory = task.category;

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit task'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: 'Short description',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<TaskCategory>(
                    value: selectedCategory,
                    isExpanded: true,
                    onChanged: (TaskCategory? value) {
                      if (value != null) {
                        setDialogState(() => selectedCategory = value);
                      }
                    },
                    items: _categoryItems(),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      widget.taskController.updateTask(
        task.id,
        title: titleController.text,
        category: selectedCategory,
      );
    }
    titleController.dispose();
  }

  void _onMenuSelected(String action, PomodoroTask task) {
    switch (action) {
      case 'add':
        widget.taskController.incrementEstimate(task.id);
      case 'remove':
        widget.taskController.decrementEstimate(task.id);
      case 'done':
        widget.taskController.toggleComplete(task.id);
      case 'split':
        widget.taskController.splitTask(task.id);
      case 'edit':
        _editTask(task);
      case 'inbox':
        widget.taskController.moveTaskToBucket(task.id, TaskBucket.inbox);
      case 'tomorrow':
        widget.taskController.moveTaskToBucket(task.id, TaskBucket.tomorrow);
      case 'week':
        widget.taskController.moveTaskToBucket(task.id, TaskBucket.week);
      case 'later':
        widget.taskController.moveTaskToBucket(task.id, TaskBucket.later);
      case 'delete':
        widget.taskController.deleteTask(task.id);
    }
  }

  List<DropdownMenuItem<TaskCategory>> _categoryItems() {
    return const <DropdownMenuItem<TaskCategory>>[
      DropdownMenuItem<TaskCategory>(
        value: TaskCategory.personal,
        child: Text('personal'),
      ),
      DropdownMenuItem<TaskCategory>(
        value: TaskCategory.work,
        child: Text('work'),
      ),
    ];
  }

  String _formatTime(BuildContext context, DateTime time) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(time),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
        <Listenable>[widget.taskController, widget.timerController],
      ),
      builder: (BuildContext context, Widget? _) {
        final List<PomodoroTask> tasks = widget.taskController.todayTasks;
        final int pomodoroMinutes =
            widget.timerController.settings.pomodoroMinutes;
        final DateTime now = DateTime.now();
        final int remainingMinutes =
            widget.taskController.remainingMinutesToday(pomodoroMinutes);
        final Map<String, DateTime> finishTimes =
            widget.taskController.estimatedFinishTimesToday(
          pomodoroMinutes: pomodoroMinutes,
          now: now,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildHeader(context, tasks.length, remainingMinutes),
            const SizedBox(height: 12),
            _buildQuickAdd(context),
            const SizedBox(height: 12),
            if (tasks.isEmpty)
              _buildEmptyState(context)
            else
              _buildList(context, tasks, finishTimes),
            const SizedBox(height: 12),
            _buildFooter(context, remainingMinutes, now),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int count, int minutes) {
    return Row(
      children: <Widget>[
        Text(
          'TODO · $count / ${minutes}m',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Divider(color: AppTheme.brandCrimson, thickness: 1),
        ),
      ],
    );
  }

  DropdownButton<TaskCategory> _categoryDropdown({required bool expanded}) {
    return DropdownButton<TaskCategory>(
      value: _category,
      isExpanded: expanded,
      underline: const SizedBox.shrink(),
      onChanged: (TaskCategory? value) {
        if (value != null) {
          setState(() => _category = value);
        }
      },
      items: _categoryItems(),
    );
  }

  Widget _buildQuickAdd(BuildContext context) {
    final Widget addButton = IconButton(
      onPressed: _addTask,
      tooltip: 'Add task',
      icon: const Icon(Icons.add),
    );
    final Widget schedulerButton = IconButton(
      onPressed: _openScheduler,
      tooltip: 'Open scheduler',
      icon: const Icon(Icons.assignment_outlined),
    );
    final Widget input = TextField(
      controller: _textController,
      focusNode: _focusNode,
      decoration: const InputDecoration(
        hintText: 'Short description',
        isDense: true,
      ),
      onSubmitted: (_) => _addTask(),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth >= 420) {
          return Row(
            children: <Widget>[
              _categoryDropdown(expanded: false),
              const SizedBox(width: 8),
              Expanded(child: input),
              addButton,
              schedulerButton,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            input,
            Row(
              children: <Widget>[
                Expanded(child: _categoryDropdown(expanded: true)),
                addButton,
                schedulerButton,
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'TODO list is empty. Try to add some tasks using the form above.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<PomodoroTask> tasks,
    Map<String, DateTime> finishTimes,
  ) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: tasks.length,
      // ignore: deprecated_member_use
      onReorder: widget.taskController.reorderTodayTask,
      itemBuilder: (BuildContext context, int index) {
        return _buildRow(context, tasks[index], index, finishTimes);
      },
    );
  }

  Widget _buildRow(
    BuildContext context,
    PomodoroTask task,
    int index,
    Map<String, DateTime> finishTimes,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final DateTime? finishTime = finishTimes[task.id];
    return Padding(
      key: ValueKey<String>(task.id),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          ReorderableDragStartListener(
            index: index,
            child: Icon(
              Icons.drag_handle,
              size: 20,
              color: scheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 8),
          _CategoryChip(category: task.category),
          const SizedBox(width: 8),
          Expanded(
            child: Text(task.title, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          if (finishTime != null) ...<Widget>[
            Text(
              _formatTime(context, finishTime),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(width: 8),
          ],
          InkWell(
            onTap: () => widget.taskController.incrementEstimate(task.id),
            borderRadius: BorderRadius.circular(AppTheme.controlRadius),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.brandCrimson.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.controlRadius),
              ),
              child: Text(
                '${task.completedPomodoros}/${task.estimatedPomodoros}',
                style: const TextStyle(
                  color: AppTheme.brandCrimson,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Task actions',
            onSelected: (String value) => _onMenuSelected(value, task),
            itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'add', child: Text('Add more')),
              PopupMenuItem<String>(value: 'remove', child: Text('Remove one')),
              PopupMenuItem<String>(value: 'done', child: Text('Mark as done')),
              PopupMenuItem<String>(value: 'split', child: Text('Split')),
              PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
              PopupMenuItem<String>(value: 'inbox', child: Text('Move to Inbox')),
              PopupMenuItem<String>(
                value: 'tomorrow',
                child: Text('Set to Tomorrow'),
              ),
              PopupMenuItem<String>(value: 'week', child: Text('Set to Week')),
              PopupMenuItem<String>(value: 'later', child: Text('Set to Later')),
              PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, int remainingMinutes, DateTime now) {
    final DateTime finish = now.add(Duration(minutes: remainingMinutes));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'FINISH TIME · ${_formatTime(context, finish)}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: <Widget>[
            ChoiceChip(
              label: const Text('All'),
              selected: widget.taskController.categoryFilter == null,
              onSelected: (_) => widget.taskController.setCategoryFilter(null),
            ),
            for (final TaskCategory category in TaskCategory.values)
              ChoiceChip(
                label: Text(
                  '${category.name} · ${widget.taskController.countForCategory(category)}',
                ),
                selected: widget.taskController.categoryFilter == category,
                onSelected: (_) =>
                    widget.taskController.setCategoryFilter(category),
              ),
          ],
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final TaskCategory category;

  @override
  Widget build(BuildContext context) {
    final Color color = category == TaskCategory.work
        ? AppTheme.longBreakBlue
        : AppTheme.breakTeal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
      ),
      child: Text(
        category.name,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
