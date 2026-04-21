// Persistence interface for per-user data (loadout, decks, settings).
//
// The concrete implementation today is SharedPrefsUserDataRepository.
// When Firebase accounts are added, swap it for a Firestore-backed class
// that implements this same interface — no other code needs to change.
//
// Design rule: all load* methods are synchronous. Both implementations
// must pre-load their data before the app starts (e.g. in main() before
// runApp) so UI code never has to await anything.

// ── Deck data transfer object ───────────────────────────────────────────────

/// Serialization-friendly deck snapshot. Card IDs are bare strings; the
/// caller resolves them back to [CardDefinition] via [cardRegistry].
class PersistedDeck {
  final String id;
  final String name;

  /// Exactly 6 entries. null = empty slot.
  final List<String?> slotIds;

  const PersistedDeck({
    required this.id,
    required this.name,
    required this.slotIds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slots': slotIds,
      };

  factory PersistedDeck.fromJson(Map<String, dynamic> j) => PersistedDeck(
        id: j['id'] as String,
        name: j['name'] as String,
        slotIds: (j['slots'] as List).map((e) => e as String?).toList(),
      );
}

// ── Repository interface ────────────────────────────────────────────────────

abstract class UserDataRepository {
  // ── Cosmetic loadout ───────────────────────────────────────────────────────

  /// Returns the persisted loadout slot IDs, or null (use defaults).
  ///
  /// Keys: masterPieceId, studentPieceId, throneId, boardId,
  ///       sceneryId, cardBackId, moveEffectId, uiSoundsId
  Map<String, String>? loadLoadoutIds();

  Future<void> saveLoadoutIds(Map<String, String> ids);

  // ── Decks ──────────────────────────────────────────────────────────────────

  /// Returns all saved decks, or null if none have been saved yet.
  List<PersistedDeck>? loadDecks();

  Future<void> saveDecks(List<PersistedDeck> decks);

  /// Returns the last selected deck ID, or null.
  String? loadSelectedDeckId();

  Future<void> saveSelectedDeckId(String? id);

  // ── Tutorial ───────────────────────────────────────────────────────────────

  /// Returns true if the player has completed the tutorial at least once.
  bool loadTutorialDone();

  Future<void> saveTutorialDone(bool done);

  // ── Unlocks ────────────────────────────────────────────────────────────────

  /// IDs of cards the player owns. Null = not yet persisted (use starter set).
  Set<String>? loadUnlockedCardIds();

  Future<void> saveUnlockedCardIds(Set<String> ids);

  /// IDs of cosmetics the player owns. Null = not yet persisted (use defaults).
  Set<String>? loadUnlockedCosmeticIds();

  Future<void> saveUnlockedCosmeticIds(Set<String> ids);
}
