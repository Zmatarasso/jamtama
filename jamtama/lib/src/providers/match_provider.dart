import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/card_definitions.dart';
import '../models/card.dart';
import '../models/match_state.dart';
import '../models/piece.dart';
import '../models/round_state.dart';

class MatchNotifier extends Notifier<MatchState> {
  @override
  MatchState build() => MatchState(
        phase: MatchPhase.menu,
        redDeck: redDefaultDeck,
        blueDeck: blueDefaultDeck,
        redRemaining: List.of(redDefaultDeck.cards),
        blueRemaining: List.of(blueDefaultDeck.cards),
      );

  void startLocalMatch() {
    state = state.copyWith(phase: MatchPhase.deckSelection);
  }

  // ---------------------------------------------------------------------------
  // Deck selection
  // ---------------------------------------------------------------------------

  void confirmDeckSelection() {
    state = state.copyWith(phase: MatchPhase.draftingRed);
    _drawFor(Player.red);
  }

  // ---------------------------------------------------------------------------
  // Draft phase
  // ---------------------------------------------------------------------------

  void _drawFor(Player player) {
    final remaining =
        player == Player.red ? state.redRemaining : state.blueRemaining;
    final shuffled = List.of(remaining)..shuffle(Random());
    final drawn = shuffled.take(min(3, shuffled.length)).toList();

    if (player == Player.red) {
      state = state.copyWith(
        phase: MatchPhase.draftingRed,
        redDrafted: drawn,
      );
    } else {
      state = state.copyWith(
        phase: MatchPhase.draftingBlue,
        blueDrafted: drawn,
      );
    }
  }

  /// Called when a player confirms their 2-card pick from the draft.
  void confirmDraft(Player player, List<CardDefinition> selected) {
    assert(selected.length == 2);
    final drafted =
        player == Player.red ? state.redDrafted : state.blueDrafted;

    // The unselected card returns to the deck pool.
    final returned =
        drafted.firstWhereOrNull((c) => !selected.contains(c));

    if (player == Player.red) {
      // Remove all drafted cards from remaining, then put the returned one back.
      final newRemaining = [
        ...state.redRemaining.where((c) => !state.redDrafted.contains(c)),
        if (returned != null) returned,
      ];
      state = state.copyWith(
        redRemaining: newRemaining,
        redHand: selected,
      );
      // Now draw for blue.
      _drawFor(Player.blue);
    } else {
      final newRemaining = [
        ...state.blueRemaining.where((c) => !state.blueDrafted.contains(c)),
        if (returned != null) returned,
      ];
      state = state.copyWith(
        blueRemaining: newRemaining,
        blueHand: selected,
        phase: MatchPhase.playing,
      );
      _startRound();
    }
  }

  // ---------------------------------------------------------------------------
  // Round setup
  // ---------------------------------------------------------------------------

  void _startRound() {
    // Community card: prefer a card not held by either player.
    final handIds = {
      ...state.redHand.map((c) => c.id),
      ...state.blueHand.map((c) => c.id),
    };
    final pool =
        allCards.where((c) => !handIds.contains(c.id)).toList();
    final communityPool = pool.isNotEmpty ? pool : List.of(allCards);
    communityPool.shuffle(Random());
    final community = communityPool.first;

    state = state.copyWith(
      phase: MatchPhase.playing,
      round: RoundState(
        roundNumber: state.currentRound,
        phase: RoundPhase.playing,
        pieces: _initialPieces(),
        redHand: List.of(state.redHand),
        blueHand: List.of(state.blueHand),
        communityCard: community,
        currentTurn: Player.red,
      ),
    );
  }

  static List<Piece> _initialPieces() => const [
        Piece(type: PieceType.master, player: Player.red, row: 0, col: 2),
        Piece(type: PieceType.student, player: Player.red, row: 0, col: 0),
        Piece(type: PieceType.student, player: Player.red, row: 0, col: 1),
        Piece(type: PieceType.student, player: Player.red, row: 0, col: 3),
        Piece(type: PieceType.student, player: Player.red, row: 0, col: 4),
        Piece(type: PieceType.master, player: Player.blue, row: 4, col: 2),
        Piece(type: PieceType.student, player: Player.blue, row: 4, col: 0),
        Piece(type: PieceType.student, player: Player.blue, row: 4, col: 1),
        Piece(type: PieceType.student, player: Player.blue, row: 4, col: 3),
        Piece(type: PieceType.student, player: Player.blue, row: 4, col: 4),
      ];

  // ---------------------------------------------------------------------------
  // In-round actions
  // ---------------------------------------------------------------------------

