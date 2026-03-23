import 'package:flutter/material.dart';

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

  const CardDefinition({
    required this.id,
    required this.name,
    required this.moves,
    required this.stampColor,
  });

  @override
  bool operator ==(Object other) => other is CardDefinition && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}
