import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';  // For Offset.
import '../models/piece.dart';
import '../models/card.dart';

/// Immutable game state for predictable updates and easy testing.
class GameState {
  final List<Piece> pieces;
  final List<MoveCard> cards;
  final Player currentTurn;
  final Piece? selectedPiece;
  final MoveCard? selectedCard;

  const GameState({
    this.pieces = const [],
    this.cards = const [],
    this.currentTurn = Player.red,
    this.selectedPiece,
    this.selectedCard,
  });

  /// Creates a new state with updated fields (immutable copy).
  GameState copyWith({
    List<Piece>? pieces,
    List<MoveCard>? cards,
    Player? currentTurn,
    Piece? selectedPiece,
    MoveCard? selectedCard,
  }) {
    return GameState(
      pieces: pieces ?? this.pieces,
      cards: cards ?? this.cards,
      currentTurn: currentTurn ?? this.currentTurn,
      selectedPiece: selectedPiece ?? this.selectedPiece,
      selectedCard: selectedCard ?? this.selectedCard,
    );
  }

  @override
  String toString() => 'Turn: $currentTurn, Pieces: ${pieces.length}';
}

/// Manages game logic; notifies on state changes.
class GameNotifier extends Notifier<GameState> {
  @override
  GameState build() => const GameState();

  /// Initializes board and cards.
  void initGame() {
    state = state.copyWith(
      pieces: [
        Piece(type: PieceType.master, player: Player.red, row: 0, col: 2),
        ...List.generate(4, (i) => Piece(type: PieceType.student, player: Player.red, row: 0, col: i < 2 ? i : i + 1)),
        Piece(type: PieceType.master, player: Player.blue, row: 4, col: 2),
        ...List.generate(4, (i) => Piece(type: PieceType.student, player: Player.blue, row: 4, col: i < 2 ? i : i + 1)),
      ],
      cards: [
        MoveCard(name: 'Tiger', moves: [Offset(0, 2), Offset(0, -1)]),
        // Add more as needed.
      ],
    );
  }

  /// Selects a piece if it's the current player's.
  void selectPiece(Piece piece) {
    if (piece.player == state.currentTurn) {
      state = state.copyWith(selectedPiece: piece);
    }
  }

  /// Moves selected piece; validates stubbed; rotates turn.
  void movePiece(int newRow, int newCol) {
    if (state.selectedPiece == null || state.selectedCard == null) return;
    // TODO: Add move validation based on selectedCard.moves.
    final updatedPieces = [...state.pieces];
    final index = updatedPieces.indexOf(state.selectedPiece!);
    updatedPieces[index] = Piece(
      type: updatedPieces[index].type,
      player: updatedPieces[index].player,
      row: newRow,
      col: newCol,
    );
    state = state.copyWith(
      pieces: updatedPieces,
      currentTurn: state.currentTurn == Player.red ? Player.blue : Player.red,
      selectedPiece: null,
      selectedCard: null,
    );
  }
}

/// Global provider for game state.
final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);