import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/card_definitions.dart';
import '../data/user_data_repository.dart';
import '../data/user_data_repository_provider.dart';
import '../models/card.dart';
import '../models/saved_deck.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

const _sentinel = Object();

class DeckBuilderState {
  final List<SavedDeck> decks;
  final String? selectedDeckId;

  const DeckBuilderState({required this.decks, this.selectedDeckId});

  SavedDeck? get selectedDeck {
    if (selectedDeckId == null) return null;
    for (final d in decks) {
      if (d.id == selectedDeckId) return d;
    }
    return null;
  }

  DeckBuilderState copyWith({
    List<SavedDeck>? decks,
    Object? selectedDeckId = _sentinel,
  }) =>
      DeckBuilderState(
        decks: decks ?? this.decks,
        selectedDeckId: identical(selectedDeckId, _sentinel)
            ? this.selectedDeckId
            : selectedDeckId as String?,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DeckBuilderNotifier extends Notifier<DeckBuilderState> {
  // Monotonic counter for generating unique local IDs.
  // Safe for local-only use; Firebase will use its own document IDs.
  int _nextId = 1;

  @override
  DeckBuilderState build() {
    final repo = ref.read(userDataRepositoryProvider);
    final persisted = repo.loadDecks();

    if (persisted != null && persisted.isNotEmpty) {
      // Resolve card IDs back to CardDefinition objects.
      final decks = persisted.map(_fromPersisted).toList();

      // Keep _nextId ahead of any existing numeric suffixes so new IDs
      // never collide with loaded ones.
      for (final d in persisted) {
        final n = int.tryParse(d.id.replaceFirst('deck_', ''));
        if (n != null && n >= _nextId) _nextId = n + 1;
      }

      final savedSelectedId = repo.loadSelectedDeckId();
      final selectedId = decks.any((d) => d.id == savedSelectedId)
          ? savedSelectedId
          : decks.first.id;

      return DeckBuilderState(decks: decks, selectedDeckId: selectedId);
    }

    // First launch — seed a starter deck.
    final id = 'deck_${_nextId++}';
    final starter = SavedDeck(
      id: id,
      name: 'Starter Deck',
      slots: List<CardDefinition?>.of(redDefaultDeck.cards),
    );
    _persist(DeckBuilderState(decks: [starter], selectedDeckId: id));
    return DeckBuilderState(decks: [starter], selectedDeckId: id);
  }

  // ── Selection ─────────────────────────────────────────────────────────────

  void selectDeck(String id) {
    final next = state.copyWith(selectedDeckId: id);
    state = next;
    ref.read(userDataRepositoryProvider).saveSelectedDeckId(id);
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  void addDeck() {
    final id = 'deck_${_nextId++}';
    final deck = SavedDeck(
      id: id,
      name: 'Deck ${state.decks.length + 1}',
      slots: List<CardDefinition?>.filled(6, null),
    );
    _update(state.copyWith(
      decks: [...state.decks, deck],
      selectedDeckId: id,
    ));
  }

  void deleteDeck(String deckId) {
    final decks = state.decks.where((d) => d.id != deckId).toList();
    final newSelected = state.selectedDeckId == deckId
        ? (decks.isEmpty ? null : decks.last.id)
        : state.selectedDeckId;
    _update(DeckBuilderState(decks: decks, selectedDeckId: newSelected));
  }

  void renameDeck(String deckId, String name) {
    _update(state.copyWith(
      decks: [
        for (final d in state.decks)
          if (d.id == deckId) d.copyWith(name: name) else d,
      ],
    ));
  }

  // ── Card management ───────────────────────────────────────────────────────

  void addCard(String deckId, CardDefinition card) {
    final decks = List<SavedDeck>.of(state.decks);
    final idx = decks.indexWhere((d) => d.id == deckId);
    if (idx == -1) return;
    final deck = decks[idx];
    if (deck.contains(card) || deck.isFull) return;
    final slots = List<CardDefinition?>.of(deck.slots);
    slots[slots.indexWhere((s) => s == null)] = card;
    decks[idx] = deck.copyWith(slots: slots);
    _update(state.copyWith(decks: decks));
  }

  void removeCard(String deckId, CardDefinition card) {
    final decks = List<SavedDeck>.of(state.decks);
    final idx = decks.indexWhere((d) => d.id == deckId);
    if (idx == -1) return;
    final slots = List<CardDefinition?>.of(decks[idx].slots);
    final cardIdx = slots.indexWhere((s) => s?.id == card.id);
    if (cardIdx == -1) return;
    slots[cardIdx] = null;
    decks[idx] = decks[idx].copyWith(slots: slots);
    _update(state.copyWith(decks: decks));
  }

  // ── Persistence helpers ───────────────────────────────────────────────────

  void _update(DeckBuilderState next) {
    state = next;
    _persist(next);
  }

  void _persist(DeckBuilderState s) {
    final repo = ref.read(userDataRepositoryProvider);
    repo.saveDecks(s.decks.map(_toPersisted).toList());
    repo.saveSelectedDeckId(s.selectedDeckId);
  }

  /// Convert a [SavedDeck] to its serialization-friendly form.
  static PersistedDeck _toPersisted(SavedDeck d) => PersistedDeck(
        id: d.id,
        name: d.name,
        slotIds: d.slots.map((c) => c?.id).toList(),
      );

  /// Resolve a [PersistedDeck] back to a [SavedDeck], skipping unknown IDs.
  static SavedDeck _fromPersisted(PersistedDeck p) {
    final slots = p.slotIds.map((id) {
      if (id == null) return null;
      return cardRegistry[id]; // null if card was removed from catalogue
    }).toList();

    // Pad to exactly 6 slots if data is somehow shorter.
    while (slots.length < 6) {
      slots.add(null);
    }

    return SavedDeck(id: p.id, name: p.name, slots: slots);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final deckBuilderProvider =
    NotifierProvider<DeckBuilderNotifier, DeckBuilderState>(
  DeckBuilderNotifier.new,
);
