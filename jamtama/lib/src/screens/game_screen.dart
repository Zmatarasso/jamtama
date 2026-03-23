import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../models/piece.dart';
import '../models/round_state.dart';
import '../providers/match_provider.dart';
import '../widgets/card_widget.dart';

// ---------------------------------------------------------------------------
// Board rendering constants
// ---------------------------------------------------------------------------
const _boardBg = Color(0xFF2B1810);
const _cellLight = Color(0xFFDEB887);
const _cellDark = Color(0xFFA0522D);
const _templeColor = Color(0xFFFFD700);
const _validMoveColor = Color(0xFF4CAF50);
const _selectedBorder = Color(0xFFFFD700);
const _hoverColor = Color(0xFF8BC34A);

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchProvider);
    final round = match.round;

    if (round == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: _boardBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Blue's area (rotated so Blue sees it from their perspective) ──
            RotatedBox(
              quarterTurns: 2,
              child: _PlayerArea(
                player: Player.blue,
                round: round,
                isActive: round.currentTurn == Player.blue &&
                    round.phase == RoundPhase.playing,
              ),
            ),

            // ── Score / round indicator ──
            _ScoreBar(match: match),

            // ── Board ──
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _Board(round: round),
                  ),
                ),
              ),
            ),

            // ── Red's area ──
            _PlayerArea(
              player: Player.red,
              round: round,
              isActive: round.currentTurn == Player.red &&
                  round.phase == RoundPhase.playing,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Score / round bar
// ---------------------------------------------------------------------------

class _ScoreBar extends StatelessWidget {
  final dynamic match; // MatchState

  const _ScoreBar({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A0F08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _winPips(match.blueWins, const Color(0xFF4169E1)),
          Text(
            'Round ${match.currentRound}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          _winPips(match.redWins, const Color(0xFFDC143C)),
        ],
      ),
    );
  }

  Widget _winPips(int wins, Color color) {
    return Row(
      children: List.generate(
        2,
        (i) => Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < wins ? color : color.withAlpha(50),
            border: Border.all(color: color.withAlpha(120), width: 1),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Player area: hand cards + community card (for that player's side)
// ---------------------------------------------------------------------------

class _PlayerArea extends ConsumerWidget {
  final Player player;
  final RoundState round;
  final bool isActive;

  const _PlayerArea({
    required this.player,
    required this.round,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hand = player == Player.red ? round.redHand : round.blueHand;
    final color =
        player == Player.red ? const Color(0xFFDC143C) : const Color(0xFF4169E1);
    final label = player == Player.red ? 'Red' : 'Blue';

    return Container(
      color: const Color(0xFF1A0F08),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Turn indicator dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? color : color.withAlpha(60),
            ),
          ),

          // Hand cards
          Row(
            children: hand.map((card) {
              final isPending = round.pendingCard == card && isActive;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: CardWidget(
                  card: card,
                  selected: isPending,
                  dimmed: !isActive,
                  onTap: isActive
                      ? () =>
                          ref.read(matchProvider.notifier).selectCard(card)
                      : null,
                ),
              );
            }).toList(),
          ),

          // Community card (shown on Red's side for both players to see)
          if (player == Player.red) ...[
            Column(
              children: [
                const Text(
                  'TABLE',
                  style: TextStyle(color: Colors.white38, fontSize: 9),
                ),
                const SizedBox(height: 4),
                CardWidget(card: round.communityCard, dimmed: true),
              ],
            ),
          ] else
            const SizedBox(width: 76), // balance layout for Blue's side

          // Label
          Text(
            label,
            style: TextStyle(
              color: isActive ? color : color.withAlpha(100),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Board
// ---------------------------------------------------------------------------

class _Board extends ConsumerWidget {
  final RoundState round;
  const _Board({required this.round});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: 25,
      itemBuilder: (context, index) {
        // Render row 4 first (Blue's back row at top, Red's back row at bottom).
        final row = 4 - (index ~/ 5);
        final col = index % 5;
        return _Cell(row: row, col: col, round: round);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Individual board cell
// ---------------------------------------------------------------------------

class _Cell extends ConsumerWidget {
  final int row;
  final int col;
  final RoundState round;

  const _Cell({required this.row, required this.col, required this.round});

  Color _baseColor(bool isTemple) {
    if (isTemple) return _templeColor.withAlpha(80);
    return ((row + col) % 2 == 0) ? _cellLight : _cellDark;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final piece = round.pieces
        .firstWhereOrNull((p) => p.row == row && p.col == col);
    final pos = BoardPos(row, col);
    final isValidMove = round.validMoves.contains(pos);
    final isSelected =
        round.selectedPiece?.row == row && round.selectedPiece?.col == col;
    final isRedTemple = row == 0 && col == 2;
    final isBlueTemple = row == 4 && col == 2;
    final isTemple = isRedTemple || isBlueTemple;
    final isCurrentPlayer = piece?.player == round.currentTurn;

    return DragTarget<Piece>(
      onWillAcceptWithDetails: (_) {
        // Read live state — not stale build-time capture.
        return ref
                .read(matchProvider)
                .round
                ?.validMoves
                .contains(pos) ??
            false;
      },
      onAcceptWithDetails: (_) {
        ref.read(matchProvider.notifier).executeMove(row: row, col: col);
      },
      builder: (context, candidates, _) {
        final isHovering = candidates.isNotEmpty;
        Color bg = _baseColor(isTemple);
        if (isHovering) bg = _hoverColor;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: bg,
            border: isSelected
                ? Border.all(color: _selectedBorder, width: 2.5)
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Valid-move dot (shown under pieces too, for clarity)
              if (isValidMove && piece == null)
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _validMoveColor.withAlpha(200),
                    shape: BoxShape.circle,
                  ),
                ),

              // Piece
              if (piece != null)
                _buildPieceSlot(context, ref, piece, isCurrentPlayer,
                    isSelected, isValidMove),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPieceSlot(
    BuildContext context,
    WidgetRef ref,
    Piece piece,
    bool isCurrentPlayer,
    bool isSelected,
    bool isValidMove,
  ) {
    final pieceWidget = _PieceWidget(piece: piece, selected: isSelected);

    if (!isCurrentPlayer || round.phase != RoundPhase.playing) {
      return pieceWidget;
    }

    return Draggable<Piece>(
      data: piece,
      onDragStarted: () {
        ref.read(matchProvider.notifier).selectPiece(piece);
      },
      feedback: Material(
        color: Colors.transparent,
        child: _PieceWidget(piece: piece, selected: true, size: 44),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: pieceWidget,
      ),
      child: GestureDetector(
        onTap: () => ref.read(matchProvider.notifier).selectPiece(piece),
        child: pieceWidget,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Piece widget
// ---------------------------------------------------------------------------

class _PieceWidget extends StatelessWidget {
  final Piece piece;
  final bool selected;
  final double size;

  const _PieceWidget({
    required this.piece,
    this.selected = false,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final isMaster = piece.type == PieceType.master;
    final color = piece.player == Player.red
        ? const Color(0xFFDC143C)
        : const Color(0xFF4169E1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: selected ? Colors.amber : Colors.white.withAlpha(80),
          width: selected ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: selected ? Colors.amber.withAlpha(160) : Colors.black38,
            blurRadius: selected ? 8 : 3,
          ),
        ],
      ),
      child: Center(
        child: Text(
          isMaster ? '★' : '●',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMaster ? size * 0.42 : size * 0.32,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Round-over overlay — shown as a dialog when round.phase == over
// ---------------------------------------------------------------------------

class RoundOverDialog extends ConsumerWidget {
  final RoundState round;
  final int redWins;
  final int blueWins;
  final bool isMatchOver;

  const RoundOverDialog({
    super.key,
    required this.round,
    required this.redWins,
    required this.blueWins,
    required this.isMatchOver,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final winner = round.winner!;
    final winnerColor = winner == Player.red
        ? const Color(0xFFDC143C)
        : const Color(0xFF4169E1);
    final winnerLabel = winner == Player.red ? 'Red' : 'Blue';
    final conditionLabel = round.winCondition == WinCondition.wayOfStone
        ? 'Way of the Stone'
        : 'Way of the Stream';

    return AlertDialog(
      backgroundColor: const Color(0xFF1A0F08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isMatchOver ? 'Match Over!' : 'Round Over!',
        style: const TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$winnerLabel wins',
            style: TextStyle(
              color: winnerColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            conditionLabel,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _scoreChip('Red', redWins, const Color(0xFFDC143C)),
              const SizedBox(width: 16),
              _scoreChip('Blue', blueWins, const Color(0xFF4169E1)),
            ],
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (isMatchOver) {
              ref.read(matchProvider.notifier).returnToMenu();
            } else {
              ref.read(matchProvider.notifier).startNextRound();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B6914),
            foregroundColor: Colors.white,
          ),
          child: Text(isMatchOver ? 'New Match' : 'Next Round'),
        ),
      ],
    );
  }

  Widget _scoreChip(String label, int wins, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: List.generate(
            2,
            (i) => Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < wins ? color : color.withAlpha(40),
                border: Border.all(color: color.withAlpha(100)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