  /// Select/deselect a card as the pending move card.
  void selectCard(CardDefinition card) {
    final round = state.round;
    if (round == null || round.phase != RoundPhase.playing) return;

    final hand = round.currentTurn == Player.red ? round.redHand : round.blueHand;
    if (!hand.contains(card)) return;

    final newPending = round.pendingCard == card ? null : card;
    final validMoves = (newPending != null && round.selectedPiece != null)
        ? _computeValidMoves(round.selectedPiece!, newPending, round.pieces)
        : <BoardPos>[];

    state = state.copyWith(
      round: round.copyWith(
        pendingCard: newPending,
        validMoves: validMoves,
      ),
    );
  }

  /// Select/deselect one of the current player's pieces.
  void selectPiece(Piece piece) {
    final round = state.round;
    if (round == null || round.phase != RoundPhase.playing) return;
    if (piece.player != round.currentTurn) return;

    final newSelected = round.selectedPiece == piece ? null : piece;
    final validMoves = (newSelected != null && round.pendingCard != null)
        ? _computeValidMoves(newSelected, round.pendingCard!, round.pieces)
        : <BoardPos>[];

    state = state.copyWith(
      round: round.copyWith(
        selectedPiece: newSelected,
        validMoves: validMoves,
      ),
    );
  }

  /// Commit the move — called when the player drops a piece on a valid square.
  void executeMove({required int row, required int col}) {
    final round = state.round;
    if (round == null) return;
    if (round.pendingCard == null || round.selectedPiece == null) return;
    if (!round.validMoves.contains(BoardPos(row, col))) return;

    final moving = round.selectedPiece!;
    final usedCard = round.pendingCard!;

    // Remove captured piece (if any) and move the piece.
    final captured = round.pieces
        .firstWhereOrNull((p) => p.row == row && p.col == col);
    final newPieces = round.pieces
        .where((p) => p != captured && p != moving)
        .toList()
      ..add(moving.copyWith(row: row, col: col));

    // Card swap: used card → community slot, old community → player's hand.
    final oldCommunity = round.communityCard;
    final newRedHand = round.redHand
        .map((c) =>
            (round.currentTurn == Player.red && c == usedCard) ? oldCommunity : c)
        .toList();
    final newBlueHand = round.blueHand
        .map((c) =>
            (round.currentTurn == Player.blue && c == usedCard) ? oldCommunity : c)
        .toList();

    // Check win conditions.
    Player? winner;
    WinCondition? condition;

    if (captured?.type == PieceType.master) {
      // Way of the Stone: captured opponent's master.
      winner = round.currentTurn;
      condition = WinCondition.wayOfStone;
    } else if (moving.type == PieceType.master) {
      // Way of the Stream: own master steps onto opponent's temple.
      final temple = round.currentTurn == Player.red
          ? const BoardPos(4, 2)
          : const BoardPos(0, 2);
      if (BoardPos(row, col) == temple) {
        winner = round.currentTurn;
        condition = WinCondition.wayOfStream;
      }
    }

    state = state.copyWith(
      round: round.copyWith(
        pieces: newPieces,
        redHand: newRedHand,
        blueHand: newBlueHand,
        communityCard: usedCard,
        currentTurn:
            round.currentTurn == Player.red ? Player.blue : Player.red,
        pendingCard: null,
        selectedPiece: null,
        validMoves: [],
        winner: winner,
        winCondition: condition,
        phase: winner != null ? RoundPhase.over : RoundPhase.playing,
      ),
    );

    if (winner != null) _handleRoundOver(winner);
  }

  void _handleRoundOver(Player winner) {
    final newRedWins =
        winner == Player.red ? state.redWins + 1 : state.redWins;
    final newBlueWins =
        winner == Player.blue ? state.blueWins + 1 : state.blueWins;

    if (newRedWins >= 2 || newBlueWins >= 2) {
      state = state.copyWith(
        redWins: newRedWins,
        blueWins: newBlueWins,
        phase: MatchPhase.matchOver,
      );
    } else {
      state = state.copyWith(
        redWins: newRedWins,
        blueWins: newBlueWins,
        currentRound: state.currentRound + 1,
      );
    }
  }

  /// Advance from a finished round back to drafting for the next round.
  void startNextRound() {
    state = state.copyWith(phase: MatchPhase.draftingRed);
    _drawFor(Player.red);
  }

  /// Return to the main menu.
  void returnToMenu() {
    state = build();
  }

  // ---------------------------------------------------------------------------
  // Move computation
  // ---------------------------------------------------------------------------

  static List<BoardPos> _computeValidMoves(
    Piece piece,
    CardDefinition card,
    List<Piece> pieces,
  ) {
    final isRed = piece.player == Player.red;
    final result = <BoardPos>[];

    for (final move in card.moves) {
      // Red: forward = +row, left = -col.
      // Blue: card is rotated 180° — both axes flip.
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
}

final matchProvider =
    NotifierProvider<MatchNotifier, MatchState>(MatchNotifier.new);
