import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../state/timer_controller.dart';
import '../theme/app_theme.dart';

/// The compact, full-bleed dock-mode surface.
class MiniTimerView extends StatelessWidget {
  const MiniTimerView({
    super.key,
    required this.controller,
    required this.isPinned,
    required this.onTogglePin,
    required this.onExpand,
  });

  final TimerController controller;
  final bool isPinned;
  final VoidCallback onTogglePin;
  final VoidCallback onExpand;

  Color _phaseColor(TimerPhase phase) {
    switch (phase) {
      case TimerPhase.pomodoro:
        return AppTheme.brandCrimson;
      case TimerPhase.shortBreak:
        return AppTheme.breakTeal;
      case TimerPhase.longBreak:
        return AppTheme.longBreakBlue;
    }
  }

  String _phaseLabel(TimerPhase phase) {
    switch (phase) {
      case TimerPhase.pomodoro:
        return 'POMODORO';
      case TimerPhase.shortBreak:
        return 'SHORT BREAK';
      case TimerPhase.longBreak:
        return 'LONG BREAK';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        final TimerPhase phase = controller.phase;
        final String? taskTitle = controller.activeTaskTitle;
        return Material(
          color: _phaseColor(phase),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: onTogglePin,
                        tooltip: isPinned ? 'Unpin' : 'Pin on top',
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _phaseLabel(phase),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onExpand,
                        tooltip: 'Expand',
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.open_in_full,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              controller.formattedTime,
                              maxLines: 1,
                              softWrap: false,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1,
                                fontFeatures: <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          if (taskTitle != null && taskTitle.isNotEmpty)
                            Text(
                              taskTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  _buildControls(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    late final String primaryLabel;
    late final IconData primaryIcon;
    late final VoidCallback primaryAction;
    late final bool primaryEnabled;

    switch (controller.runState) {
      case TimerRunState.idle:
        primaryLabel = 'START';
        primaryIcon = Icons.play_arrow;
        primaryAction = controller.start;
        primaryEnabled = true;
      case TimerRunState.running:
        primaryLabel = 'PAUSE';
        primaryIcon = Icons.pause;
        primaryAction = controller.pause;
        primaryEnabled = true;
      case TimerRunState.paused:
        primaryLabel = 'RESUME';
        primaryIcon = Icons.play_arrow;
        primaryAction = controller.resume;
        primaryEnabled = true;
    }

    final bool canStop = controller.runState != TimerRunState.idle;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        TextButton.icon(
          onPressed: primaryEnabled ? primaryAction : null,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          icon: Icon(primaryIcon, size: 18),
          label: Text(
            primaryLabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(width: 4),
        TextButton.icon(
          onPressed: canStop ? controller.stop : null,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
          ),
          icon: const Icon(Icons.stop, size: 18),
          label: const Text(
            'STOP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}
