import 'package:collection/collection.dart';

import 'models/card.dart';
import 'models/piece.dart';
import 'models/round_state.dart';

/// Returns all squares a [piece] can legally move to using [card],
/// given the current [pieces] on the board.
///
/// Move offsets are stored from the current player's perspective
/// (dy > 0 = forward, dx > 0 = right). Blue's card is rotated 180°
/// so both axes are negated.
List<BoardPos> computeValidMoves(
  Piece piece,
  CardDefinition card,
  List<Piece> pieces,
) {
  final isRed = piece.player == Player.red;
  final result = <BoardPos>[];

  for (final move in card.moves) {
    final dr = isRed ? move.dy : -move.dy;
    final dc = isRed ? move.dx : -move.dx;
    final newRow = piece.row + dr;
    final newCol = piece.col + dc;

    if (newRow < 0 || newRow > 4 || newCol < 0 || newCol > 4) continue;

    final target =
        pieces.firstWhereOrNull((p) => p.row == newRow && p.col == newCol);
    if (target?.player == piece.player) continue; // can't capture own piece

    result.add(BoardPos(newRow, newCol));
  }

  return result;
}
