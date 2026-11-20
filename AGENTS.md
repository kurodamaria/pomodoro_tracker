# AGENTS.md — `pomodoro_tracker` Engineering Rules

## Product Scope (Strict)
- **Local-first only:** Never add user authentication, login/signup flows, cloud sync, social media sharing, global leaderboards, feedback forms, or third-party integrations (Google, Trello, Todoist, Slack, Telegram, etc.).
- **Core features only:** Interval timer (`pomodoro`, `shortBreak`, `longBreak`), `TODO` & `Scheduler` (`today`, `inbox`, `tomorrow`, `week`, `later`), local session statistics, and local app/timer/audio preferences.

## Architecture & Code Discipline
- `lib/models/`: Immutable data classes with `const` constructors where possible and `copyWith` methods.
- `lib/state/`: State management (`ChangeNotifier` / `ValueNotifier`) separated from UI. Never place `dart:async` `Timer` logic or business calculations inside `Widget` classes.
- `lib/theme/`: All colors, typography, and theme tokens live in `lib/theme/app_theme.dart`. Do not hardcode hex colors inside screens or widgets.
- `lib/screens/` & `lib/widgets/`: Keep widgets small and composable. Always dispose `TextEditingController`, `ScrollController`, and `FocusNode` in `State.dispose()`.
- **No unrequested dependencies:** Do not add packages to `pubspec.yaml` unless explicitly instructed in the task prompt.

## Execution Rules
1. **Inspect before editing:** Read every target file before modifying it so existing symbols, imports, and constructors are preserved.
2. **Stay within scope:** Only create or edit files listed in `TARGETS`. Do not refactor unrelated files.
3. **No silent stubs:** Never leave `TODO` comments or empty `onPressed: () {}` callbacks without explicit instruction.
4. **Always verify:** Run `flutter analyze && flutter test` after every edit and fix all warnings, lints, or test failures before reporting done.
