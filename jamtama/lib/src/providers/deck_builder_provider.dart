import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/card_definitions.dart';
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
  int _nextId = 1;

  @override
  DeckBuilderState build() {
    // Seed with one pre-filled starter deck so there's something to see.
    final id = 'deck_${_nextId++}';
    final starter = SavedDeck(
      id: id,
      name: 'Starter Deck',
      slots: List<CardDefinition?>.of(redDefaultDeck.cards),
    );
    return DeckBuilderState(decks: [starter], selectedDeckId: id);
  }

  // ── Selection ─────────────────────────────────────────────────────────────

  void selectDeck(String id) => state = state.copyWith(selectedDeckId: id);

  // ── CRUD ──────────────────────────────────────────────────────────────────

  void addDeck() {
    final id = 'deck_${_nextId++}';
    final deck = SavedDeck(
      id: id,
      name: 'Deck ${state.decks.length + 1}',
      slots: List<CardDefinition?>.filled(6, null),
    );
    state = state.copyWith(
      decks: [...state.decks, deck],
      selectedDeckId: id,
    );
  }

  void deleteDeck(String deckId) {
    final decks = state.decks.where((d) => d.id != deckId).toList();
    final newSelected = state.selectedDeckId == deckId
        ? (decks.isEmpty ? null : decks.last.id)
        : state.selectedDeckId;
    state = DeckBuilderState(decks: decks, selectedDeckId: newSelected);
  }

  void renameDeck(String deckId, String name) {
    state = state.copyWith(
      decks: [
        for (final d in state.decks)
          if (d.id == deckId) d.copyWith(name: name) else d,
      ],
    );
  }

  // ── Card management ───────────────────────────────────────────────────────

  void addCard(String deckId, CardDefinition card) {
    final decks = List<SavedDeck>.of(state.decks);
    final idx = decks.indexWhere((d) => d.id == deckId);
    if (idx == -1) return;
    final deck = decks[idx];
    if (deck.contains(card) || deck.isFull) return;
    final slots = List<CardDefinition?>.of(deck.slots);
    final emptyIdx = slots.indexWhere((s) => s == null);
    slots[emptyIdx] = card;
    decks[idx] = deck.copyWith(slots: slots);
    state = state.copyWith(decks: decks);
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
    state = state.copyWith(decks: decks);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final deckBuilderProvider =
    NotifierProvider<DeckBuilderNotifier, DeckBuilderState>(
  DeckBuilderNotifier.new,
);
