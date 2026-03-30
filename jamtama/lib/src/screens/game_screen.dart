import 'dart:math' show cos, sin, pi, min;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../cosmetics/models/board_cosmetic.dart' show BoardCosmetic, BoardTileStyle;
import '../cosmetics/models/move_effect_cosmetic.dart';
import '../cosmetics/models/master_piece_cosmetic.dart';
import '../cosmetics/models/piece_cosmetic.dart' show PieceCosmetic, PieceStyle;
import '../cosmetics/models/student_piece_cosmetic.dart';
import '../cosmetics/models/throne_cosmetic.dart';
import '../cosmetics/providers/cosmetic_loadout_provider.dart';
import '../models/card.dart';
import '../models/piece.dart';
import '../models/round_state.dart';
import '../providers/match_provider.dart';
import '../services/audio_service.dart';
import '../widgets/card_widget.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  // ── Debug layout knobs ──────────────────────────────────────────────────
  double _boardScale    = 0.90; // fraction of min(w,h) the board occupies
  double _boardLeft     = 12.0; // px from left edge
  double _cardScale     = 1.0;  // fan hand card scale (1.0 = native 76×100)
  double _tableCardW    = 76.0; // table card display width (px)
  double _floatCardW    = 90.0; // floating selected card display width (px)
  double _rightPanelW   = 110.0; // right panel fixed width (px)
  bool   _debugOpen     = true;

  @override
  Widget build(BuildContext context) {
    final match = ref.watch(matchProvider);
    final round = match.round;
    if (round == null) return const SizedBox.shrink();

    final board   = ref.watch(cosmeticLoadoutProvider.select((l) => l.board));
    final scenery = ref.watch(cosmeticLoadoutProvider.select((l) => l.scenery));

    // Derived float-card dimensions (aspect ratio always locked).
    final floatCardH = _floatCardW * 100.0 / 76.0;

    return Scaffold(
      backgroundColor: scenery.backgroundColor,
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 9 / 19.5, // iPhone portrait frame
            child: Container(
              // Visible frame so you can see the exact portrait dimensions.
              color: const Color(0xFF0D1F2D),
              child: Stack(
                children: [
                  // ── Main game layout ─────────────────────────────────────
                  Column(
                    children: [
                      _ScoreBar(match: match),
                      Expanded(
                        child: Stack(
                          children: [
                            // Board + right panel
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final boardSize =
                                    (min(constraints.maxWidth, constraints.maxHeight) - 16.0)
                                    * _boardScale;

                                const rightPanelRight = 6.0;
                                final rightPanelLeft =
                                    constraints.maxWidth - rightPanelRight - _rightPanelW;

                                final floatX = rightPanelLeft +
                                    (_rightPanelW - _floatCardW) / 2.0;
                                final floatY =
                                    (constraints.maxHeight - floatCardH) / 2.0;

                                return Stack(
                                  children: [
                                    // Board
                                    Positioned(
                                      left: _boardLeft,
                                      top: 0,
                                      bottom: 0,
                                      width: boardSize,
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
                                    // Table card
                                    Positioned(
                                      right: rightPanelRight,
                                      width: _rightPanelW,
                                      top: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: _TableCard(
                                          card: round.communityCard,
                                          currentTurn: round.currentTurn,
                                          displayW: _tableCardW,
                                        ),
                                      ),
                                    ),
                                    // Floating selected card
                                    if (round.pendingCard != null)
                                      AnimatedPositioned(
                                        duration: const Duration(milliseconds: 320),
                                        curve: Curves.easeOutBack,
                                        left: floatX,
                                        top: floatY,
                                        child: _FloatingCard(
                                          card: round.pendingCard!,
                                          displayW: _floatCardW,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),

                            // Blue's hand
                            Positioned(
                              top: 0, left: 0, right: 0,
                              child: RotatedBox(
                                quarterTurns: 2,
                                child: _PlayerArea(
                                  player: Player.blue,
                                  round: round,
                                  cardScale: _cardScale,
                                  isActive: round.currentTurn == Player.blue &&
                                      round.phase == RoundPhase.playing,
                                ),
                              ),
                            ),

                            // Red's hand
                            Positioned(
                              bottom: 0, left: 0, right: 0,
                              child: _PlayerArea(
                                player: Player.red,
                                round: round,
                                cardScale: _cardScale,
                                isActive: round.currentTurn == Player.red &&
                                    round.phase == RoundPhase.playing,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Debug panel ──────────────────────────────────────────
                  _DebugPanel(
                    open: _debugOpen,
                    onToggle: () => setState(() => _debugOpen = !_debugOpen),
                    sliders: [
                      _DebugSlider('Board scale', _boardScale, 0.4, 1.0,
                          (v) => setState(() => _boardScale = v)),
                      _DebugSlider('Board left', _boardLeft, 0, 60,
                          (v) => setState(() => _boardLeft = v)),
                      _DebugSlider('Card scale', _cardScale, 0.5, 3.0,
                          (v) => setState(() => _cardScale = v)),
                      _DebugSlider('Table card W', _tableCardW, 40, 160,
                          (v) => setState(() => _tableCardW = v)),
                      _DebugSlider('Float card W', _floatCardW, 40, 160,
                          (v) => setState(() => _floatCardW = v)),
                      _DebugSlider('Right panel W', _rightPanelW, 60, 200,
                          (v) => setState(() => _rightPanelW = v)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Debug panel
// ---------------------------------------------------------------------------

class _DebugSlider {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  const _DebugSlider(this.label, this.value, this.min, this.max, this.onChanged);
}

class _DebugPanel extends StatelessWidget {
  final bool open;
  final VoidCallback onToggle;
  final List<_DebugSlider> sliders;

  const _DebugPanel({
    required this.open,
    required this.onToggle,
    required this.sliders,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 36,
      right: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (open)
            Container(
              width: 180,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(210),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: sliders.map((s) => _buildSlider(s)).toList(),
              ),
            ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 24,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Center(
                child: Text(
                  open ? '›' : '‹',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(_DebugSlider s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${s.label}: ${s.value.toStringAsFixed(1)}',
          style: const TextStyle(color: Colors.white70, fontSize: 9),
        ),
        SizedBox(
          height: 24,
          child: Slider(
            value: s.value,
            min: s.min,
            max: s.max,
            onChanged: s.onChanged,
            activeColor: Colors.amber,
            inactiveColor: Colors.white24,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Score / round bar
// ---------------------------------------------------------------------------

class _ScoreBar extends ConsumerWidget {
  final dynamic match;
  const _ScoreBar({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFF1A0F08),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          // Back to menu
          IconButton(
            onPressed: () =>
                ref.read(matchProvider.notifier).returnToMenu(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 16),
            color: Colors.white38,
            tooltip: 'Back to menu',
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          _winPips(match.blueWins, const Color(0xFF4169E1)),
          Expanded(
            child: Center(
              child: Text(
                'Round ${match.currentRound}',
                style:
                    const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
          ),
          _winPips(match.redWins, const Color(0xFFDC143C)),
          const SizedBox(width: 36), // balance the back button
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
  final double cardScale;

  const _PlayerArea({
    required this.player,
    required this.round,
    required this.isActive,
    required this.cardScale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hand = player == Player.red ? round.redHand : round.blueHand;
    final color =
        player == Player.red ? const Color(0xFFDC143C) : const Color(0xFF4169E1);
    final label = player == Player.red ? 'Red' : 'Blue';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xE61A0F08), Colors.transparent],
          stops: [0.0, 1.0],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Turn indicator dot
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? color : color.withAlpha(60),
              ),
            ),
          ),

          // Fan hand
          Expanded(
            child: Center(
              child: _FanHand(
                hand: hand,
                pendingCard: isActive ? round.pendingCard : null,
                isActive: isActive,
                scale: cardScale,
                onCardTap: (card) {
                  ref.read(audioServiceProvider).playCardSelect(
                      ref.read(cosmeticLoadoutProvider).uiSounds);
                  ref.read(matchProvider.notifier).selectCard(card);
                },
              ),
            ),
          ),

          // Label
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? color : color.withAlpha(100),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
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

class _Cell extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<_Cell> createState() => _CellState();
}

class _CellState extends ConsumerState<_Cell>
    with SingleTickerProviderStateMixin {
  late AnimationController _glitterAnim;

  @override
  void initState() {
    super.initState();
    _glitterAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _glitterAnim.dispose();
    super.dispose();
  }

  void _triggerGlitter() => _glitterAnim.forward(from: 0);

  Color _baseColor(bool isTemple) {
    if (isTemple) return widget.board.templeHighlightColor.withAlpha(80);
    return ((widget.row + widget.col) % 2 == 0)
        ? widget.board.lightTileColor
        : widget.board.darkTileColor;
  }

  @override
  Widget build(BuildContext context) {
    final piece = widget.round.pieces
        .firstWhereOrNull((p) => p.row == widget.row && p.col == widget.col);
    final pos = BoardPos(widget.row, widget.col);
    final isValidMove = widget.round.validMoves.contains(pos);
    final isSelected = widget.round.selectedPiece?.row == widget.row &&
        widget.round.selectedPiece?.col == widget.col;
    final isTemple =
        (widget.row == 0 || widget.row == 4) && widget.col == 2;
    final isCurrentPlayer = piece?.player == widget.round.currentTurn;

    return DragTarget<Piece>(
      onWillAcceptWithDetails: (_) =>
          ref.read(matchProvider).round?.validMoves.contains(pos) ?? false,
      onAcceptWithDetails: (_) {
        final liveRound = ref.read(matchProvider).round;
        final targetPiece = liveRound?.pieces.firstWhereOrNull(
            (p) => p.row == widget.row && p.col == widget.col);
        final isCapture = targetPiece != null &&
            targetPiece.player != liveRound?.currentTurn;
        final audio = ref.read(audioServiceProvider);
        final moveCosmetic = ref.read(cosmeticLoadoutProvider).moveEffect;
        if (isCapture) {
          audio.playCapture(moveCosmetic);
        } else {
          audio.playMove(moveCosmetic);
        }
        if (moveCosmetic.type == MoveEffectType.glitter) _triggerGlitter();
        ref
            .read(matchProvider.notifier)
            .executeMove(row: widget.row, col: widget.col);
      },
      builder: (context, candidates, _) {
        final isHovering = candidates.isNotEmpty;
        final style = widget.board.tileStyle;
        final isPainted = style == BoardTileStyle.woodGrain ||
            style == BoardTileStyle.stone;
        final tileBase = _baseColor(isTemple);

        // Painted styles handle hover as an overlay; flat bakes it into bg.
        Color bg = tileBase;
        if (isHovering && !isPainted) bg = widget.board.hoverColor;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: isPainted ? Colors.transparent : bg,
            border: isSelected
                ? Border.all(color: Colors.amber, width: 2.5)
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Procedural tile background
              if (style == BoardTileStyle.woodGrain)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WoodGrainTilePainter(
                      baseColor: tileBase,
                      tileRow: widget.row,
                      tileCol: widget.col,
                    ),
                  ),
                ),
              if (style == BoardTileStyle.stone)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StoneTilePainter(
                      baseColor: tileBase,
                      tileRow: widget.row,
                      tileCol: widget.col,
                    ),
                  ),
                ),

              // Hover highlight overlay for painted styles
              if (isPainted && isHovering)
                Positioned.fill(
                  child: ColoredBox(
                    color: widget.board.hoverColor.withAlpha(110),
                  ),
                ),

              if (isTemple) _ThroneOverlay(cosmetic: widget.throneCosmetic),

              if (isValidMove && piece == null)
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: widget.board.validMoveColor.withAlpha(200),
                    shape: BoxShape.circle,
                  ),
                ),

              if (piece != null)
                _buildPieceSlot(piece, isCurrentPlayer, isSelected),

              // Glitter overlay — only active while animation is running
              AnimatedBuilder(
                animation: _glitterAnim,
                builder: (_, __) {
                  if (_glitterAnim.value == 0) return const SizedBox.shrink();
                  return Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter:
                            _GlitterPainter(progress: _glitterAnim.value),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPieceSlot(
      Piece piece, bool isCurrentPlayer, bool isSelected) {
    final pieceWidget = _PieceWidget(
      piece: piece,
      selected: isSelected,
      masterCosmetic: widget.masterCosmetic,
      studentCosmetic: widget.studentCosmetic,
    );

    if (!isCurrentPlayer || widget.round.phase != RoundPhase.playing) {
      return pieceWidget;
    }

    final moveType =
        ref.read(cosmeticLoadoutProvider).moveEffect.type;
    final baseFeedback = _PieceWidget(
      piece: piece,
      selected: true,
      size: 76,
      masterCosmetic: widget.masterCosmetic,
      studentCosmetic: widget.studentCosmetic,
    );
    final feedbackChild = moveType == MoveEffectType.glitter
        ? _GlitterFeedbackWidget(child: baseFeedback)
        : baseFeedback;

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
        child: feedbackChild,
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: pieceWidget),
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
// Glitter particle painter — used by MoveEffectType.glitter
// ---------------------------------------------------------------------------

class _GlitterPainter extends CustomPainter {
  final double progress;
  const _GlitterPainter({required this.progress});

  static const _colors = [
    Color(0xFFFFD700), // gold
    Color(0xFFFFFFFF), // white
    Color(0xFFFFC107), // amber
    Color(0xFFE1BEE7), // lavender
    Color(0xFFB3E5FC), // ice blue
    Color(0xFFFFECB3), // pale gold
  ];

  // 16 deterministic particles: (angle radians, speed 0–1, size px, color index)
  static const _p = [
    (a: 0.00, s: 0.90, z: 3.5, c: 0),
    (a: 0.39, s: 0.70, z: 2.0, c: 1),
    (a: 0.79, s: 1.00, z: 2.5, c: 2),
    (a: 1.18, s: 0.60, z: 3.0, c: 3),
    (a: 1.57, s: 0.85, z: 2.0, c: 4),
    (a: 1.96, s: 1.00, z: 3.5, c: 5),
    (a: 2.36, s: 0.70, z: 2.5, c: 0),
    (a: 2.75, s: 0.90, z: 2.0, c: 1),
    (a: 3.14, s: 0.65, z: 3.0, c: 2),
    (a: 3.53, s: 1.00, z: 2.0, c: 3),
    (a: 3.93, s: 0.75, z: 3.5, c: 4),
    (a: 4.32, s: 0.85, z: 2.5, c: 5),
    (a: 4.71, s: 0.95, z: 2.0, c: 0),
    (a: 5.10, s: 0.70, z: 3.0, c: 1),
    (a: 5.50, s: 1.00, z: 2.5, c: 2),
    (a: 5.89, s: 0.80, z: 3.0, c: 3),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxDist = size.shortestSide * 0.55;

    for (final p in _p) {
      final dist = p.s * progress * maxDist;
      final x = cx + cos(p.a) * dist;
      final y = cy + sin(p.a) * dist + 10 * progress * progress;
      final alpha = ((1.0 - progress) * 255).clamp(0, 255).toInt();
      final r = p.z * (1.0 - progress * 0.4);
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = _colors[p.c].withAlpha(alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_GlitterPainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------
// Glitter drag feedback — orbiting sparkles while holding a piece
// ---------------------------------------------------------------------------

// TODO(fix): _GlitterFeedbackWidget orbit particles are not rendering during
// drag. Likely cause: the Draggable feedback widget is painted in a separate
// overlay entry and the AnimationController may not be ticking, or the
// Positioned overflow is being clipped by the overlay. Needs investigation.
class _GlitterFeedbackWidget extends StatefulWidget {
  final Widget child;
  const _GlitterFeedbackWidget({required this.child});

  @override
  State<_GlitterFeedbackWidget> createState() =>
      _GlitterFeedbackWidgetState();
}

class _GlitterFeedbackWidgetState extends State<_GlitterFeedbackWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Particles overflow the piece bounds — 26px halo around it
          Positioned(
            left: -26,
            right: -26,
            top: -26,
            bottom: -26,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GlitterOrbitPainter(phase: _ctrl.value),
              ),
            ),
          ),
          child!,
        ],
      ),
      child: widget.child,
    );
  }
}

class _GlitterOrbitPainter extends CustomPainter {
  final double phase;
  const _GlitterOrbitPainter({required this.phase});

  static const _colors = [
    Color(0xFFFFD700),
    Color(0xFFFFFFFF),
    Color(0xFFFFC107),
    Color(0xFFE1BEE7),
    Color(0xFFB3E5FC),
    Color(0xFFFFECB3),
  ];

  static const _count = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 0; i < _count; i++) {
      // Each particle is offset in its cycle — they stagger around the orbit.
      final pPhase = (phase + i / _count) % 1.0;

      // Angle slowly rotates + per-particle spread.
      final angle =
          (i * (2 * pi / _count)) + phase * pi * 0.6;

      // Expand outward then fade — max ~30px from edge of piece.
      final dist = sin(pPhase * pi) * 30.0;

      // 85% max alpha of landing burst.
      final alpha = (sin(pPhase * pi) * 217).clamp(0, 255).toInt();
      final radius = 1.2 + sin(pPhase * pi) * 2.4;

      if (alpha <= 0) continue;

      canvas.drawCircle(
        Offset(cx + cos(angle) * dist, cy + sin(angle) * dist),
        radius,
        Paint()..color = _colors[i % _colors.length].withAlpha(alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_GlitterOrbitPainter old) => old.phase != phase;
}

// ---------------------------------------------------------------------------
// Throne overlay — rendered on temple squares behind pieces
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Wood grain tile painter — used by BoardTileStyle.woodGrain
// ---------------------------------------------------------------------------

class _WoodGrainTilePainter extends CustomPainter {
  final Color baseColor;
  final int tileRow;
  final int tileCol;

  const _WoodGrainTilePainter({
    required this.baseColor,
    required this.tileRow,
    required this.tileCol,
  });

  // Darken base color to get grain line color.
  Color get _grainColor {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl
        .withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Fill base
    canvas.drawRect(Offset.zero & size, Paint()..color = baseColor);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Offset grain start per tile so adjacent tiles don't look identical.
    final seed = tileRow * 17 + tileCol * 13;
    final yOffset = (seed % 20) / 20.0 * size.height;

    // ~12 grain lines per tile, running left→right with slight angle + waviness.
    for (int i = 0; i < 13; i++) {
      final t = ((i / 12.0) + yOffset / size.height) % 1.1 - 0.05;
      final y = t * size.height;

      final alpha = 30 + ((i * 31 + seed) % 45);
      final strokeW = 0.4 + ((i + tileCol) % 4) * 0.25;
      paint
        ..color = _grainColor.withAlpha(alpha)
        ..strokeWidth = strokeW;

      // Each line has a slight S-curve to mimic real grain.
      final waver = size.height * 0.04 * ((i % 2 == 0) ? 1 : -1);
      final path = Path()
        ..moveTo(-1, y)
        ..cubicTo(
          size.width * 0.3, y + waver,
          size.width * 0.7, y - waver * 0.6,
          size.width + 1, y + waver * 0.3,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WoodGrainTilePainter old) =>
      old.baseColor != baseColor ||
      old.tileRow != tileRow ||
      old.tileCol != tileCol;
}

// ---------------------------------------------------------------------------
// Stone tile painter — used by BoardTileStyle.stone
// ---------------------------------------------------------------------------

class _StoneTilePainter extends CustomPainter {
  final Color baseColor;
  final int tileRow;
  final int tileCol;

  const _StoneTilePainter({
    required this.baseColor,
    required this.tileRow,
    required this.tileCol,
  });

  Color get _lightVariant {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl.withLightness((hsl.lightness + 0.07).clamp(0.0, 1.0)).toColor();
  }

  Color get _darkVariant {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl.withLightness((hsl.lightness - 0.06).clamp(0.0, 1.0)).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = baseColor);

    final seed = tileRow * 19 + tileCol * 11;

    // Mottled blobs — give stone its uneven coloring.
    final blobPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 5; i++) {
      final bx = ((seed * (i + 3) * 7) % 80 + 10) / 100.0 * size.width;
      final by = ((seed * (i + 6) * 5) % 80 + 10) / 100.0 * size.height;
      final bw = size.width * (0.25 + (seed + i * 9) % 20 / 100.0);
      final bh = bw * (0.6 + (i % 4) * 0.15);
      blobPaint.color = _darkVariant.withAlpha(18 + i % 15);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(bx, by), width: bw, height: bh),
        blobPaint,
      );
    }

    // Cracks — angular jagged lines (1–2 per tile).
    final crackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final numCracks = 1 + seed % 2;
    for (int c = 0; c < numCracks; c++) {
      final startX = ((seed * (c + 2) * 7) % 60 + 20) / 100.0 * size.width;
      final startY = ((seed * (c + 5) * 3) % 25) / 100.0 * size.height;

      crackPaint
        ..color = _lightVariant.withAlpha(55 + c * 20)
        ..strokeWidth = 0.5 + (seed % 3) * 0.25;

      final path = Path()..moveTo(startX, startY);
      double x = startX, y = startY;
      final steps = 4 + seed % 3;
      for (int s = 0; s < steps; s++) {
        final dx = ((seed * (s + c + 1) * 13) % 18 - 9) / 100.0 * size.width;
        final dy = size.height / steps * (0.7 + (seed + s) % 5 * 0.08);
        x = (x + dx).clamp(0.0, size.width);
        y = (y + dy).clamp(0.0, size.height);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, crackPaint);
    }

    // Mineral speckles.
    final specklePaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 10; i++) {
      final sx = ((seed * (i + 2) * 11) % 88 + 6) / 100.0 * size.width;
      final sy = ((seed * (i + 4) * 7) % 88 + 6) / 100.0 * size.height;
      specklePaint.color = _lightVariant.withAlpha(25 + i % 25);
      canvas.drawCircle(Offset(sx, sy), 0.5 + (i % 3) * 0.4, specklePaint);
    }
  }

  @override
  bool shouldRepaint(_StoneTilePainter old) =>
      old.baseColor != baseColor ||
      old.tileRow != tileRow ||
      old.tileCol != tileCol;
}

// ---------------------------------------------------------------------------

class _ThroneOverlay extends StatefulWidget {
  final ThroneCosmetic cosmetic;
  const _ThroneOverlay({required this.cosmetic});

  @override
  State<_ThroneOverlay> createState() => _ThroneOverlayState();
}

class _ThroneOverlayState extends State<_ThroneOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _beat;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // ~72 bpm
      duration: const Duration(milliseconds: 833),
    );

    // Lub-dub rhythm: fast compress → partial release → smaller compress → full
    // release → long diastolic rest.
    _beat = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.00, end: 1.10), weight: 8),  // lub
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 1.04), weight: 7),  // release
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.08), weight: 6),  // dub
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.00), weight: 12), // relax
      TweenSequenceItem(tween: Tween(begin: 1.00, end: 1.00), weight: 67), // diastole
    ]).animate(_controller);

    if (widget.cosmetic.style == ThroneStyle.beatingHeart) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Asset override — works for all styles.
    if (widget.cosmetic.assetPath != null) {
      return Positioned.fill(
        child: Image.asset(widget.cosmetic.assetPath!, fit: BoxFit.contain),
      );
    }

    switch (widget.cosmetic.style) {
      case ThroneStyle.beatingHeart:
        return AnimatedBuilder(
          animation: _beat,
          builder: (_, __) => CustomPaint(
            painter: _HeartPainter(_beat.value),
            child: const SizedBox.expand(),
          ),
        );

      case ThroneStyle.classic:
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.cosmetic.fallbackColor.withAlpha(160),
              width: 3,
            ),
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Anatomical beating heart painter
// ---------------------------------------------------------------------------

class _HeartPainter extends CustomPainter {
  final double beat; // 1.0 = rest, 1.10 = peak systole

  _HeartPainter(this.beat);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();

    // Scale the whole heart from its visual centre for the beat effect.
    canvas.translate(w * 0.50, h * 0.52);
    canvas.scale(beat);
    canvas.translate(-w * 0.50, -h * 0.52);

    // ── Glow: brightens at peak systole ───────────────────────────────────
    final glowAlpha = ((beat - 1.0) / 0.10 * 140).round().clamp(0, 140);
    if (glowAlpha > 0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.49, h * 0.54),
          width: w * 0.72,
          height: h * 0.68,
        ),
        Paint()
          ..color = const Color(0xFFDC143C).withAlpha(glowAlpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.14),
      );
    }

    // ── Main body ─────────────────────────────────────────────────────────
    // Clockwise from the great-vessel junction at the top.
    // Coordinates are in [0,1] space then multiplied by w / h.
    //
    //  ┌──── left atrium ──── right atrium ────┐
    //  │        ╔══ aortic arch ══╗            │
    //  │  left  ║                ║  right      │
    //  │ ventricle               atrium        │
    //  │                         │             │
    //  └────────── apex ─────────┘
    final body = Path()
      ..moveTo(w * 0.51, h * 0.24)
      // right atrium sweep
      ..cubicTo(w * 0.76, h * 0.08, w * 0.92, h * 0.32, w * 0.82, h * 0.50)
      // right border → inferior border
      ..cubicTo(w * 0.74, h * 0.64, w * 0.62, h * 0.75, w * 0.52, h * 0.84)
      // apex (slightly left of centre)
      ..cubicTo(w * 0.48, h * 0.89, w * 0.40, h * 0.88, w * 0.37, h * 0.82)
      // up left side — left ventricle dominates
      ..cubicTo(w * 0.28, h * 0.68, w * 0.16, h * 0.50, w * 0.17, h * 0.35)
      // left atrium / pulmonary vein junction
      ..cubicTo(w * 0.17, h * 0.19, w * 0.30, h * 0.10, w * 0.42, h * 0.16)
      // back to start across the base
      ..cubicTo(w * 0.46, h * 0.20, w * 0.49, h * 0.22, w * 0.51, h * 0.24)
      ..close();

    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0xFF8B0000)
        ..style = PaintingStyle.fill,
    );

    // ── Left-ventricle highlight (lighter, gives roundness) ───────────────
    final lv = Path()
      ..moveTo(w * 0.35, h * 0.22)
      ..cubicTo(w * 0.20, h * 0.30, w * 0.20, h * 0.52, w * 0.30, h * 0.66)
      ..cubicTo(w * 0.38, h * 0.74, w * 0.46, h * 0.80, w * 0.50, h * 0.82)
      ..cubicTo(w * 0.42, h * 0.68, w * 0.28, h * 0.50, w * 0.34, h * 0.32)
      ..cubicTo(w * 0.36, h * 0.26, w * 0.37, h * 0.23, w * 0.35, h * 0.22)
      ..close();

    canvas.drawPath(
      lv,
      Paint()
        ..color = const Color(0xFFB22222).withAlpha(170)
        ..style = PaintingStyle.fill,
    );

    // ── Aortic arch ───────────────────────────────────────────────────────
    // A thick curved tube rising from the top-right of the body.
    final aorta = Path()
      ..moveTo(w * 0.51, h * 0.22)                          // inner base
      ..cubicTo(w * 0.58, h * 0.08, w * 0.78, h * 0.04, w * 0.82, h * 0.14) // arch top
      ..cubicTo(w * 0.86, h * 0.22, w * 0.80, h * 0.28, w * 0.74, h * 0.26) // descend right
      ..cubicTo(w * 0.72, h * 0.18, w * 0.62, h * 0.13, w * 0.58, h * 0.20) // inner curve
      ..cubicTo(w * 0.56, h * 0.22, w * 0.53, h * 0.23, w * 0.51, h * 0.22)
      ..close();

    canvas.drawPath(
      aorta,
      Paint()
        ..color = const Color(0xFF4A3560) // aorta is elastic / purplish
        ..style = PaintingStyle.fill,
    );

    // Aortic highlight
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.54, h * 0.17)
        ..cubicTo(w * 0.60, h * 0.07, w * 0.74, h * 0.06, w * 0.78, h * 0.14),
      Paint()
        ..color = const Color(0xFF7A66A0).withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.028
        ..strokeCap = StrokeCap.round,
    );

    // ── Pulmonary trunk (front, left of aorta) ────────────────────────────
    final pulm = Path()
      ..moveTo(w * 0.44, h * 0.20)
      ..cubicTo(w * 0.38, h * 0.08, w * 0.28, h * 0.06, w * 0.24, h * 0.14)
      ..cubicTo(w * 0.22, h * 0.20, w * 0.28, h * 0.26, w * 0.34, h * 0.24)
      ..cubicTo(w * 0.36, h * 0.16, w * 0.40, h * 0.14, w * 0.42, h * 0.20)
      ..close();

    canvas.drawPath(
      pulm,
      Paint()
        ..color = const Color(0xFF5C1A1A) // deoxygenated side — darker red
        ..style = PaintingStyle.fill,
    );

    // ── Coronary vessels ──────────────────────────────────────────────────
    final coronaryPaint = Paint()
      ..color = const Color(0xFFAA0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.030
      ..strokeCap = StrokeCap.round;

    // Left anterior descending (LAD) — runs in interventricular groove
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.50, h * 0.28)
        ..cubicTo(w * 0.52, h * 0.46, w * 0.50, h * 0.62, w * 0.46, h * 0.78),
      coronaryPaint,
    );

    // Circumflex — goes left along AV groove
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.50, h * 0.28)
        ..cubicTo(w * 0.36, h * 0.28, w * 0.24, h * 0.38, w * 0.22, h * 0.52),
      coronaryPaint,
    );

    // Right coronary artery
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.52, h * 0.28)
        ..cubicTo(w * 0.66, h * 0.30, w * 0.76, h * 0.44, w * 0.72, h * 0.60),
      coronaryPaint,
    );

    // ── Specular gleam on left ventricle ──────────────────────────────────
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.22, h * 0.28)
        ..cubicTo(w * 0.20, h * 0.36, w * 0.22, h * 0.46, w * 0.26, h * 0.54)
        ..cubicTo(w * 0.28, h * 0.46, w * 0.26, h * 0.36, w * 0.24, h * 0.28)
        ..close(),
      Paint()
        ..color = Colors.white.withAlpha(38)
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeartPainter old) => old.beat != beat;
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

    // Determine child based on style / asset.
    Widget pieceBody;
    if (cosmetic.assetPath != null) {
      pieceBody = ClipOval(
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(playerColor, BlendMode.modulate),
          child: Image.asset(cosmetic.assetPath!, fit: BoxFit.cover),
        ),
      );
    } else if (cosmetic.style == PieceStyle.wood) {
      pieceBody = ClipOval(
        child: CustomPaint(
          painter: _WoodPiecePainter(
              playerColor: playerColor, isMaster: isMaster),
          child: const SizedBox.expand(),
        ),
      );
    } else if (cosmetic.style == PieceStyle.stone) {
      pieceBody = ClipOval(
        child: CustomPaint(
          painter: _StonePiecePainter(
              playerColor: playerColor, isMaster: isMaster),
          child: const SizedBox.expand(),
        ),
      );
    } else {
      pieceBody = Center(
        child: Text(
          isMaster ? '★' : '●',
          style: TextStyle(
            color: Colors.white,
            fontSize:
                isMaster ? effectiveSize * 0.42 : effectiveSize * 0.32,
            height: 1,
          ),
        ),
      );
    }

    final usesCustomPainter = cosmetic.style != PieceStyle.classic;

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
          color: usesCustomPainter || cosmetic.assetPath != null
              ? null
              : playerColor,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(color: shadowColor, blurRadius: shadowBlur),
          ],
        ),
        child: pieceBody,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wood piece painter
