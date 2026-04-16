/// A complete set of sounds for one "feel" — swap the whole pack to
/// replace every sound in the game at once.
///
/// All paths are relative to the Flutter asset root, e.g.
///   `'audio/packs/default/move.ogg'`
///
/// Any null path plays silently for that event.
class SoundPack {
  final String id;
  final String name;

  // ── Gameplay ──────────────────────────────────────────────────────────────

  /// Played when the active player taps a card to select it.
  final String? cardSelect;

  /// Played when the active player taps or starts dragging a piece.
  final String? pieceSelect;

  /// Played when a card is revealed during the draft phase.
  final String? cardDraft;

  /// Played when a piece slides to an empty square.
  final String? move;

  /// Played when a piece lands on and removes an opponent's piece.
  final String? capture;

  // ── Win fanfares ──────────────────────────────────────────────────────────

  /// Short sting when a round ends (first-to-2 wins, not yet done).
  final String? roundWin;

  /// Longer fanfare when the match ends (someone reached 2 round wins).
  final String? matchWin;

  const SoundPack({
    required this.id,
    required this.name,
    this.cardSelect,
    this.pieceSelect,
    this.cardDraft,
    this.move,
    this.capture,
    this.roundWin,
    this.matchWin,
  });
}
