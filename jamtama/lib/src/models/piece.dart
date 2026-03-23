enum PieceType { master, student }

enum Player { red, blue }

class Piece {
  final PieceType type;
  final Player player;
  final int row;
  final int col;

  const Piece({
    required this.type,
    required this.player,
    required this.row,
    required this.col,
  });

  Piece copyWith({int? row, int? col}) => Piece(
        type: type,
        player: player,
        row: row ?? this.row,
        col: col ?? this.col,
      );

  @override
  bool operator ==(Object other) =>
      other is Piece &&
      other.type == type &&
      other.player == player &&
      other.row == row &&
      other.col == col;

  @override
  int get hashCode => Object.hash(type, player, row, col);

  @override
  String toString() => '$player $type at ($row, $col)';
}
