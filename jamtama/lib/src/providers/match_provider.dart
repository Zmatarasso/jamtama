import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cosmetics/providers/cosmetic_loadout_provider.dart';
import '../data/card_definitions.dart';
import '../game_logic.dart';
import '../models/card.dart';
import '../models/deck.dart';
import '../models/match_state.dart';
import '../models/opponent.dart';
import '../models/piece.dart';
import '../models/round_state.dart';
import '../models/saved_deck.dart';
import '../services/multiplayer_service.dart';

class MatchNotifier extends Notifier<MatchState> {
  Timer? _matchmakingTimer;
  String? _currentQueueId;
  Opponent? _currentOpponent;

  /// Last-generated AI-fallback opponent. Exposed so UI (game screen, round
  /// over dialog) can show the opposing name/cosmetics.
  Opponent? get currentOpponent => _currentOpponent;

  @override
  MatchState build() {
    ref.onDispose(() {
      _matchmakingTimer?.cancel();
    });
    return MatchState(
      phase: MatchPhase.menu,
      redDeck: redDefaultDeck,
      blueDeck: blueDefaultDeck,
      redRemaining: List.of(redDefaultDeck.cards),
      blueRemaining: List.of(blueDefaultDeck.cards),
    );
  }

  void startLocalMatch() {
    state = state.copyWith(
      phase: MatchPhase.deckSelection,
      gameMode: GameMode.local,
    );
  }

  /// Skips deck selection and drafting — jumps straight into a playable round
  /// using random cards from the default decks. Useful for quick testing.
  void startTestMatch() {
    final rng = Random();
    final redCards = List.of(redDefaultDeck.cards)..shuffle(rng);
    final blueCards = List.of(blueDefaultDeck.cards)..shuffle(rng);
    state = state.copyWith(
      redDeck: redDefaultDeck,
      blueDeck: blueDefaultDeck,
      redRemaining: redCards.skip(2).toList(),
      blueRemaining: blueCards.skip(2).toList(),
      redHand: redCards.take(2).toList(),
      blueHand: blueCards.take(2).toList(),
      gameMode: GameMode.ai,
      phase: MatchPhase.playing,
    );
    _startRound();
  }

  // ---------------------------------------------------------------------------
  // Deck selection
  // ---------------------------------------------------------------------------

  void selectDeck(Player player, SavedDeck deck) {
    final d = Deck(cards: deck.slots.whereType<CardDefinition>().toList());
    if (player == Player.red) {
      state = state.copyWith(
        redDeckId: deck.id,
        redDeck: d,
        redRemaining: List.of(d.cards),
      );
    } else {
      state = state.copyWith(
        blueDeckId: deck.id,
        blueDeck: d,
        blueRemaining: List.of(d.cards),
      );
    }
  }

