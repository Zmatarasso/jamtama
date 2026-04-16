import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game_logic.dart';
import '../models/piece.dart';
import '../models/round_state.dart';
import '../providers/match_provider.dart';

/// Plays a random legal move for the current player (Blue in tutorial).
/// Call this after the human's turn when the tutorial bot should act.
void botMove(WidgetRef ref) {
  final match = ref.read(matchProvider);
  final round = match.round;
  if (round == null || round.phase != RoundPhase.playing) return;
  if (round.currentTurn != Player.blue) return;

  final rng = Random();
  final hand = round.blueHand;
  final ownPieces =
      round.pieces.where((p) => p.player == Player.blue).toList()..shuffle(rng);

  // Try every piece+card combo until we find a legal move.
  for (final piece in ownPieces) {
    final shuffledHand = List.of(hand)..shuffle(rng);
    for (final card in shuffledHand) {
      final moves = computeValidMoves(piece, card, round.pieces);
      if (moves.isNotEmpty) {
        final target = moves[rng.nextInt(moves.length)];
        final notifier = ref.read(matchProvider.notifier);
        notifier.selectCard(card);
        notifier.selectPiece(piece);
        notifier.executeMove(row: target.row, col: target.col);
        return;
      }
    }
  }
  // No legal move — extremely rare, but skip if it happens.
}
