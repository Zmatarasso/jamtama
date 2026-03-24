import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../cosmetics/models/board_cosmetic.dart';
import '../cosmetics/models/master_piece_cosmetic.dart';
import '../cosmetics/models/piece_cosmetic.dart';
import '../cosmetics/models/student_piece_cosmetic.dart';
import '../cosmetics/models/throne_cosmetic.dart';
import '../cosmetics/providers/cosmetic_loadout_provider.dart';
import '../models/piece.dart';
import '../models/round_state.dart';
import '../providers/match_provider.dart';
import '../services/audio_service.dart';
import '../widgets/card_widget.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchProvider);
    final round = match.round;
    if (round == null) return const SizedBox.shrink();

    final board = ref.watch(cosmeticLoadoutProvider.select((l) => l.board));
    final scenery =
        ref.watch(cosmeticLoadoutProvider.select((l) => l.scenery));

    return Scaffold(
      backgroundColor: scenery.backgroundColor,
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
                    child: _Board(round: round, board: board),
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
  final dynamic match;
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
// Player area: hand cards + community card
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
                      ? () {
                          ref.read(audioServiceProvider).playCardSelect(
                              ref.read(cosmeticLoadoutProvider).uiSounds);
                          ref.read(matchProvider.notifier).selectCard(card);
                        }
                      : null,
                ),
              );
            }).toList(),
          ),

          // Community card (shown on Red's side)
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
            const SizedBox(width: 76),

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
// Board — reads cosmetics and passes them to each cell
// ---------------------------------------------------------------------------

class _Board extends ConsumerWidget {
  final RoundState round;
  final BoardCosmetic board;

