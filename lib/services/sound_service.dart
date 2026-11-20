import 'dart:async' show runZonedGuarded;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show MissingPluginException;

/// Generates and plays short synthesized audio cues.
///
/// All cues are built in pure Dart as 16-bit mono PCM WAV buffers, so no
/// bundled asset files are needed. The underlying [AudioPlayer] is created
/// strictly lazily (only on an actual play request) and every platform call
/// is guarded, so headless or test environments where the native plugin is
/// missing never crash and never retry.
class SoundService {
  SoundService({this.enabled = true});

  /// When false, playback is skipped entirely and no [AudioPlayer] is created.
  final bool enabled;

  static const int _sampleRate = 44100;

  AudioPlayer? _player;

  /// Set once a platform call reports a missing plugin, to avoid retrying.
  bool _disabledForSession = false;

  /// Plays the decaying two-tone bell used to signal a completed phase.
  Future<void> playAlarm(double volume) => _play(buildBellWav(), volume);

  /// Plays the soft ping used for the one-minute warning.
  Future<void> playOneMinuteWarning(double volume) =>
      _play(buildWarningWav(), volume);

  /// Plays the ultra-short click used for the ticking sound.
  Future<void> playTick(double volume) => _play(buildTickWav(), volume);

  Future<void> _play(Uint8List wav, double volume) async {
    final double clamped = volume.clamp(0.0, 1.0).toDouble();
    if (!enabled || _disabledForSession || clamped <= 0.0) {
      return;
    }
    try {
      await runZonedGuarded(
        () async {
          final AudioPlayer player = _player ??= AudioPlayer();
          await player.setVolume(clamped);
          await player.play(BytesSource(wav));
        },
        (Object error, StackTrace _) {
          // audioplayers' EventChannel emits plugin errors on an unawaited
          // future; catch them here so playback disables cleanly.
          if (error is MissingPluginException) {
            _disabledForSession = true;
          }
        },
      );
    } on MissingPluginException {
      // No native audio plugin (e.g. unit/widget tests): stop trying.
      _disabledForSession = true;
    } catch (_) {
      // Unsupported platform or transient playback failure: ignore.
    }
  }

  Future<void> dispose() async {
    final AudioPlayer? player = _player;
    if (player != null) {
      try {
        await player.dispose();
      } catch (_) {
        // Ignore teardown failures.
      }
    }
    _player = null;
  }

  /// A pleasant ~0.6s chime with an exponentially decaying envelope.
  static Uint8List buildBellWav() {
    const double duration = 0.6;
    final int count = (duration * _sampleRate).round();
    final List<double> samples = <double>[];
    for (int i = 0; i < count; i++) {
      final double t = i / _sampleRate;
      final double envelope = math.exp(-4.0 * t);
      final double tone = math.sin(2 * math.pi * 880.0 * t) * 0.7 +
          math.sin(2 * math.pi * 1320.0 * t) * 0.3;
      samples.add(tone * envelope * 0.8);
    }
    return _buildWav(samples);
  }

  /// A short, soft ~0.25s ping.
  static Uint8List buildWarningWav() {
    const double duration = 0.25;
    final int count = (duration * _sampleRate).round();
    final List<double> samples = <double>[];
    for (int i = 0; i < count; i++) {
      final double t = i / _sampleRate;
      final double envelope = math.exp(-12.0 * t);
      samples.add(math.sin(2 * math.pi * 660.0 * t) * envelope * 0.6);
    }
    return _buildWav(samples);
  }

  /// An ultra-short ~0.025s subtle click.
  static Uint8List buildTickWav() {
    const double duration = 0.025;
    final int count = (duration * _sampleRate).round();
    final List<double> samples = <double>[];
    for (int i = 0; i < count; i++) {
      final double t = i / _sampleRate;
      final double envelope = math.exp(-140.0 * t);
      samples.add(math.sin(2 * math.pi * 2000.0 * t) * envelope * 0.5);
    }
    return _buildWav(samples);
  }

  /// Wraps [samples] (range `-1.0..1.0`) in a standard 16-bit mono PCM header.
  static Uint8List _buildWav(List<double> samples) {
    const int numChannels = 1;
    const int bitsPerSample = 16;
    const int bytesPerSample = bitsPerSample ~/ 8;
    final int dataSize = samples.length * bytesPerSample * numChannels;
    final int byteRate = _sampleRate * numChannels * bytesPerSample;
    final int blockAlign = numChannels * bytesPerSample;

    final ByteData data = ByteData(44 + dataSize);
    int offset = 0;

    void writeAscii(String value) {
      for (final int codeUnit in value.codeUnits) {
        data.setUint8(offset++, codeUnit);
      }
    }

    writeAscii('RIFF');
    data.setUint32(offset, 36 + dataSize, Endian.little);
    offset += 4;
    writeAscii('WAVE');

    writeAscii('fmt ');
    data.setUint32(offset, 16, Endian.little);
    offset += 4;
    data.setUint16(offset, 1, Endian.little); // PCM
    offset += 2;
    data.setUint16(offset, numChannels, Endian.little);
    offset += 2;
    data.setUint32(offset, _sampleRate, Endian.little);
    offset += 4;
    data.setUint32(offset, byteRate, Endian.little);
    offset += 4;
    data.setUint16(offset, blockAlign, Endian.little);
    offset += 2;
    data.setUint16(offset, bitsPerSample, Endian.little);
    offset += 2;

    writeAscii('data');
    data.setUint32(offset, dataSize, Endian.little);
    offset += 4;

    for (final double sample in samples) {
      final int value = (sample.clamp(-1.0, 1.0) * 32767).round();
      data.setInt16(offset, value, Endian.little);
      offset += 2;
    }

    return data.buffer.asUint8List();
  }
}
