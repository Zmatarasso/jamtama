import 'package:flutter/foundation.dart';

import 'card.dart';

// ---------------------------------------------------------------------------
// Validation result
// ---------------------------------------------------------------------------

/// The result of validating a [SavedDeck] for battle readiness.
///
/// [isValid] — true only when the deck can legally enter a match.
/// [errors]  — human-readable reasons why it cannot (empty when valid).
@immutable
class DeckValidation {
  final bool isValid;
  final List<String> errors;

  const DeckValidation._({required this.isValid, required this.errors});

  static const valid = DeckValidation._(isValid: true, errors: []);
}

// ---------------------------------------------------------------------------
// Deck model
// ---------------------------------------------------------------------------

/// A named deck stored in the player's collection.
/// Always has exactly 6 slots; a null slot means it is empty.
@immutable
class SavedDeck {
  final String id;
  final String name;

  /// Exactly 6 entries. null = empty slot.
  final List<CardDefinition?> slots;

  const SavedDeck({
    required this.id,
    required this.name,
    required this.slots,
  });

  bool contains(CardDefinition card) => slots.any((s) => s?.id == card.id);
  bool get isFull => slots.every((s) => s != null);
  int get cardCount => slots.where((s) => s != null).length;

  /// Returns a [DeckValidation] describing whether this deck can enter a match.
  ///
  /// Rules:
  /// - All 6 slots must be filled.
  /// - No duplicate cards (same id in two slots).
  ///
  /// Add new rules here as the game design evolves; the UI and match entry
  /// gate both consume this — no other changes needed.
  DeckValidation validate() {
    final errors = <String>[];

    final filled = slots.where((s) => s != null).toList();
    final missing = 6 - filled.length;
    if (missing > 0) {
      errors.add('Missing $missing card${missing == 1 ? '' : 's'} (need 6)');
    }

    final ids = filled.map((c) => c!.id).toList();
    final unique = ids.toSet();
    if (unique.length < ids.length) {
      // Find and name the duplicates for a helpful message.
      final seen = <String>{};
      final dupes = <String>[];
      for (final c in filled) {
        if (!seen.add(c!.id)) dupes.add(c.name);
      }
      errors.add('Duplicate card${dupes.length == 1 ? '' : 's'}: ${dupes.join(', ')}');
    }

    if (errors.isEmpty) return DeckValidation.valid;
    return DeckValidation._(isValid: false, errors: errors);
  }

  SavedDeck copyWith({String? name, List<CardDefinition?>? slots}) => SavedDeck(
        id: id,
        name: name ?? this.name,
        slots: slots ?? List<CardDefinition?>.of(this.slots),
      );
}