  void confirmDeckSelection() {
    // Guard is enforced in the UI (Begin Match button disabled until both
    // players have selected a deck).  No hard guard here so test helpers
    // can drive the draft flow without needing SavedDeck objects.
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
      final newRemaining = [
        ...state.redRemaining.where((c) => !state.redDrafted.contains(c)),
        if (returned != null) returned,
      ];
      state = state.copyWith(
        redRemaining: newRemaining,
        redHand: selected,
      );
      if (state.gameMode != GameMode.local) {
        // AI / net: auto-confirm Blue's draft immediately.
        // The draftingBlue phase is never entered — no draft screen shown.
        _drawFor(Player.blue);
        _autoConfirmBlue();
      } else {
        // Local 2-player: show the draft screen for blue.
        _drawFor(Player.blue);
      }
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

  /// Randomly pick 2 of blue's drafted cards and start the round.
  /// Called for [GameMode.ai] and [GameMode.net] — never shows the draft screen for Blue.
  void _autoConfirmBlue() {
    final drawn = state.blueDrafted;
    final shuffled = List.of(drawn)..shuffle(Random());
    final pick = shuffled.take(2).toList();
    final returned = drawn.firstWhereOrNull((c) => !pick.contains(c));
    final newRemaining = [
      ...state.blueRemaining.where((c) => !drawn.contains(c)),
      if (returned != null) returned,
    ];
    state = state.copyWith(
      blueRemaining: newRemaining,
      blueHand: pick,
      phase: MatchPhase.playing,
    );
    _startRound();
  }

  // ---------------------------------------------------------------------------
  // Round setup
  // ---------------------------------------------------------------------------

  void _startRound() {
    // Community card: carry forward the match-level tableCard when available
    // (rounds 2+). On round 1, pick randomly from cards not in either hand.
    final CardDefinition community;
    if (state.tableCard != null) {
      community = state.tableCard!;
    } else {
      final handIds = {
        ...state.redHand.map((c) => c.id),
        ...state.blueHand.map((c) => c.id),
      };
      final pool = allCards.where((c) => !handIds.contains(c.id)).toList();
      final communityPool = pool.isNotEmpty ? pool : List.of(allCards);
      communityPool.shuffle(Random());
      community = communityPool.first;
    }

    state = state.copyWith(
      phase: MatchPhase.playing,
      tableCard: community, // ensure match-level is in sync
      round: RoundState(
        roundNumber: state.currentRound,
        phase: RoundPhase.playing,
        pieces: _initialPieces(),
        redHand: List.of(state.redHand),
        blueHand: List.of(state.blueHand),
        communityCard: community,
        // Loser of the previous round goes first. Round 1 defaults to Red.
        currentTurn: state.round?.winner == Player.red
            ? Player.blue
            : Player.red,
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
        ? computeValidMoves(round.selectedPiece!, newPending, round.pieces)
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
        ? computeValidMoves(newSelected, round.pendingCard!, round.pieces)
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

    // Compute new match-level state in the same update so listeners see a
    // fully consistent snapshot (no two-step race between round and match).
    final newRedWins  = winner == Player.red  ? state.redWins  + 1 : state.redWins;
    final newBlueWins = winner == Player.blue ? state.blueWins + 1 : state.blueWins;
    final isMatchOver = winner != null && (newRedWins >= 2 || newBlueWins >= 2);

    state = state.copyWith(
      // Match-level fields updated atomically together with round state.
      phase: isMatchOver ? MatchPhase.matchOver : state.phase,
      // usedCard is now on the table; keep match-level tableCard in sync so
      // it's available to display during the next draft phase.
      tableCard: usedCard,
      redWins: newRedWins,
      blueWins: newBlueWins,
      currentRound: (winner != null && !isMatchOver)
          ? state.currentRound + 1
          : state.currentRound,
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
  }

  /// Advance from a finished round back to drafting for the next round.
  void startNextRound() {
    state = state.copyWith(phase: MatchPhase.draftingRed);
    _drawFor(Player.red);
  }

  /// Return to the main menu.
  void returnToMenu() {
    _matchmakingTimer?.cancel();
    _currentQueueId = null;
    _currentOpponent = null;
    state = build();
  }

  // ---------------------------------------------------------------------------
  // Matchmaking (v1: enqueue → 15s timeout → AI fallback)
  // ---------------------------------------------------------------------------

  /// Called from "Find Online Match" → the [MatchmakingScreen] drives the
  /// timer. Enqueues the player and sets up the fallback timer.
  Future<void> startNetworkMatch() async {
    final multiplayer = ref.read(multiplayerServiceProvider);
    final cosmetics = _currentCosmeticPayload();

    try {
      _currentQueueId =
          await multiplayer.enqueue(cosmeticLoadout: cosmetics);
    } catch (_) {
      // Offline / rules reject — fall back to AI immediately.
      _fallbackToAi(cosmetics);
      return;
    }

    _matchmakingTimer?.cancel();
    _matchmakingTimer = Timer(const Duration(seconds: 15), () {
      _fallbackToAi(cosmetics);
    });
  }

  /// Cancel button handler — aborts the search and returns to menu phase.
  void cancelMatchmaking() {
    _matchmakingTimer?.cancel();
    _matchmakingTimer = null;
    final id = _currentQueueId;
    if (id != null) {
      ref.read(multiplayerServiceProvider).dequeue(id);
      _currentQueueId = null;
    }
    _currentOpponent = null;
    state = state.copyWith(phase: MatchPhase.menu);
  }

  void _fallbackToAi(Map<String, dynamic> playerCosmetics) {
    _matchmakingTimer?.cancel();
    _matchmakingTimer = null;
    final id = _currentQueueId;
    if (id != null) {
      ref.read(multiplayerServiceProvider).dequeue(id);
      _currentQueueId = null;
    }

    _currentOpponent = Opponent(
      Opponent.generateName(),
      Map<String, dynamic>.from(playerCosmetics),
    );

    // Switch into the AI path. startTestMatch bypasses deck selection and
    // drafting, which matches "opponent found, jump into the game".
    startTestMatch();
  }

  /// Serialize the equipped loadout IDs for the matchmaking queue payload.
  Map<String, dynamic> _currentCosmeticPayload() {
    final l = ref.read(cosmeticLoadoutProvider);
    return {
      'profilePictureId': l.profilePicture.id,
      'masterPieceId': l.masterPiece.id,
      'studentPieceId': l.studentPiece.id,
      'throneId': l.throne.id,
      'boardId': l.board.id,
      'sceneryId': l.scenery.id,
      'cardBackId': l.cardBack.id,
      'moveEffectId': l.moveEffect.id,
      'soundPackId': l.soundPack.id,
    };
  }

  // Move computation delegated to game_logic.dart for testability.
}

final matchProvider =
    NotifierProvider<MatchNotifier, MatchState>(MatchNotifier.new);