// ---------------------------------------------------------------------------

class _WoodPiecePainter extends CustomPainter {
  final Color playerColor;
  final bool isMaster;
  const _WoodPiecePainter(
      {required this.playerColor, required this.isMaster});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final rect = Rect.fromCircle(center: center, radius: r);

    // Base: warm wood brown tinted toward player color.
    final base =
        Color.lerp(const Color(0xFFDEB887), playerColor, 0.38)!;
    canvas.drawCircle(center, r, Paint()..color = base);

    // Grain lines.
    final grainColor =
        Color.lerp(base, Colors.black, 0.22)!;
    final grainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 9; i++) {
      final y = (i / 9.0) * size.height;
      final waver = size.height * 0.06 * ((i % 2 == 0) ? 1 : -1);
      grainPaint
        ..color = grainColor.withAlpha(35 + i % 30)
        ..strokeWidth = 0.5 + (i % 3) * 0.2;
      final path = Path()
        ..moveTo(0, y)
        ..cubicTo(size.width * 0.3, y + waver, size.width * 0.7,
            y - waver * 0.6, size.width, y + waver * 0.3);
      canvas.drawPath(path, grainPaint);
    }

    // Highlight bevel — lighter at top-left, darker at bottom-right.
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.45),
          radius: 1.1,
          colors: [
            Colors.white.withAlpha(70),
            Colors.transparent,
            Colors.black.withAlpha(55),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    // Master/student mark.
    final markPaint = Paint()
      ..color = Colors.white.withAlpha(190)
      ..style = PaintingStyle.fill;
    if (isMaster) {
      // Diamond mark.
      final m = r * 0.32;
      final path = Path()
        ..moveTo(center.dx, center.dy - m)
        ..lineTo(center.dx + m * 0.65, center.dy)
        ..lineTo(center.dx, center.dy + m)
        ..lineTo(center.dx - m * 0.65, center.dy)
        ..close();
      canvas.drawPath(path, markPaint);
    } else {
      canvas.drawCircle(center, r * 0.18, markPaint);
    }
  }

  @override
  bool shouldRepaint(_WoodPiecePainter old) =>
      old.playerColor != playerColor || old.isMaster != isMaster;
}