  const _Board({required this.round, required this.board});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masterCosmetic =
        ref.watch(cosmeticLoadoutProvider.select((l) => l.masterPiece));
    final studentCosmetic =
        ref.watch(cosmeticLoadoutProvider.select((l) => l.studentPiece));
    final throneCosmetic =
        ref.watch(cosmeticLoadoutProvider.select((l) => l.throne));

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: 25,
      itemBuilder: (context, index) {
        // Render row 4 first so Blue's back row appears at top.
        final row = 4 - (index ~/ 5);
        final col = index % 5;
        return _Cell(
          row: row,
          col: col,
          round: round,
          board: board,
          masterCosmetic: masterCosmetic,
          studentCosmetic: studentCosmetic,
          throneCosmetic: throneCosmetic,
        );
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
  final BoardCosmetic board;
  final MasterPieceCosmetic masterCosmetic;
  final StudentPieceCosmetic studentCosmetic;
  final ThroneCosmetic throneCosmetic;

  const _Cell({
    required this.row,
    required this.col,
    required this.round,
    required this.board,
    required this.masterCosmetic,
    required this.studentCosmetic,
    required this.throneCosmetic,
  });

  Color _baseColor(bool isTemple) {
    if (isTemple) return board.templeHighlightColor.withAlpha(80);
    return ((row + col) % 2 == 0) ? board.lightTileColor : board.darkTileColor;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final piece =
        round.pieces.firstWhereOrNull((p) => p.row == row && p.col == col);
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
        return ref
                .read(matchProvider)
                .round
                ?.validMoves
                .contains(pos) ??
            false;
      },
      onAcceptWithDetails: (_) {
        // Play move or capture sound depending on whether the target is occupied.
        final liveRound = ref.read(matchProvider).round;
        final targetPiece = liveRound?.pieces
            .firstWhereOrNull((p) => p.row == row && p.col == col);
        final isCapture =
            targetPiece != null && targetPiece.player != liveRound?.currentTurn;
        final audio = ref.read(audioServiceProvider);
        final moveCosmetic = ref.read(cosmeticLoadoutProvider).moveEffect;
        if (isCapture) {
          audio.playCapture(moveCosmetic);
        } else {
          audio.playMove(moveCosmetic);
        }
        ref.read(matchProvider.notifier).executeMove(row: row, col: col);
      },
      builder: (context, candidates, _) {
        final isHovering = candidates.isNotEmpty;
        Color bg = _baseColor(isTemple);
        if (isHovering) bg = board.hoverColor;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: bg,
            border: isSelected
                ? Border.all(color: Colors.amber, width: 2.5)
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Throne overlay on temple squares (behind pieces)
              if (isTemple) _ThroneOverlay(cosmetic: throneCosmetic),

              // Valid-move dot on empty squares
              if (isValidMove && piece == null)
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: board.validMoveColor.withAlpha(200),
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
    final pieceWidget = _PieceWidget(
      piece: piece,
      selected: isSelected,
      masterCosmetic: masterCosmetic,
      studentCosmetic: studentCosmetic,
    );

    if (!isCurrentPlayer || round.phase != RoundPhase.playing) {
      return pieceWidget;
    }

    return Draggable<Piece>(
      data: piece,
      feedbackOffset: const Offset(-38, -38),
      onDragStarted: () {
        final round = ref.read(matchProvider).round;
        if (round?.selectedPiece != piece) {
          ref.read(audioServiceProvider).playPieceSelect(
              ref.read(cosmeticLoadoutProvider).uiSounds);
          ref.read(matchProvider.notifier).selectPiece(piece);
        }
      },
      feedback: Material(
        color: Colors.transparent,
        child: _PieceWidget(
          piece: piece,
          selected: true,
          size: 76,
          masterCosmetic: masterCosmetic,
          studentCosmetic: studentCosmetic,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: pieceWidget,
      ),
      child: GestureDetector(
        onTap: () {
          ref.read(audioServiceProvider).playPieceSelect(
              ref.read(cosmeticLoadoutProvider).uiSounds);
          ref.read(matchProvider.notifier).selectPiece(piece);
        },
        child: pieceWidget,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Throne overlay — rendered on temple squares behind pieces
// ---------------------------------------------------------------------------

class _ThroneOverlay extends StatelessWidget {
  final ThroneCosmetic cosmetic;
  const _ThroneOverlay({required this.cosmetic});

  @override
  Widget build(BuildContext context) {
    if (cosmetic.assetPath != null) {
      return Positioned.fill(
        child: Image.asset(
          cosmetic.assetPath!,
          fit: BoxFit.contain,
        ),
      );
    }
    // Programmatic fallback: concentric ring in the throne color.
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: cosmetic.fallbackColor.withAlpha(160),
          width: 3,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Piece widget
// ---------------------------------------------------------------------------

class _PieceWidget extends StatefulWidget {
  final Piece piece;
  final bool selected;
  final double size;
  final MasterPieceCosmetic masterCosmetic;
  final StudentPieceCosmetic studentCosmetic;

  const _PieceWidget({
    required this.piece,
    this.selected = false,
    this.size = 76,
    required this.masterCosmetic,
    required this.studentCosmetic,
  });

  @override
  State<_PieceWidget> createState() => _PieceWidgetState();
}

class _PieceWidgetState extends State<_PieceWidget> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isMaster = widget.piece.type == PieceType.master;
    final playerColor = widget.piece.player == Player.red
        ? const Color(0xFFDC143C)
        : const Color(0xFF4169E1);

    final baseSize = isMaster ? widget.size * 1.1 : widget.size;
    final effectiveSize = _hovering ? baseSize * 1.1 : baseSize;

    final borderColor = widget.selected
        ? Colors.amber
        : (_hovering ? Colors.white.withAlpha(200) : Colors.white.withAlpha(80));
    final borderWidth = widget.selected ? 2.5 : (_hovering ? 2.0 : 1.5);
    final shadowColor = widget.selected
        ? Colors.amber.withAlpha(160)
        : (_hovering ? playerColor.withAlpha(180) : Colors.black38);
    final shadowBlur = widget.selected ? 10.0 : (_hovering ? 14.0 : 3.0);

    final PieceCosmetic cosmetic =
        isMaster ? widget.masterCosmetic : widget.studentCosmetic;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: effectiveSize,
        height: effectiveSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Asset path present → image asset tinted with player color.
          // null → programmatic colored circle (current default look).
          color: cosmetic.assetPath == null ? playerColor : null,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(color: shadowColor, blurRadius: shadowBlur),
          ],
        ),
        child: cosmetic.assetPath != null
            ? ClipOval(
                child: ColorFiltered(
                  colorFilter:
                      ColorFilter.mode(playerColor, BlendMode.modulate),
                  child: Image.asset(
                    cosmetic.assetPath!,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : Center(
                child: Text(
                  isMaster ? '★' : '●',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMaster
                        ? effectiveSize * 0.42
                        : effectiveSize * 0.32,
                    height: 1,
                  ),
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Round-over dialog
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
