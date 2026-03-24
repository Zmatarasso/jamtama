import 'package:flutter/material.dart';

/// Every independently-equippable cosmetic slot.
/// Used by the Collection UI to know which category to show.
enum CosmeticSlotType {
  masterPiece,
  studentPiece,
  throne,
  board,
  scenery,
  cardBack,
  moveEffect,
  uiSounds,
}

extension CosmeticSlotTypeX on CosmeticSlotType {
  String get label => switch (this) {
        CosmeticSlotType.masterPiece => 'Master',
        CosmeticSlotType.studentPiece => 'Student',
        CosmeticSlotType.throne => 'Throne',
        CosmeticSlotType.board => 'Board',
        CosmeticSlotType.scenery => 'Scenery',
        CosmeticSlotType.cardBack => 'Card Back',
        CosmeticSlotType.moveEffect => 'Move FX',
        CosmeticSlotType.uiSounds => 'Sounds',
      };

  IconData get icon => switch (this) {
        CosmeticSlotType.masterPiece => Icons.star,
        CosmeticSlotType.studentPiece => Icons.circle,
        CosmeticSlotType.throne => Icons.account_balance,
        CosmeticSlotType.board => Icons.grid_on,
        CosmeticSlotType.scenery => Icons.landscape,
        CosmeticSlotType.cardBack => Icons.style,
        CosmeticSlotType.moveEffect => Icons.auto_awesome,
        CosmeticSlotType.uiSounds => Icons.volume_up,
      };

  /// Position of this slot's icon within the paper-doll box as a fraction
  /// of the box dimensions (dx = left 0→right 1, dy = top 0→bottom 1).
  ///
  /// These are designed to be overlaid on a graphic later — adjust freely
  /// without touching any other code.
  Offset get paperDollOffset => switch (this) {
        CosmeticSlotType.scenery => const Offset(0.50, 0.10),
        CosmeticSlotType.uiSounds => const Offset(0.18, 0.35),
        CosmeticSlotType.moveEffect => const Offset(0.82, 0.35),
        CosmeticSlotType.masterPiece => const Offset(0.50, 0.28),
        CosmeticSlotType.studentPiece => const Offset(0.50, 0.47),
        CosmeticSlotType.throne => const Offset(0.50, 0.63),
        CosmeticSlotType.cardBack => const Offset(0.18, 0.72),
        CosmeticSlotType.board => const Offset(0.50, 0.82),
      };
}