// ---------------------------------------------------------------------------
// Stone piece painter
// ---------------------------------------------------------------------------

class _StonePiecePainter extends CustomPainter {
  final Color playerColor;
  final bool isMaster;
  const _StonePiecePainter(
      {required this.playerColor, required this.isMaster});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final rect = Rect.fromCircle(center: center, radius: r);

    // Base: cool grey tinted toward player color.
    final base =
        Color.lerp(const Color(0xFF8A8078), playerColor, 0.32)!;
    canvas.drawCircle(center, r, Paint()..color = base);

    final seed = playerColor.r.toInt() * 3 + (isMaster ? 7 : 0);

    // Mottled blobs.
    final darkVar = Color.lerp(base, Colors.black, 0.15)!;
    final blobPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 4; i++) {
      final bx = ((seed * (i + 3) * 7) % 60 + 20) / 100.0 * size.width;
      final by = ((seed * (i + 6) * 5) % 60 + 20) / 100.0 * size.height;
      blobPaint.color = darkVar.withAlpha(18 + i % 14);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(bx, by),
            width: r * 0.7,
            height: r * 0.45),
        blobPaint,
      );
    }

    // Crack line.
    final lightVar = Color.lerp(base, Colors.white, 0.15)!;
    final crackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = lightVar.withAlpha(60);
    final cx = ((seed * 11) % 40 + 30) / 100.0 * size.width;
    final path = Path()..moveTo(cx, 0);
    double x = cx, y = 0;
    for (int s = 0; s < 4; s++) {
      x = (x + ((seed * (s + 2) * 13) % 14 - 7) / 100.0 * size.width)
          .clamp(0.0, size.width);
      y += size.height / 4;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, crackPaint);

    // Speckles.
    for (int i = 0; i < 8; i++) {
      final sx = ((seed * (i + 2) * 11) % 80 + 10) / 100.0 * size.width;
      final sy = ((seed * (i + 4) * 7) % 80 + 10) / 100.0 * size.height;
      canvas.drawCircle(Offset(sx, sy), 0.6 + (i % 3) * 0.3,
          Paint()..color = lightVar.withAlpha(28 + i % 20));
    }

    // Highlight bevel.
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          radius: 1.15,
          colors: [
            Colors.white.withAlpha(60),
            Colors.transparent,
            Colors.black.withAlpha(65),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
    );

    // Master/student mark.
    final markPaint = Paint()
      ..color = Colors.white.withAlpha(185)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    if (isMaster) {
      // Carved ring.
      canvas.drawCircle(center, r * 0.3, markPaint);
      canvas.drawCircle(center, r * 0.1,
          Paint()..color = Colors.white.withAlpha(185));
    } else {
      canvas.drawCircle(center, r * 0.18,
          Paint()..color = Colors.white.withAlpha(160));
    }
  }

  @override
  bool shouldRepaint(_StonePiecePainter old) =>
      old.playerColor != playerColor || old.isMaster != isMaster;
}

