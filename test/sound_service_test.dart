import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_tracker/services/sound_service.dart';

void main() {
  group('SoundService WAV builders', () {
    test('produce non-empty RIFF/WAVE buffers', () {
      final Uint8List bell = SoundService.buildBellWav();
      final Uint8List warning = SoundService.buildWarningWav();
      final Uint8List tick = SoundService.buildTickWav();

      for (final Uint8List buffer in <Uint8List>[bell, warning, tick]) {
        expect(buffer, isNotEmpty);
        expect(
          buffer.sublist(0, 4),
          <int>[0x52, 0x49, 0x46, 0x46], // "RIFF"
        );
        expect(
          buffer.sublist(8, 12),
          <int>[0x57, 0x41, 0x56, 0x45], // "WAVE"
        );
      }

      // Longer cues must contain more sample data than shorter ones.
      expect(bell.length, greaterThan(warning.length));
      expect(warning.length, greaterThan(tick.length));
    });
  });

  group('SoundService (disabled)', () {
    test('play and dispose complete cleanly without platform channels',
        () async {
      final SoundService service = SoundService(enabled: false);

      await service.playAlarm(0.5);
      await service.playOneMinuteWarning(0.5);
      await service.playTick(0.5);
      await service.playAlarm(0.0);

      await service.dispose();
    });
  });
}
