import 'dart:ui';  // For Offset.

class MoveCard {
  final String name;
  final List<Offset> moves;

  MoveCard({required this.name, required this.moves});

  @override
  String toString() => '$name: ${moves.length} moves';
}