// ---------------------------------------------------------------------------
// Fan hand — MTG-style fanned card hand
// ---------------------------------------------------------------------------

class _FanHand extends StatelessWidget {
  final List<CardDefinition> hand;
  final CardDefinition? pendingCard;
  final bool isActive;
  final double scale;
  final void Function(CardDefinition) onCardTap;

  const _FanHand({
    required this.hand,
    required this.pendingCard,
    required this.isActive,
    required this.scale,
    required this.onCardTap,
  });

  static const double _overlapFraction = 0.10;

  double get _cardW => 76.0 * scale;
  double get _cardH => 100.0 * scale;
  double get _step  => _cardW * (1.0 - _overlapFraction);

  double _angleForIndex(int i, int n) {
    if (n <= 1) return 0;
    // spread cards across ±9° total (18° fan)
    return (i / (n - 1) - 0.5) * (18.0 * pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    final n = hand.length;
    if (n == 0) return SizedBox(height: _cardH);

    // Each card is offset horizontally so only 10% overlaps with its neighbour.
    final totalW = _cardW + (n - 1) * _step;
    final totalH = _cardH + 30.0; // extra room for rotation/lift

    return SizedBox(
      width: totalW,
      height: totalH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < n; i++)
            Positioned(
              left: i * _step,
              bottom: 0,
              child: Transform.rotate(
                angle: _angleForIndex(i, n),
                alignment: Alignment.bottomCenter,
                child: _HandCard(
                  card: hand[i],
                  isPending: pendingCard == hand[i],
                  isActive: isActive,
                  scale: scale,
                  onTap: isActive && pendingCard != hand[i]
                      ? () => onCardTap(hand[i])
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hand card — single scaled card in the fan, hover-lifts and dims when pending
// ---------------------------------------------------------------------------

class _HandCard extends StatefulWidget {
  final CardDefinition card;
  final bool isPending;
  final bool isActive;
  final double scale;
  final VoidCallback? onTap;

  const _HandCard({
    required this.card,
    required this.isPending,
    required this.isActive,
    required this.scale,
    this.onTap,
  });

  @override
  State<_HandCard> createState() => _HandCardState();
}

class _HandCardState extends State<_HandCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final liftPx = widget.isPending ? 22.0 : (_hovering ? 16.0 : 0.0);
    final opacity = widget.isPending ? 0.35 : 1.0;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: opacity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            transform: Matrix4.translationValues(0, -liftPx, 0),
            child: Transform.scale(
              scale: widget.scale,
              alignment: Alignment.bottomCenter,
              child: CardWidget(
                card: widget.card,
                selected: false,
                dimmed: !widget.isActive,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating card — bobbing selected card shown in the board gutter
// ---------------------------------------------------------------------------

class _FloatingCard extends StatefulWidget {
  final CardDefinition card;
  final double displayW;

  const _FloatingCard({required this.card, required this.displayW});

  // Aspect ratio always locked at 76:100 (CardWidget native ratio).
  double get displayH => displayW * 100.0 / 76.0;

  @override
  State<_FloatingCard> createState() => _FloatingCardState();
}

class _FloatingCardState extends State<_FloatingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bob;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _bob = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -6.0 + _bob.value * 12.0),
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withAlpha(130),
              blurRadius: 18,
              spreadRadius: 3,
            ),
          ],
        ),
        // SizedBox locks the aspect ratio; FittedBox scales CardWidget to fill it.
        child: SizedBox(
          width: widget.displayW,
          height: widget.displayH,   // locked: displayW * 100/76
          child: FittedBox(
            fit: BoxFit.contain,
            child: CardWidget(card: widget.card, selected: true),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Table card — community card shown in right scenery area with turn arrows
// ---------------------------------------------------------------------------

class _TableCard extends StatelessWidget {
  final CardDefinition card;
  final Player currentTurn;

  final double displayW;

  const _TableCard({
    required this.card,
    required this.currentTurn,
    required this.displayW,
  });

  // Aspect ratio always locked at 76:100 (CardWidget native ratio).
  double get displayH => displayW * 100.0 / 76.0;

  @override
  Widget build(BuildContext context) {
    const blueColor = Color(0xFF4169E1);
    const redColor = Color(0xFFDC143C);

    final blueActive = currentTurn == Player.blue;
    final redActive = currentTurn == Player.red;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Up arrow — Blue is at the top of the board
        Icon(
          Icons.keyboard_arrow_up_rounded,
          size: 28,
          color: blueActive ? blueColor : Colors.white24,
        ),
        // SizedBox locks the aspect ratio; FittedBox scales CardWidget to fill it.
        SizedBox(
          width: displayW,
          height: displayH,    // locked: displayW * 100/76
          child: FittedBox(
            fit: BoxFit.contain,
            child: CardWidget(card: card, dimmed: true),
          ),
        ),
        // Down arrow — Red is at the bottom of the board
        Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 28,
          color: redActive ? redColor : Colors.white24,
        ),
      ],
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
