/// Cosmetic slot for UI interaction sounds — the non-move audio events
/// that happen throughout a match (card/piece selection, draft flips,
/// round/match end fanfares).
///
/// All paths are optional. Null means that event plays silently.
/// Paths are relative to the Flutter asset root, e.g. `'audio/card_select.ogg'`.
class UiSoundsCosmetic {
  final String id;
  final String name;

  /// Played when the active player taps a card to select it.
  final String? cardSelectSound;

  /// Played when the active player taps or begins dragging a piece.
  final String? pieceSelectSound;

  /// Played when a card is revealed/flipped during the draft phase.
  final String? cardDraftSound;

  /// Short fanfare played when a round ends (winner decided).
  final String? roundWinSound;

  /// Longer fanfare played when the match ends.
  final String? matchWinSound;

  const UiSoundsCosmetic({
    required this.id,
    required this.name,
    this.cardSelectSound,
    this.pieceSelectSound,
    this.cardDraftSound,
    this.roundWinSound,
    this.matchWinSound,
  });
}
