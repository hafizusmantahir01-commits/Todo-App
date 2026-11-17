import 'package:audioplayers/audioplayers.dart';

/// Background sound for the focus timer. Files live in assets/sounds.
class FocusSound {
  FocusSound._();

  static AudioPlayer? _player;
  static String _playing = 'off';

  static const choices = ['off', 'rain', 'white', 'brown'];

  static Future<void> play(String which) async {
    if (which == _playing) return;
    await stop();
    if (which == 'off') return;
    try {
      final p = AudioPlayer();
      _player = p;
      await p.setReleaseMode(ReleaseMode.loop);
      await p.play(AssetSource('sounds/$which.wav'), volume: 0.55);
      _playing = which;
    } catch (_) {
      _playing = 'off';
    }
  }

  static Future<void> stop() async {
    final p = _player;
    _player = null;
    _playing = 'off';
    try {
      await p?.stop();
      await p?.dispose();
    } catch (_) {}
  }
}
