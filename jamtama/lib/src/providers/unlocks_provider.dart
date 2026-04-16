import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/card_definitions.dart';
import '../data/user_data_repository_provider.dart';
import '../models/card.dart';

// ---------------------------------------------------------------------------
// Starter sets — what every new player begins with
// ---------------------------------------------------------------------------

/// Cards every player starts with regardless of purchases.
const starterCardIds = {
  'halberd',
  'mace',
  'sickle',
  'spear',
  'saber',
  'longsword',
};

/// Cosmetic IDs that are free / default for everyone.
const starterCosmeticIds = {
  'master_default',
  'student_default',
  'throne_default',
  'board_default',
  'scenery_default',
  'card_back_default',
  'move_default',
};

// ---------------------------------------------------------------------------
// Unlocked cards
// ---------------------------------------------------------------------------

class UnlockedCardsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final persisted =
        ref.read(userDataRepositoryProvider).loadUnlockedCardIds();
    // Null means first launch — give them the starter set.
    return persisted ?? Set<String>.from(starterCardIds);
  }

  /// Add a card by ID and persist.
  Future<void> unlock(String cardId) async {
    if (state.contains(cardId)) return;
    state = {...state, cardId};
    await ref.read(userDataRepositoryProvider).saveUnlockedCardIds(state);
  }

  bool owns(String cardId) => state.contains(cardId);

  /// All [CardDefinition]s the player currently owns.
  List<CardDefinition> get ownedCards =>
      allCards.where((c) => state.contains(c.id)).toList();
}

final unlockedCardsProvider =
    NotifierProvider<UnlockedCardsNotifier, Set<String>>(
        UnlockedCardsNotifier.new);

// ---------------------------------------------------------------------------
// Unlocked cosmetics
// ---------------------------------------------------------------------------

class UnlockedCosmeticsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final persisted =
        ref.read(userDataRepositoryProvider).loadUnlockedCosmeticIds();
    return persisted ?? Set<String>.from(starterCosmeticIds);
  }

  /// Add a cosmetic by ID and persist.
  Future<void> unlock(String cosmeticId) async {
    if (state.contains(cosmeticId)) return;
    state = {...state, cosmeticId};
    await ref
        .read(userDataRepositoryProvider)
        .saveUnlockedCosmeticIds(state);
  }

  bool owns(String cosmeticId) => state.contains(cosmeticId);
}

final unlockedCosmeticsProvider =
    NotifierProvider<UnlockedCosmeticsNotifier, Set<String>>(
        UnlockedCosmeticsNotifier.new);
