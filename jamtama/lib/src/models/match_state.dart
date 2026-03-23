import 'card.dart';
import 'deck.dart';
import 'round_state.dart';

enum MatchPhase { menu, deckSelection, draftingRed, draftingBlue, playing, matchOver }

const _s = Object();

class MatchState {
  final MatchPhase phase;
  final Deck redDeck;
  final Deck blueDeck;

  /// Cards still available to draw from each player's deck this match.
  final List<CardDefinition> redRemaining;
  final List<CardDefinition> blueRemaining;

  /// The 3 cards drawn this draft phase (before the player picks 2).
  final List<CardDefinition> redDrafted;
  final List<CardDefinition> blueDrafted;

  /// The 2 cards confirmed for the current round's hand.
  final List<CardDefinition> redHand;
  final List<CardDefinition> blueHand;

  final int redWins;
  final int blueWins;
  final int currentRound;

  final RoundState? round;

  const MatchState({
    required this.phase,
    required this.redDeck,
    required this.blueDeck,
    required this.redRemaining,
    required this.blueRemaining,
    this.redDrafted = const [],
    this.blueDrafted = const [],
    this.redHand = const [],
    this.blueHand = const [],
    this.redWins = 0,
    this.blueWins = 0,
    this.currentRound = 1,
    this.round,
  });

  MatchState copyWith({
    MatchPhase? phase,
    Deck? redDeck,
    Deck? blueDeck,
    List<CardDefinition>? redRemaining,
    List<CardDefinition>? blueRemaining,
    List<CardDefinition>? redDrafted,
    List<CardDefinition>? blueDrafted,
    List<CardDefinition>? redHand,
    List<CardDefinition>? blueHand,
    int? redWins,
    int? blueWins,
    int? currentRound,
    Object? round = _s,
  }) {
    return MatchState(
      phase: phase ?? this.phase,
      redDeck: redDeck ?? this.redDeck,
      blueDeck: blueDeck ?? this.blueDeck,
      redRemaining: redRemaining ?? this.redRemaining,
      blueRemaining: blueRemaining ?? this.blueRemaining,
      redDrafted: redDrafted ?? this.redDrafted,
      blueDrafted: blueDrafted ?? this.blueDrafted,
      redHand: redHand ?? this.redHand,
      blueHand: blueHand ?? this.blueHand,
      redWins: redWins ?? this.redWins,
      blueWins: blueWins ?? this.blueWins,
      currentRound: currentRound ?? this.currentRound,
      round: round == _s ? this.round : round as RoundState?,
    );
  }
}
