# AGENTS.md — `pomodoro_tracker` Engineering Rules

## Product Scope (Strict)
- **Local-first only:** Never add user authentication, login/signup flows, cloud sync, social media sharing, global leaderboards, feedback forms, or third-party integrations (Google, Trello, Todoist, Slack, Telegram, etc.).
- **Core features only:** Interval timer (`pomodoro`, `shortBreak`, `longBreak`), `TODO` & `Scheduler` (`today`, `inbox`, `tomorrow`, `week`, `later`), local session statistics, local app/timer/audio preferences, Mini/Dock Mode, and desktop window/tray behavior.

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
5. **Propose a commit, never auto-commit:** Never run `git commit` or `git push` yourself. Once `flutter analyze && flutter test` passes, end your response with a single copy-pasteable `git add` and `git commit -m "<type>: <summary>"` command for the user to run after manual verification.
6. **Terse responses only:** Do not recap instructions, paste code snippets, or summarize unchanged code. Report only: (a) files created/edited, (b) `flutter analyze && flutter test` result, and (c) the proposed `git add && git commit` command.
