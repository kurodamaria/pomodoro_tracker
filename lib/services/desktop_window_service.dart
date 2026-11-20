// ignore_for_file: deprecated_member_use
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show Size;
import 'package:window_manager/legacy.dart';

/// Thin, defensive wrapper around `window_manager` for desktop behavior.
///
/// Every call is guarded so tests, web, and unsupported platforms are no-ops.
class DesktopWindowService {
  DesktopWindowService({this.enabled = true});

  /// When false, the service never touches the platform (used by tests).
  final bool enabled;

  Size? _savedNormalSize;

  bool get isSupported =>
      enabled &&
      !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  Future<void> initialize({required WindowListener listener}) async {
    if (!isSupported) {
      return;
    }
    try {
      await windowManager.ensureInitialized();
      await windowManager.setMinimumSize(const Size(280, 160));
      await windowManager.setPreventClose(true);
      windowManager.addListener(listener);
    } catch (_) {
      // Unsupported platform or missing plugin.
    }
  }

  Future<void> enterMiniMode({required bool alwaysOnTop}) async {
    if (!isSupported) {
      return;
    }
    try {
      _savedNormalSize ??= await windowManager.getSize();
      await windowManager.setSize(const Size(300, 180));
      await windowManager.setAlwaysOnTop(alwaysOnTop);
    } catch (_) {
      // Ignore.
    }
  }

  Future<void> exitMiniMode() async {
    if (!isSupported) {
      return;
    }
    try {
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setSize(_savedNormalSize ?? const Size(880, 720));
    } catch (_) {
      // Ignore.
    }
  }

  Future<void> setAlwaysOnTop(bool value) async {
    if (!isSupported) {
      return;
    }
    try {
      await windowManager.setAlwaysOnTop(value);
    } catch (_) {
      // Ignore.
    }
  }

  Future<void> setTitle(String title) async {
    if (!isSupported) {
      return;
    }
    try {
      await windowManager.setTitle(title);
    } catch (_) {
      // Ignore.
    }
  }

  Future<void> hideToTray() async {
    if (!isSupported) {
      return;
    }
    try {
      await windowManager.hide();
    } catch (_) {
      // Ignore.
    }
  }

  Future<void> showFromTray() async {
    if (!isSupported) {
      return;
    }
    try {
      await windowManager.show();
      await windowManager.focus();
    } catch (_) {
      // Ignore.
    }
  }

  Future<void> forceClose() async {
    if (!isSupported) {
      return;
    }
    try {
      await windowManager.setPreventClose(false);
      await windowManager.close();
    } catch (_) {
      // Ignore.
    }
  }
}
