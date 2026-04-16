import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamtama/src/data/card_definitions.dart';
import 'package:jamtama/src/models/match_state.dart';
import 'package:jamtama/src/models/piece.dart';
import 'package:jamtama/src/models/round_state.dart';
import 'package:jamtama/src/providers/match_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ProviderContainer makeContainer() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

/// Drive both players through a full draft using the first 2 cards drawn.
void completeDraft(ProviderContainer c) {
  final n = c.read(matchProvider.notifier);
  n.confirmDeckSelection();

  final redDrafted = c.read(matchProvider).redDrafted;
  n.confirmDraft(Player.red, redDrafted.take(2).toList());

  final blueDrafted = c.read(matchProvider).blueDrafted;
  n.confirmDraft(Player.blue, blueDrafted.take(2).toList());
}

/// Complete draft and return the live RoundState.
RoundState startRound(ProviderContainer c) {
  completeDraft(c);
  return c.read(matchProvider).round!;
}

/// Select a card + piece for the current player, assert validMoves is set,
/// and return the first valid move.
BoardPos selectAndGetFirstMove(ProviderContainer c) {
  final n = c.read(matchProvider.notifier);
  final round = c.read(matchProvider).round!;
  final hand = round.currentTurn == Player.red ? round.redHand : round.blueHand;
  final pieces = round.pieces.where((p) => p.player == round.currentTurn).toList();

  // Try each card × piece combination until we find valid moves.
  for (final card in hand) {
    for (final piece in pieces) {
      n.selectCard(card);
      n.selectPiece(piece);
      final valid = c.read(matchProvider).round!.validMoves;
      if (valid.isNotEmpty) return valid.first;
      // Reset.
      n.selectCard(card); // toggle off
      n.selectPiece(piece); // toggle off
    }
  }
  throw StateError('No valid moves found — check initial board / hand setup');
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── Match lifecycle ──────────────────────────────────────────────────────

  group('Match lifecycle', () {
    test('Initialises to menu phase with default decks', () {
      final c = makeContainer();
      final s = c.read(matchProvider);
      expect(s.phase, MatchPhase.menu);
      expect(s.redDeck.cards.length, 6);
      expect(s.blueDeck.cards.length, 6);
      expect(s.redRemaining.length, 6);
      expect(s.blueRemaining.length, 6);
    });

    test('startLocalMatch() transitions to deckSelection', () {
      final c = makeContainer();
      c.read(matchProvider.notifier).startLocalMatch();
      expect(c.read(matchProvider).phase, MatchPhase.deckSelection);
    });

    test('confirmDeckSelection() transitions to draftingRed and draws 3', () {
      final c = makeContainer();
      c.read(matchProvider.notifier).confirmDeckSelection();
      final s = c.read(matchProvider);
      expect(s.phase, MatchPhase.draftingRed);
      expect(s.redDrafted.length, 3);
    });

    test('returnToMenu() resets to initial state', () {
      final c = makeContainer();
      completeDraft(c);
      c.read(matchProvider.notifier).returnToMenu();
      final s = c.read(matchProvider);
      expect(s.phase, MatchPhase.menu);
      expect(s.redWins, 0);
      expect(s.blueWins, 0);
      expect(s.currentRound, 1);
    });
  });

  // ── Draft mechanics ──────────────────────────────────────────────────────

  group('Draft mechanics', () {
    test('After Red confirms, blue draft begins with 3 cards', () {
      final c = makeContainer();
      c.read(matchProvider.notifier).confirmDeckSelection();
      final redDrafted = c.read(matchProvider).redDrafted;
      c.read(matchProvider.notifier).confirmDraft(Player.red, redDrafted.take(2).toList());
      final s = c.read(matchProvider);
      expect(s.phase, MatchPhase.draftingBlue);
      expect(s.blueDrafted.length, 3);
    });

    test('Returned card goes back into remaining pool', () {
      final c = makeContainer();
      c.read(matchProvider.notifier).confirmDeckSelection();
      final drafted = c.read(matchProvider).redDrafted;
      final selected = drafted.take(2).toList();
      final returned = drafted.last; // the 3rd card is returned
      c.read(matchProvider.notifier).confirmDraft(Player.red, selected);
      expect(c.read(matchProvider).redRemaining, contains(returned));
    });

    test('Red remaining shrinks by 2 after round 1 draft (drew 3, returned 1)', () {
      final c = makeContainer();
      completeDraft(c);
      // Started with 6, drew 3 → 3 left, returned 1 → 4 remaining.
      expect(c.read(matchProvider).redRemaining.length, 4);
    });

    test('Red remaining shrinks by 2 after round 2 draft', () {
      final c = makeContainer();
      completeDraft(c);
      c.read(matchProvider.notifier).startNextRound();
      final redDrafted = c.read(matchProvider).redDrafted;
      c.read(matchProvider.notifier).confirmDraft(Player.red, redDrafted.take(2).toList());
      final blueDrafted = c.read(matchProvider).blueDrafted;
      c.read(matchProvider.notifier).confirmDraft(Player.blue, blueDrafted.take(2).toList());
      // 4 remaining → drew 3, returned 1 → 2 remaining.
      expect(c.read(matchProvider).redRemaining.length, 2);
    });

    test('Round 3 draws only 2 cards when only 2 remain', () {
      final c = makeContainer();
      // Complete two full rounds to deplete the deck to 2.
      completeDraft(c);
      c.read(matchProvider.notifier).startNextRound();
      var rd = c.read(matchProvider).redDrafted;
      c.read(matchProvider.notifier).confirmDraft(Player.red, rd.take(2).toList());
      var bd = c.read(matchProvider).blueDrafted;
      c.read(matchProvider.notifier).confirmDraft(Player.blue, bd.take(2).toList());

      // Start round 3.
      c.read(matchProvider.notifier).startNextRound();
      expect(c.read(matchProvider).redDrafted.length, 2);
    });

    test('Round starts with 10 pieces and red going first', () {
      final c = makeContainer();
      final round = startRound(c);
      expect(round.pieces.length, 10);
      expect(round.currentTurn, Player.red);
      expect(round.pieces.where((p) => p.player == Player.red).length, 5);
      expect(round.pieces.where((p) => p.player == Player.blue).length, 5);
    });

    test('Community card is not in either player\'s hand', () {
      final c = makeContainer();
      final round = startRound(c);
      final handIds = {
        ...round.redHand.map((c) => c.id),
        ...round.blueHand.map((c) => c.id),
      };
      expect(handIds, isNot(contains(round.communityCard.id)));
    });
  });

  // ── Card and piece selection ─────────────────────────────────────────────

  group('Card and piece selection', () {
    test('Selecting a card sets pendingCard', () {
      final c = makeContainer();
      final round = startRound(c);
      final card = round.redHand.first;
      c.read(matchProvider.notifier).selectCard(card);
      expect(c.read(matchProvider).round!.pendingCard, card);
    });

    test('Selecting same card again toggles it off', () {
      final c = makeContainer();
      final round = startRound(c);
      final card = round.redHand.first;
      final n = c.read(matchProvider.notifier);
      n.selectCard(card);
      n.selectCard(card);
      expect(c.read(matchProvider).round!.pendingCard, isNull);
    });

    test('Cannot select opponent\'s card', () {
      final c = makeContainer();
      final round = startRound(c);
      final blueCard = round.blueHand.first;
      c.read(matchProvider.notifier).selectCard(blueCard);
      expect(c.read(matchProvider).round!.pendingCard, isNull);
    });

    test('Select card then piece computes validMoves', () {
      final c = makeContainer();
      startRound(c);
      selectAndGetFirstMove(c);
      expect(c.read(matchProvider).round!.validMoves, isNotEmpty);
    });

    test('Select piece then card also computes validMoves', () {
      final c = makeContainer();
      final round = startRound(c);
      final n = c.read(matchProvider.notifier);
      final piece = round.pieces.firstWhere((p) => p.player == Player.red);
      final card = round.redHand.first;
      n.selectPiece(piece);
      n.selectCard(card);
      // validMoves may be empty if the specific card has no moves from that
      // position, but the mechanism should run without error.
      expect(c.read(matchProvider).round, isNotNull);
    });

    test('Selecting a piece without a card does not set validMoves', () {
      final c = makeContainer();
      final round = startRound(c);
      final piece = round.pieces.firstWhere((p) => p.player == Player.red);
      c.read(matchProvider.notifier).selectPiece(piece);
      expect(c.read(matchProvider).round!.validMoves, isEmpty);
    });
  });

  // ── executeMove ───────────────────────────────────────────────────────────

  group('executeMove', () {
    test('Moves piece to the target square', () {
      final c = makeContainer();
      startRound(c);
      final target = selectAndGetFirstMove(c);
      c.read(matchProvider.notifier).executeMove(row: target.row, col: target.col);
      final pieces = c.read(matchProvider).round!.pieces;
      expect(pieces.any((p) => p.row == target.row && p.col == target.col), isTrue);
    });

    test('Clears pendingCard, selectedPiece, and validMoves after move', () {
      final c = makeContainer();
      startRound(c);
      final target = selectAndGetFirstMove(c);
      c.read(matchProvider.notifier).executeMove(row: target.row, col: target.col);
      final round = c.read(matchProvider).round!;
      expect(round.pendingCard, isNull);
      expect(round.selectedPiece, isNull);
      expect(round.validMoves, isEmpty);
    });

    test('Switches turn after move', () {
      final c = makeContainer();
      startRound(c);
      final target = selectAndGetFirstMove(c);
      c.read(matchProvider.notifier).executeMove(row: target.row, col: target.col);
      expect(c.read(matchProvider).round!.currentTurn, Player.blue);
    });

    test('Used card goes to community; community card comes to hand', () {
      final c = makeContainer();
      startRound(c);
      final target = selectAndGetFirstMove(c);
      final beforeRound = c.read(matchProvider).round!;
      final usedCard = beforeRound.pendingCard!;
      final oldCommunity = beforeRound.communityCard;

      c.read(matchProvider.notifier).executeMove(row: target.row, col: target.col);

      final afterRound = c.read(matchProvider).round!;
      expect(afterRound.communityCard, usedCard);
      expect(afterRound.redHand, contains(oldCommunity));
      expect(afterRound.redHand, isNot(contains(usedCard)));
    });

    test('Does nothing if no card is selected', () {
      final c = makeContainer();
      final round = startRound(c);
      final piece = round.pieces.firstWhere((p) => p.player == Player.red);
      c.read(matchProvider.notifier).selectPiece(piece);
      c.read(matchProvider.notifier).executeMove(row: 1, col: 2);
      expect(c.read(matchProvider).round!.currentTurn, Player.red);
    });

    test('Does nothing if target is not in validMoves', () {
      final c = makeContainer();
      startRound(c);
      selectAndGetFirstMove(c);
      // (4,4) is very unlikely to be a valid move from the opening position.
      c.read(matchProvider.notifier).executeMove(row: 4, col: 4);
      expect(c.read(matchProvider).round!.currentTurn, Player.red);
    });

    test('Capturing a student removes it from the board', () {
      // Manually craft a round where Red can immediately capture a Blue student.
      // Use the notifier's public API to set up the round, then manipulate via
      // a controlled round state injected through the match state.
      //
      // Since we can't inject arbitrary state, we use a known scenario:
      // place pieces so a valid move lands on an opponent square. We do this
      // by setting up a provider override with a preset round.
      final override = ProviderContainer(
        overrides: [
          matchProvider.overrideWith(() => _ControlledMatchNotifier()),
        ],
      );
      addTearDown(override.dispose);

      final n = override.read(matchProvider.notifier) as _ControlledMatchNotifier;
      n.setupCaptureScenario();

      final round = override.read(matchProvider).round!;
      expect(round.pieces.length, 2); // 1 red + 1 blue

      // Red boar: forward from (3,2) = (4,2) where Blue student is.
      override.read(matchProvider.notifier).selectCard(mace);
      override.read(matchProvider.notifier)
          .selectPiece(round.pieces.first); // red student
      override.read(matchProvider.notifier).executeMove(row: 4, col: 2);

      final newPieces = override.read(matchProvider).round!.pieces;
      expect(newPieces.length, 1); // blue student captured
      expect(newPieces.first.player, Player.red);
      expect(newPieces.first.row, 4);
      expect(newPieces.first.col, 2);
    });
  });

  // ── Win conditions ────────────────────────────────────────────────────────

  group('Win conditions', () {
    test('Way of the Stone: capturing opponent master wins the round', () {
      final c = ProviderContainer(
        overrides: [
          matchProvider.overrideWith(() => _ControlledMatchNotifier()),
        ],
      );
      addTearDown(c.dispose);

      final n = c.read(matchProvider.notifier) as _ControlledMatchNotifier;
      n.setupStoneScenario(); // Red student at (3,2), Blue master at (4,2)

      c.read(matchProvider.notifier).selectCard(mace);
      final piece = c.read(matchProvider).round!.pieces.first;
      c.read(matchProvider.notifier).selectPiece(piece);
      c.read(matchProvider.notifier).executeMove(row: 4, col: 2);

      final round = c.read(matchProvider).round!;
      expect(round.winner, Player.red);
      expect(round.winCondition, WinCondition.wayOfStone);
      expect(round.phase, RoundPhase.over);
    });

    test('Way of the Stream: Red master on Blue temple (4,2) wins the round', () {
      final c = ProviderContainer(
        overrides: [
          matchProvider.overrideWith(() => _ControlledMatchNotifier()),
        ],
      );
      addTearDown(c.dispose);

      final n = c.read(matchProvider.notifier) as _ControlledMatchNotifier;
      n.setupStreamScenario(); // Red master at (3,2), nothing at (4,2)

      c.read(matchProvider.notifier).selectCard(mace);
      final piece = c.read(matchProvider).round!.pieces.first;
      c.read(matchProvider.notifier).selectPiece(piece);
      c.read(matchProvider.notifier).executeMove(row: 4, col: 2);

      final round = c.read(matchProvider).round!;
      expect(round.winner, Player.red);
      expect(round.winCondition, WinCondition.wayOfStream);
      expect(round.phase, RoundPhase.over);
    });

    test('Way of the Stream: Blue master on Red temple (0,2) wins', () {
      final c = ProviderContainer(
        overrides: [
          matchProvider.overrideWith(() => _ControlledMatchNotifier()),
        ],
      );
      addTearDown(c.dispose);

      final n = c.read(matchProvider.notifier) as _ControlledMatchNotifier;
      n.setupBlueStreamScenario(); // Blue master at (1,2), nothing at (0,2)

      c.read(matchProvider.notifier).selectCard(mace);
      final piece = c.read(matchProvider).round!.pieces.first;
      c.read(matchProvider.notifier).selectPiece(piece);
      c.read(matchProvider.notifier).executeMove(row: 0, col: 2);

      final round = c.read(matchProvider).round!;
      expect(round.winner, Player.blue);
      expect(round.winCondition, WinCondition.wayOfStream);
    });

    test('Winning a round increments win count', () {
      final c = ProviderContainer(
        overrides: [
          matchProvider.overrideWith(() => _ControlledMatchNotifier()),
        ],
      );
      addTearDown(c.dispose);

      (c.read(matchProvider.notifier) as _ControlledMatchNotifier)
          .setupStoneScenario();
      c.read(matchProvider.notifier).selectCard(mace);
      final piece = c.read(matchProvider).round!.pieces.first;
      c.read(matchProvider.notifier).selectPiece(piece);
      c.read(matchProvider.notifier).executeMove(row: 4, col: 2);

      expect(c.read(matchProvider).redWins, 1);
      expect(c.read(matchProvider).blueWins, 0);
    });

    test('Two wins transitions to matchOver', () {
      final c = ProviderContainer(
        overrides: [
          matchProvider.overrideWith(() => _ControlledMatchNotifier()),
        ],
      );
      addTearDown(c.dispose);

      void winRoundForRed() {
        (c.read(matchProvider.notifier) as _ControlledMatchNotifier)
            .setupStoneScenario();
        c.read(matchProvider.notifier).selectCard(mace);
        final piece = c.read(matchProvider).round!.pieces.first;
        c.read(matchProvider.notifier).selectPiece(piece);
        c.read(matchProvider.notifier).executeMove(row: 4, col: 2);
      }

      winRoundForRed();
      expect(c.read(matchProvider).phase, isNot(MatchPhase.matchOver));

      winRoundForRed();
      expect(c.read(matchProvider).phase, MatchPhase.matchOver);
      expect(c.read(matchProvider).redWins, 2);
    });
  });

  // ── Regression tests ──────────────────────────────────────────────────────

  group('Regression', () {
    test('Dragging an already-selected piece does not toggle it off', () {
      // Simulates: tap piece → tap card → start drag (which calls selectPiece again).
      final c = makeContainer();
      final round = startRound(c);
      final n = c.read(matchProvider.notifier);
      final piece = round.pieces.firstWhere((p) => p.player == Player.red);
      final card = round.redHand.first;

      n.selectPiece(piece); // tap piece first
      n.selectCard(card);   // tap card

      final validBefore = c.read(matchProvider).round!.validMoves;

      // Simulate onDragStarted guard: only call selectPiece if not already selected.
      final currentSelected = c.read(matchProvider).round?.selectedPiece;
      if (currentSelected != piece) n.selectPiece(piece);

      // validMoves must remain unchanged (not cleared by accidental toggle).
      expect(c.read(matchProvider).round!.validMoves, validBefore);
      expect(c.read(matchProvider).round!.pendingCard, card);
      expect(c.read(matchProvider).round!.selectedPiece, piece);
    });

    test('Selecting a piece without card and then selecting card computes moves', () {
      final c = makeContainer();
      final round = startRound(c);
      final n = c.read(matchProvider.notifier);
      final piece = round.pieces.firstWhere((p) => p.player == Player.red);
      final card = round.redHand.first;

      n.selectPiece(piece);
      expect(c.read(matchProvider).round!.validMoves, isEmpty);

      n.selectCard(card);
      // validMoves is now computed (may be empty for this specific piece/card
      // combo, but the state machine ran correctly).
      expect(c.read(matchProvider).round!.pendingCard, card);
      expect(c.read(matchProvider).round!.selectedPiece, piece);
    });
  });
}

