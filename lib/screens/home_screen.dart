import 'package:flutter/material.dart';

import '../state/task_controller.dart';
import '../state/timer_controller.dart';
import '../widgets/timer_card.dart';
import '../widgets/todo_section.dart';

/// The main interval timer view.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.taskController,
    required this.onOpenSettings,
    this.onToggleMiniMode,
  });

  final TimerController controller;
  final TaskController taskController;
  final VoidCallback onOpenSettings;
  final VoidCallback? onToggleMiniMode;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TimerCard(
                controller: controller,
                onOpenSettings: onOpenSettings,
                onToggleMiniMode: onToggleMiniMode,
              ),
              const SizedBox(height: 24),
              TodoSection(
                taskController: taskController,
                timerController: controller,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
