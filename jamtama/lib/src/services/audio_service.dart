import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cosmetics/models/move_effect_cosmetic.dart';
import '../cosmetics/models/ui_sounds_cosmetic.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});

// ---------------------------------------------------------------------------
// AudioService
// ---------------------------------------------------------------------------

/// Thin wrapper around audioplayers that handles null asset paths gracefully
/// (null = silence) and keeps a small pool of players so overlapping sounds
/// don't cut each other off.
///
/// Call the named methods from game widgets/notifiers; pass the relevant
/// cosmetic so the service uses whatever sounds are currently equipped.
///
/// Usage:
/// ```dart
/// final audio = ref.read(audioServiceProvider);
/// audio.playCardSelect(ref.read(cosmeticLoadoutProvider).uiSounds);
/// ```
class AudioService {
  // One dedicated player per sound role avoids overlap issues (e.g. a capture
  // sound cutting off a move sound that fires at the same time).
  final _move = AudioPlayer();
  final _capture = AudioPlayer();
  final _ui = AudioPlayer();
  final _win = AudioPlayer();

  AudioService() {
    // Low-latency mode for all players.
    for (final p in [_move, _capture, _ui, _win]) {
      p.setReleaseMode(ReleaseMode.stop);
    }
  }

  // ── Move effects ──────────────────────────────────────────────────────────

  Future<void> playMove(MoveEffectCosmetic cosmetic) =>
      _play(_move, cosmetic.moveSoundAsset);

  Future<void> playCapture(MoveEffectCosmetic cosmetic) =>
      _play(_capture, cosmetic.captureSoundAsset);

  // ── UI sounds ─────────────────────────────────────────────────────────────

  Future<void> playCardSelect(UiSoundsCosmetic cosmetic) =>
      _play(_ui, cosmetic.cardSelectSound);

  Future<void> playPieceSelect(UiSoundsCosmetic cosmetic) =>
      _play(_ui, cosmetic.pieceSelectSound);

  Future<void> playCardDraft(UiSoundsCosmetic cosmetic) =>
      _play(_ui, cosmetic.cardDraftSound);

  Future<void> playRoundWin(UiSoundsCosmetic cosmetic) =>
      _play(_win, cosmetic.roundWinSound);

  Future<void> playMatchWin(UiSoundsCosmetic cosmetic) =>
      _play(_win, cosmetic.matchWinSound);

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _play(AudioPlayer player, String? assetPath) async {
    if (assetPath == null) return; // placeholder / silence
    await player.play(AssetSource(assetPath));
  }

  Future<void> dispose() async {
    for (final p in [_move, _capture, _ui, _win]) {
      await p.dispose();
    }
  }
}
