import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cosmetics/models/sound_pack.dart';
import '../providers/audio_settings_provider.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();

  // Keep the service in sync with the volume sliders immediately — fires
  // on first listen and on every subsequent settings change.
  ref.listen<AudioSettings>(
    audioSettingsProvider,
    (_, settings) => service._applyVolume(settings),
    fireImmediately: true,
  );

  ref.onDispose(service.dispose);
  return service;
});

// ---------------------------------------------------------------------------
// AudioService
// ---------------------------------------------------------------------------

/// Plays game sounds using a small pool of [AudioPlayer]s so simultaneous
/// events (e.g. a capture and a win sting) don't cut each other off.
///
/// All methods accept a [SoundPack]. A null path inside the pack means that
/// event plays silently — no error, no crash.
///
/// Volume is managed through [audioSettingsProvider]; call [_applyVolume]
/// whenever the settings change (the provider above does this automatically).
class AudioService {
  // One dedicated player per sound role.
  final _move    = AudioPlayer();
  final _capture = AudioPlayer();
  final _ui      = AudioPlayer();
  final _win     = AudioPlayer();

  double _masterVol = 1.0;
  double _sfxVol    = 1.0;

  AudioService() {
    for (final p in [_move, _capture, _ui, _win]) {
      p.setReleaseMode(ReleaseMode.stop);
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> playCardSelect(SoundPack pack) =>
      _playSfx(_ui, pack.cardSelect);

  Future<void> playPieceSelect(SoundPack pack) =>
      _playSfx(_ui, pack.pieceSelect);

  Future<void> playCardDraft(SoundPack pack) =>
      _playSfx(_ui, pack.cardDraft);

  Future<void> playMove(SoundPack pack) =>
      _playSfx(_move, pack.move);

  Future<void> playCapture(SoundPack pack) =>
      _playSfx(_capture, pack.capture);

  Future<void> playRoundWin(SoundPack pack) =>
      _playSfx(_win, pack.roundWin);

  Future<void> playMatchWin(SoundPack pack) =>
      _playSfx(_win, pack.matchWin);

  // ── Volume ────────────────────────────────────────────────────────────────

  void _applyVolume(AudioSettings settings) {
    _masterVol = settings.masterVolume;
    _sfxVol    = settings.sfxVolume;
    // Pre-set volumes on all players so the next play() call uses them.
    final effective = (_masterVol * _sfxVol).clamp(0.0, 1.0);
    for (final p in [_move, _capture, _ui, _win]) {
      p.setVolume(effective);
    }
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  Future<void> _playSfx(AudioPlayer player, String? assetPath) async {
    if (assetPath == null) return;
    await player.play(AssetSource(assetPath));
  }

  Future<void> dispose() async {
    for (final p in [_move, _capture, _ui, _win]) {
      await p.dispose();
    }
  }
}