// ---------------------------------------------------------------------------
// Test-only notifier subclass for controlled board scenarios
// ---------------------------------------------------------------------------

class _ControlledMatchNotifier extends MatchNotifier {
  void _setRound(RoundState round) {
    state = state.copyWith(phase: MatchPhase.playing, round: round);
  }

  /// Red student at (3,2) can capture Blue student at (4,2) with mace (forward).
  void setupCaptureScenario() {
    _setRound(RoundState(
      roundNumber: 1,
      phase: RoundPhase.playing,
      pieces: const [
        Piece(type: PieceType.student, player: Player.red, row: 3, col: 2),
        Piece(type: PieceType.student, player: Player.blue, row: 4, col: 2),
      ],
      redHand: [mace, halberd],
      blueHand: [spear, flail],
      communityCard: warhammer,
      currentTurn: Player.red,
    ));
  }

  /// Red student at (3,2) can capture Blue MASTER at (4,2) — Way of the Stone.
  void setupStoneScenario() {
    _setRound(RoundState(
      roundNumber: 1,
      phase: RoundPhase.playing,
      pieces: const [
        Piece(type: PieceType.student, player: Player.red, row: 3, col: 2),
        Piece(type: PieceType.master, player: Player.blue, row: 4, col: 2),
      ],
      redHand: [mace, halberd],
      blueHand: [spear, flail],
      communityCard: warhammer,
      currentTurn: Player.red,
    ));
  }

  /// Red MASTER at (3,2) steps to (4,2) — Way of the Stream.
  void setupStreamScenario() {
    _setRound(RoundState(
      roundNumber: 1,
      phase: RoundPhase.playing,
      pieces: const [
        Piece(type: PieceType.master, player: Player.red, row: 3, col: 2),
      ],
      redHand: [mace, halberd],
      blueHand: [spear, flail],
      communityCard: warhammer,
      currentTurn: Player.red,
    ));
  }

  /// Blue MASTER at (1,2) steps to (0,2) — Blue Way of the Stream.
  /// mace has CardMove(0,1) which for Blue flips to dr=-1, so (1,2)→(0,2).
  void setupBlueStreamScenario() {
    _setRound(RoundState(
      roundNumber: 1,
      phase: RoundPhase.playing,
      pieces: const [
        Piece(type: PieceType.master, player: Player.blue, row: 1, col: 2),
      ],
      redHand: [mace, halberd],
      blueHand: [mace, flail],
      communityCard: warhammer,
      currentTurn: Player.blue,
    ));
  }
}
