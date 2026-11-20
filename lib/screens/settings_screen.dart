import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../state/settings_controller.dart';

/// Local app/timer/audio preferences, grouped into three tabs.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    this.onTestNotification,
  });

  final SettingsController controller;

  /// Invoked alongside the confirmation SnackBar when the test sound is sent.
  final VoidCallback? onTestNotification;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        final TimerSettings settings = controller.settings;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: <Widget>[
                  const TabBar(
                    tabs: <Widget>[
                      Tab(text: 'Timer'),
                      Tab(text: 'Notifications'),
                      Tab(text: 'Application'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: <Widget>[
                        _TimerTab(controller: controller, settings: settings),
                        _NotificationsTab(
                          controller: controller,
                          settings: settings,
                          onTestNotification: onTestNotification,
                        ),
                        _ApplicationTab(
                          controller: controller,
                          settings: settings,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _TimerTab extends StatelessWidget {
  const _TimerTab({required this.controller, required this.settings});

  final SettingsController controller;
  final TimerSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const _SectionTitle('SCHEMES'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final TimerScheme scheme in TimerScheme.presets)
              ChoiceChip(
                label: Text(
                  '${scheme.id} · ${scheme.pomodoroMinutes}/'
                  '${scheme.shortBreakMinutes}/${scheme.longBreakMinutes}/'
                  '${scheme.longBreakDelay}',
                ),
                selected: controller.activeSchemeId == scheme.id,
                onSelected: (_) => controller.applyScheme(scheme),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _StepperRow(
          label: 'Pomodoro duration',
          value: '${settings.pomodoroMinutes} min',
          onDecrement: () => controller.updateDurations(
            pomodoroMinutes: settings.pomodoroMinutes - 1,
          ),
          onIncrement: () => controller.updateDurations(
            pomodoroMinutes: settings.pomodoroMinutes + 1,
          ),
        ),
        _StepperRow(
          label: 'Short break duration',
          value: '${settings.shortBreakMinutes} min',
          onDecrement: () => controller.updateDurations(
            shortBreakMinutes: settings.shortBreakMinutes - 1,
          ),
          onIncrement: () => controller.updateDurations(
            shortBreakMinutes: settings.shortBreakMinutes + 1,
          ),
        ),
        _StepperRow(
          label: 'Long break duration',
          value: '${settings.longBreakMinutes} min',
          onDecrement: () => controller.updateDurations(
            longBreakMinutes: settings.longBreakMinutes - 1,
          ),
          onIncrement: () => controller.updateDurations(
            longBreakMinutes: settings.longBreakMinutes + 1,
          ),
        ),
        _StepperRow(
          label: 'Long break delay',
          value: '${settings.longBreakDelay} pomodoros',
          onDecrement: () => controller.updateDurations(
            longBreakDelay: settings.longBreakDelay - 1,
          ),
          onIncrement: () => controller.updateDurations(
            longBreakDelay: settings.longBreakDelay + 1,
          ),
        ),
        _StepperRow(
          label: 'Daily Goal',
          value: '${settings.dailyGoal} pomodoros',
          onDecrement: () => controller.updateDurations(
            dailyGoal: settings.dailyGoal - 1,
          ),
          onIncrement: () => controller.updateDurations(
            dailyGoal: settings.dailyGoal + 1,
          ),
        ),
        const Divider(height: 32),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto start pomodoros'),
          value: settings.autoStartPomodoros,
          onChanged: (bool value) => controller.updateSettings(
            settings.copyWith(autoStartPomodoros: value),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto start breaks'),
          value: settings.autoStartBreaks,
          onChanged: (bool value) => controller.updateSettings(
            settings.copyWith(autoStartBreaks: value),
          ),
        ),
      ],
    );
  }
}

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab({
    required this.controller,
    required this.settings,
    this.onTestNotification,
  });

  final SettingsController controller;
  final TimerSettings settings;
  final VoidCallback? onTestNotification;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const _SectionTitle('SOUND'),
        Row(
          children: <Widget>[
            const Text('Volume'),
            Expanded(
              child: Slider(
                value: settings.volume,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                label: '${(settings.volume * 100).round()}%',
                onChanged: (double value) => controller.updateSettings(
                  settings.copyWith(volume: value),
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '${(settings.volume * 100).round()}%',
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Play alarm sound'),
          value: settings.playAlarmSound,
          onChanged: (bool value) => controller.updateSettings(
            settings.copyWith(playAlarmSound: value),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Play ticking sound'),
          value: settings.playTickingSound,
          onChanged: (bool value) => controller.updateSettings(
            settings.copyWith(playTickingSound: value),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Notify when 1 minute left'),
          value: settings.notifyOneMinuteLeft,
          onChanged: (bool value) => controller.updateSettings(
            settings.copyWith(notifyOneMinuteLeft: value),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: () {
              onTestNotification?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pomodoro test notification')),
              );
            },
            child: const Text('Send test notification'),
          ),
        ),
      ],
    );
  }
}

class _ApplicationTab extends StatelessWidget {
  const _ApplicationTab({required this.controller, required this.settings});

  final SettingsController controller;
  final TimerSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const _SectionTitle('APPEARANCE'),
        Row(
          children: <Widget>[
            const Text('Color Theme'),
            const Spacer(),
            SegmentedButton<ThemePreference>(
              segments: const <ButtonSegment<ThemePreference>>[
                ButtonSegment<ThemePreference>(
                  value: ThemePreference.light,
                  label: Text('Light'),
                ),
                ButtonSegment<ThemePreference>(
                  value: ThemePreference.dark,
                  label: Text('Dark'),
                ),
                ButtonSegment<ThemePreference>(
                  value: ThemePreference.system,
                  label: Text('System'),
                ),
              ],
              selected: <ThemePreference>{settings.themePreference},
              onSelectionChanged: (Set<ThemePreference> selection) =>
                  controller.updateThemePreference(selection.first),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle('MINI MODE'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Always on top in Mini Mode'),
          value: settings.miniModeAlwaysOnTop,
          onChanged: controller.updateMiniModeAlwaysOnTop,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<CloseBehavior>(
          initialValue: settings.closeBehavior,
          decoration: const InputDecoration(labelText: 'When closing window'),
          items: const <DropdownMenuItem<CloseBehavior>>[
            DropdownMenuItem<CloseBehavior>(
              value: CloseBehavior.ask,
              child: Text('Ask'),
            ),
            DropdownMenuItem<CloseBehavior>(
              value: CloseBehavior.minimizeToTray,
              child: Text('Minimize to tray'),
            ),
            DropdownMenuItem<CloseBehavior>(
              value: CloseBehavior.quit,
              child: Text('Quit'),
            ),
          ],
          onChanged: (CloseBehavior? value) {
            if (value != null) {
              controller.updateCloseBehavior(value);
            }
          },
        ),
        const SizedBox(height: 24),
        const _SectionTitle('TASKS'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Clear DONE history once per day'),
          value: settings.clearDoneDaily,
          onChanged: (bool value) => controller.updateSettings(
            settings.copyWith(clearDoneDaily: value),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Add new tasks to the top'),
          value: settings.addNewTasksToTop,
          onChanged: (bool value) => controller.updateSettings(
            settings.copyWith(addNewTasksToTop: value),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remove a task from TODO when Pomodoro is complete'),
          value: settings.removeCompletedFromTodo,
          onChanged: (bool value) => controller.updateSettings(
            settings.copyWith(removeCompletedFromTodo: value),
          ),
        ),
        const Divider(height: 32),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: controller.resetToDefaults,
            child: const Text('Reset to defaults'),
          ),
        ),
      ],
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final String value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label)),
        IconButton(
          onPressed: onDecrement,
          tooltip: 'Decrease $label',
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 120,
          child: Text(value, textAlign: TextAlign.center),
        ),
        IconButton(
          onPressed: onIncrement,
          tooltip: 'Increase $label',
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
