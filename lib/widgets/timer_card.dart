import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../state/timer_controller.dart';
import '../theme/app_theme.dart';

/// The hero timer surface: phase colour, countdown, and controls.
class TimerCard extends StatelessWidget {
  const TimerCard({
    super.key,
    required this.controller,
    required this.onOpenSettings,
  });

  final TimerController controller;
  final VoidCallback onOpenSettings;

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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        final TimerPhase phase = controller.phase;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _phaseColor(phase),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildTopBar(context),
              const SizedBox(height: 24),
              _buildBody(context),
              const SizedBox(height: 24),
              _buildControls(context),
              if (controller.runState == TimerRunState.running ||
                  controller.runState == TimerRunState.paused) ...<Widget>[
                const SizedBox(height: 20),
                _buildFooter(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          onPressed: onOpenSettings,
          tooltip: 'Settings',
          icon: const Icon(Icons.settings, color: Colors.white),
        ),
        Expanded(
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                _PhaseChip(
                  label: 'Pomodoro',
                  selected: controller.phase == TimerPhase.pomodoro,
                  onTap: () => controller.selectPhase(TimerPhase.pomodoro),
                ),
                _PhaseChip(
                  label: 'Short Break',
                  selected: controller.phase == TimerPhase.shortBreak,
                  onTap: () => controller.selectPhase(TimerPhase.shortBreak),
                ),
                _PhaseChip(
                  label: 'Long Break',
                  selected: controller.phase == TimerPhase.longBreak,
                  onTap: () => controller.selectPhase(TimerPhase.longBreak),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: controller.skipPhase,
          tooltip: 'Skip phase',
          icon: const Icon(Icons.fast_forward, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final String? taskTitle = controller.activeTaskTitle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          controller.phaseHeaderLabel.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            controller.formattedTime,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (taskTitle != null && taskTitle.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            taskTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    switch (controller.runState) {
      case TimerRunState.idle:
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: <Widget>[
            _ControlButton(label: 'START', onPressed: controller.start),
            _ControlButton(label: 'STOP', onPressed: null),
          ],
        );
      case TimerRunState.running:
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: <Widget>[
            _ControlButton(label: 'PAUSE', onPressed: controller.pause),
            _ControlButton(label: 'STOP', onPressed: controller.stop),
          ],
        );
      case TimerRunState.paused:
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: <Widget>[
            _ControlButton(label: 'RESUME', onPressed: controller.resume),
            _ControlButton(label: 'DONE', onPressed: controller.doneEarly),
          ],
        );
    }
  }

  Widget _buildFooter(BuildContext context) {
    final TimeOfDay next = TimeOfDay.fromDateTime(
      controller.estimatedNextLongBreak(DateTime.now()),
    );
    final String formatted = MaterialLocalizations.of(context).formatTimeOfDay(
      next,
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
      ),
      child: Text(
        'NEXT LONG BREAK · $formatted',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black87 : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(
          color: Colors.white.withValues(alpha: enabled ? 1.0 : 0.4),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: enabled ? 1.0 : 0.5),
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
