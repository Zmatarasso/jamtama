import 'package:flutter/foundation.dart';

import 'card.dart';

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

  SavedDeck copyWith({String? name, List<CardDefinition?>? slots}) => SavedDeck(
        id: id,
        name: name ?? this.name,
        slots: slots ?? List<CardDefinition?>.of(this.slots),
      );
}
