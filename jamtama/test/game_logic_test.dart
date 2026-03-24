import 'package:flutter_test/flutter_test.dart';
import 'package:jamtama/src/data/card_definitions.dart';
import 'package:jamtama/src/game_logic.dart';
import 'package:jamtama/src/models/piece.dart';
import 'package:jamtama/src/models/round_state.dart';

// Convenience: build a list of positions from (row, col) pairs.
List<BoardPos> pos(List<(int, int)> pairs) =>
    pairs.map((p) => BoardPos(p.$1, p.$2)).toList();

void main() {
  // Empty board — no blocking pieces other than the one being moved.
  const empty = <Piece>[];

  group('computeValidMoves — boar (forward, left, right)', () {
    test('Red piece in open centre returns all 3 moves', () {
      const piece = Piece(type: PieceType.student, player: Player.red, row: 2, col: 2);
      final moves = computeValidMoves(piece, boar, empty);
      expect(moves, containsAll(pos([(3, 2), (2, 1), (2, 3)])));
      expect(moves.length, 3);
    });

    test('Blue piece forward direction is opposite to Red', () {
      // Blue at (2,2): forward = row-1, left/right flip too.
      const piece = Piece(type: PieceType.student, player: Player.blue, row: 2, col: 2);
      final moves = computeValidMoves(piece, boar, empty);
      expect(moves, containsAll(pos([(1, 2), (2, 3), (2, 1)])));
      expect(moves.length, 3);
    });

    test('Red piece at top-left corner — off-board moves excluded', () {
      const piece = Piece(type: PieceType.student, player: Player.red, row: 0, col: 0);
      final moves = computeValidMoves(piece, boar, empty);
      // forward (1,0) valid; left (0,-1) off-board; right (0,1) valid.
      expect(moves, containsAll(pos([(1, 0), (0, 1)])));
      expect(moves.length, 2);
    });

    test('Red piece at bottom-right corner — only left valid', () {
      const piece = Piece(type: PieceType.student, player: Player.red, row: 4, col: 4);
      final moves = computeValidMoves(piece, boar, empty);
      // forward (5,4) off-board; left (4,3) valid; right (4,5) off-board.
      expect(moves, equals(pos([(4, 3)])));
    });
  });

  group('computeValidMoves — blocking', () {
    test('Cannot land on own piece', () {
      const piece = Piece(type: PieceType.student, player: Player.red, row: 2, col: 2);
      const blocker = Piece(type: PieceType.student, player: Player.red, row: 3, col: 2);
      final moves = computeValidMoves(piece, boar, [piece, blocker]);
      expect(moves, isNot(contains(BoardPos(3, 2))));
    });

    test('Can land on opponent piece (capture)', () {
      const piece = Piece(type: PieceType.student, player: Player.red, row: 2, col: 2);
      const target = Piece(type: PieceType.master, player: Player.blue, row: 3, col: 2);
      final moves = computeValidMoves(piece, boar, [piece, target]);
      expect(moves, contains(BoardPos(3, 2)));
    });

    test('All moves blocked by own pieces returns empty', () {
      const piece = Piece(type: PieceType.student, player: Player.red, row: 2, col: 2);
      final blockers = [
        const Piece(type: PieceType.student, player: Player.red, row: 3, col: 2),
        const Piece(type: PieceType.student, player: Player.red, row: 2, col: 1),
        const Piece(type: PieceType.student, player: Player.red, row: 2, col: 3),
      ];
      final moves = computeValidMoves(piece, boar, [piece, ...blockers]);
      expect(moves, isEmpty);
    });
  });

  group('computeValidMoves — monkey (all 4 diagonals)', () {
    test('Centre piece has 4 diagonal moves', () {
      const piece = Piece(type: PieceType.student, player: Player.red, row: 2, col: 2);
      final moves = computeValidMoves(piece, monkey, empty);
      expect(moves, containsAll(pos([(3, 1), (3, 3), (1, 1), (1, 3)])));
      expect(moves.length, 4);
    });

    test('Blue monkey moves are the same squares (diagonals are symmetric)', () {
      const piece = Piece(type: PieceType.student, player: Player.blue, row: 2, col: 2);
      final moves = computeValidMoves(piece, monkey, empty);
      expect(moves, containsAll(pos([(3, 1), (3, 3), (1, 1), (1, 3)])));
      expect(moves.length, 4);
    });

    test('Corner piece has only 1 diagonal move', () {
      const piece = Piece(type: PieceType.student, player: Player.red, row: 0, col: 0);
      final moves = computeValidMoves(piece, monkey, empty);
      expect(moves, equals(pos([(1, 1)])));
    });
  });

  group('computeValidMoves — card mirroring (Red vs Blue)', () {
    // Ox: forward, right, backward.
    // Red forward=+row; Blue forward=-row. Right also flips for Blue.
    test('Red ox from (2,2): forward=(3,2), right=(2,3), back=(1,2)', () {
      const piece = Piece(type: PieceType.student, player: Player.red, row: 2, col: 2);
      final moves = computeValidMoves(piece, ox, empty);
      expect(moves, containsAll(pos([(3, 2), (2, 3), (1, 2)])));
      expect(moves.length, 3);
    });

    test('Blue ox from (2,2): forward=(1,2), right=(2,1), back=(3,2)', () {
      const piece = Piece(type: PieceType.student, player: Player.blue, row: 2, col: 2);
      final moves = computeValidMoves(piece, ox, empty);
      expect(moves, containsAll(pos([(1, 2), (2, 1), (3, 2)])));
      expect(moves.length, 3);
    });

    // Horse: forward, left, backward.
    test('Red horse and Blue horse are mirror images', () {
      const redPiece = Piece(type: PieceType.student, player: Player.red, row: 2, col: 2);
      const bluePiece = Piece(type: PieceType.student, player: Player.blue, row: 2, col: 2);
      final redMoves = computeValidMoves(redPiece, horse, empty);
      final blueMoves = computeValidMoves(bluePiece, horse, empty);
      // Red: fwd=(3,2), left=(2,1), back=(1,2).
      // Blue: fwd=(1,2), left=(2,3), back=(3,2).
      expect(redMoves, containsAll(pos([(3, 2), (2, 1), (1, 2)])));
      expect(blueMoves, containsAll(pos([(1, 2), (2, 3), (3, 2)])));
    });
  });

  group('computeValidMoves — elephant (left-fwd, right-fwd, left, right)', () {
    test('Red elephant from centre has 4 moves', () {
      const piece = Piece(type: PieceType.student, player: Player.red, row: 2, col: 2);
      final moves = computeValidMoves(piece, elephant, empty);
      expect(moves, containsAll(pos([(3, 1), (3, 3), (2, 1), (2, 3)])));
      expect(moves.length, 4);
    });
  });

  group('computeValidMoves — board edges', () {
    test('No move goes outside the 5×5 board', () {
      // Try every piece position to ensure no BoardPos has row/col outside 0-4.
      for (var r = 0; r <= 4; r++) {
        for (var c = 0; c <= 4; c++) {
          final piece = Piece(type: PieceType.student, player: Player.red, row: r, col: c);
          for (final card in allCards) {
            final moves = computeValidMoves(piece, card, empty);
            for (final m in moves) {
              expect(m.row, inInclusiveRange(0, 4),
                  reason: '${card.name} at ($r,$c) produced out-of-range row ${m.row}');
              expect(m.col, inInclusiveRange(0, 4),
                  reason: '${card.name} at ($r,$c) produced out-of-range col ${m.col}');
            }
          }
        }
      }
    });
  });
}
