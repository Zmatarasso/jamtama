import 'card.dart';
import 'piece.dart';

enum RoundPhase { playing, over }

enum WinCondition { wayOfStone, wayOfStream }

class BoardPos {
  final int row;
  final int col;
  const BoardPos(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is BoardPos && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}

// Sentinel for nullable copyWith fields.
const _s = Object();

class RoundState {
  final int roundNumber;
  final RoundPhase phase;
  final List<Piece> pieces;
  final List<CardDefinition> redHand;
  final List<CardDefinition> blueHand;
  final CardDefinition communityCard;
  final Player currentTurn;

  /// Card selected by current player, not yet committed.
  final CardDefinition? pendingCard;

  /// Piece tapped/dragged by current player.
  final Piece? selectedPiece;

  /// Valid destination squares given [pendingCard] + [selectedPiece].
  final List<BoardPos> validMoves;

  final Player? winner;
  final WinCondition? winCondition;

  const RoundState({
    required this.roundNumber,
    required this.phase,
    required this.pieces,
    required this.redHand,
    required this.blueHand,
    required this.communityCard,
    required this.currentTurn,
    this.pendingCard,
    this.selectedPiece,
    this.validMoves = const [],
    this.winner,
    this.winCondition,
  });

  RoundState copyWith({
    int? roundNumber,
    RoundPhase? phase,
    List<Piece>? pieces,
    List<CardDefinition>? redHand,
    List<CardDefinition>? blueHand,
    CardDefinition? communityCard,
    Player? currentTurn,
    Object? pendingCard = _s,
    Object? selectedPiece = _s,
    List<BoardPos>? validMoves,
    Object? winner = _s,
    Object? winCondition = _s,
  }) {
    return RoundState(
      roundNumber: roundNumber ?? this.roundNumber,
      phase: phase ?? this.phase,
      pieces: pieces ?? this.pieces,
      redHand: redHand ?? this.redHand,
      blueHand: blueHand ?? this.blueHand,
      communityCard: communityCard ?? this.communityCard,
      currentTurn: currentTurn ?? this.currentTurn,
      pendingCard:
          pendingCard == _s ? this.pendingCard : pendingCard as CardDefinition?,
      selectedPiece:
          selectedPiece == _s ? this.selectedPiece : selectedPiece as Piece?,
      validMoves: validMoves ?? this.validMoves,
      winner: winner == _s ? this.winner : winner as Player?,
      winCondition: winCondition == _s
          ? this.winCondition
          : winCondition as WinCondition?,
    );
  }
}
