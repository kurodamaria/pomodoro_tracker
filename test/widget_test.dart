// Smoke tests for the Pomodoro Tracker app shell, navigation, and timer card.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pomodoro_tracker/main.dart';
import 'package:pomodoro_tracker/services/desktop_window_service.dart';
import 'package:pomodoro_tracker/services/sound_service.dart';
import 'package:pomodoro_tracker/widgets/mini_timer_view.dart';
import 'package:pomodoro_tracker/widgets/timer_card.dart';
import 'package:pomodoro_tracker/widgets/todo_section.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('App shell renders and navigation switches views',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      PomodoroTrackerApp(
        soundService: SoundService(enabled: false),
        windowService: DesktopWindowService(enabled: false),
      ),
    );

    // The app bar title is always visible.
    expect(find.text('Pomodoro Tracker'), findsOneWidget);

    // The timer card is the default view.
    expect(find.text('START'), findsOneWidget);

    // Switch to Stats.
    await tester.tap(find.widgetWithText(TextButton, 'Stats'));
    await tester.pump();
    expect(find.text('Stats'), findsWidgets);

    // Switch to Settings.
    await tester.tap(find.widgetWithText(TextButton, 'Settings'));
    await tester.pump();
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('Timer card controls reflect the run state',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      PomodoroTrackerApp(
        soundService: SoundService(enabled: false),
        windowService: DesktopWindowService(enabled: false),
      ),
    );

    // Idle: START is available, STOP is disabled.
    expect(find.text('START'), findsOneWidget);
    expect(find.text('STOP'), findsOneWidget);
    expect(find.text('PAUSE'), findsNothing);
    expect(find.text('RESUME'), findsNothing);

    // Running: PAUSE and STOP are shown.
    await tester.tap(find.text('START'));
    await tester.pump();
    expect(find.text('PAUSE'), findsOneWidget);
    expect(find.text('STOP'), findsOneWidget);
    expect(find.text('START'), findsNothing);

    // Paused: RESUME and DONE are shown.
    await tester.tap(find.text('PAUSE'));
    await tester.pump();
    expect(find.text('RESUME'), findsOneWidget);
    expect(find.text('DONE'), findsOneWidget);
    expect(find.text('PAUSE'), findsNothing);
  });

  testWidgets('Adding a task shows it as the active task in the TimerCard',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      PomodoroTrackerApp(
        soundService: SoundService(enabled: false),
        windowService: DesktopWindowService(enabled: false),
      ),
    );

    final Finder addButton = find.byIcon(Icons.add);
    await tester.ensureVisible(addButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Write report');
    await tester.tap(addButton);
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(TimerCard),
        matching: find.text('Write report'),
      ),
      findsOneWidget,
    );

    // The row shows this task's cumulative finish time next to its badge.
    final Finder taskRow = find
        .ancestor(
          of: find.byIcon(Icons.drag_handle),
          matching: find.byType(Row),
        )
        .first;
    expect(
      find.descendant(
        of: taskRow,
        matching: find.textContaining(RegExp(r'\d{1,2}:\d{2}')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Selecting a scheme updates the timer countdown',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      PomodoroTrackerApp(
        soundService: SoundService(enabled: false),
        windowService: DesktopWindowService(enabled: false),
      ),
    );

    // Open Settings.
    await tester.tap(find.widgetWithText(TextButton, 'Settings'));
    await tester.pumpAndSettle();

    // Choose the personal scheme (30/2/25/4).
    await tester.tap(find.text('personal · 30/2/25/4'));
    await tester.pumpAndSettle();

    // Back to the timer, which now reflects a 30 minute pomodoro.
    await tester.tap(find.widgetWithText(TextButton, 'Timer'));
    await tester.pumpAndSettle();
    expect(find.text('30 : 00'), findsOneWidget);
  });

  testWidgets('Stats screen shows the daily goal and empty state',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      PomodoroTrackerApp(
        soundService: SoundService(enabled: false),
        windowService: DesktopWindowService(enabled: false),
      ),
    );

    await tester.tap(find.widgetWithText(TextButton, 'Stats'));
    await tester.pumpAndSettle();

    expect(find.text("Today's Goal"), findsOneWidget);
    expect(
      find.text(
        'No completed sessions yet. Finish a Pomodoro to see your stats here.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Renders without overflow at a 260px wide viewport',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(260, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      PomodoroTrackerApp(
        soundService: SoundService(enabled: false),
        windowService: DesktopWindowService(enabled: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('25 : 00'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mini Mode toggles to MiniTimerView and back',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      PomodoroTrackerApp(
        soundService: SoundService(enabled: false),
        windowService: DesktopWindowService(enabled: false),
      ),
    );

    expect(find.byType(TodoSection), findsOneWidget);

    await tester.tap(find.byIcon(Icons.picture_in_picture_alt_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(MiniTimerView), findsOneWidget);
    expect(find.byType(TodoSection), findsNothing);

    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pumpAndSettle();

    expect(find.byType(MiniTimerView), findsNothing);
    expect(find.byType(TodoSection), findsOneWidget);
  });
}
