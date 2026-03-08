enum PieceType { master, student }

enum Player { red, blue }

class Piece {
  final PieceType type;
  final Player player;
  int row, col;  // Mutable position.

  Piece({
    required this.type,
    required this.player,
    required this.row,
    required this.col,
  });

  @override
  String toString() => '$player $type at ($row, $col)';
}