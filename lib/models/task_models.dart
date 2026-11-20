/// Local-only task domain models.
library;

/// The scheduling bucket a task lives in.
enum TaskBucket { today, inbox, tomorrow, week, later }

/// A simple category used to group local tasks.
enum TaskCategory { personal, work }

/// Safely resolves a [TaskBucket] from its serialized [name].
TaskBucket _taskBucketFromName(String? name) {
  for (final TaskBucket value in TaskBucket.values) {
    if (value.name == name) {
      return value;
    }
  }
  return TaskBucket.today;
}

/// Safely resolves a [TaskCategory] from its serialized [name].
TaskCategory _taskCategoryFromName(String? name) {
  for (final TaskCategory value in TaskCategory.values) {
    if (value.name == name) {
      return value;
    }
  }
  return TaskCategory.personal;
}

/// An immutable, local TODO item tracked against pomodoro estimates.
class PomodoroTask {
  const PomodoroTask({
    required this.id,
    required this.title,
    required this.bucket,
    required this.category,
    this.estimatedPomodoros = 1,
    this.completedPomodoros = 0,
    this.isCompleted = false,
    required this.createdAt,
  })  : assert(estimatedPomodoros >= 1),
        assert(completedPomodoros >= 0);

  final String id;
  final String title;
  final TaskBucket bucket;
  final TaskCategory category;

  /// Always at least `1`.
  final int estimatedPomodoros;

  /// Always at least `0`.
  final int completedPomodoros;

  final bool isCompleted;
  final DateTime createdAt;

  PomodoroTask copyWith({
    String? id,
    String? title,
    TaskBucket? bucket,
    TaskCategory? category,
    int? estimatedPomodoros,
    int? completedPomodoros,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return PomodoroTask(
      id: id ?? this.id,
      title: title ?? this.title,
      bucket: bucket ?? this.bucket,
      category: category ?? this.category,
      estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'bucket': bucket.name,
        'category': category.name,
        'estimatedPomodoros': estimatedPomodoros,
        'completedPomodoros': completedPomodoros,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PomodoroTask.fromJson(Map<String, dynamic> json) {
    return PomodoroTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      bucket: _taskBucketFromName(json['bucket'] as String?),
      category: _taskCategoryFromName(json['category'] as String?),
      estimatedPomodoros:
          ((json['estimatedPomodoros'] as num?)?.toInt() ?? 1).clamp(1, 1000000),
      completedPomodoros:
          ((json['completedPomodoros'] as num?)?.toInt() ?? 0).clamp(0, 1000000),
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
