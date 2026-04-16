import 'package:flutter/material.dart';

import '../animations/card_animation_styles.dart';

/// A movement offset from the current player's perspective.
/// [dy] > 0 = forward (toward opponent). [dx] > 0 = right.
class CardMove {
  final int dx;
  final int dy;
  const CardMove(this.dx, this.dy);
}

class CardDefinition {
  final String id;
  final String name;
  final List<CardMove> moves;
  final Color stampColor;

  /// How this card flies out of the hand when a move is confirmed.
  final CardPlayStyle playStyle;

  /// The effect applied to the moving piece after a move with this card.
  final PieceMoveEffect moveEffect;

  const CardDefinition({
    required this.id,
    required this.name,
    required this.moves,
    required this.stampColor,
    this.playStyle = CardPlayStyle.lunge,
    this.moveEffect = PieceMoveEffect.glide,
  });

  @override
  bool operator ==(Object other) => other is CardDefinition && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}
