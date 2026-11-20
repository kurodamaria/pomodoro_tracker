import 'task_models.dart';
import 'timer_models.dart';

/// Safely resolves a [TimerPhase] from its serialized [name].
TimerPhase _timerPhaseFromName(String? name) {
  for (final TimerPhase value in TimerPhase.values) {
    if (value.name == name) {
      return value;
    }
  }
  return TimerPhase.pomodoro;
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

/// A single, locally recorded focus interval.
///
/// These records power the local statistics screen and are never uploaded
/// anywhere: there is no login, sync, or remote leaderboard.
class PomodoroSessionRecord {
  const PomodoroSessionRecord({
    required this.id,
    required this.completedAt,
    required this.durationMinutes,
    required this.phase,
    this.taskId,
    this.taskTitle,
    this.category,
  });

  final String id;
  final DateTime completedAt;
  final int durationMinutes;
  final TimerPhase phase;

  /// The task this session was tracked against, if any.
  final String? taskId;
  final String? taskTitle;
  final TaskCategory? category;

  PomodoroSessionRecord copyWith({
    String? id,
    DateTime? completedAt,
    int? durationMinutes,
    TimerPhase? phase,
    String? taskId,
    String? taskTitle,
    TaskCategory? category,
  }) {
    return PomodoroSessionRecord(
      id: id ?? this.id,
      completedAt: completedAt ?? this.completedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      phase: phase ?? this.phase,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'completedAt': completedAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'phase': phase.name,
        'taskId': taskId,
        'taskTitle': taskTitle,
        'category': category?.name,
      };

  factory PomodoroSessionRecord.fromJson(Map<String, dynamic> json) {
    final String? categoryName = json['category'] as String?;
    return PomodoroSessionRecord(
      id: json['id'] as String? ?? '',
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.now(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      phase: _timerPhaseFromName(json['phase'] as String?),
      taskId: json['taskId'] as String?,
      taskTitle: json['taskTitle'] as String?,
      category: categoryName == null
          ? null
          : _taskCategoryFromName(categoryName),
    );
  }
}
