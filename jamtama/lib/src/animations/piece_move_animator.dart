import 'dart:math' show pi;

import 'package:flutter/material.dart';

import 'card_animation_styles.dart';

// ---------------------------------------------------------------------------
// PieceMoveAnimator
//
// Renders a piece sliding from [startOffset] to [endOffset] (both in the
// coordinate space of the board Stack). The piece follows a parabolic arc
// whose height is determined by [PieceMoveParams.arcFactor] × cell size,
// and rotates by [params.rotations] full turns during flight.
//
// Usage: add to a Stack that covers the board. When the animation completes
// [onDone] is called so the caller can remove the widget.
//
// To upgrade later: replace the Circle painter with a custom piece sprite,
// add a particle trail, or trigger an impact CustomPainter on landing.
// ---------------------------------------------------------------------------

class PieceMoveAnimator extends StatefulWidget {
  final Offset startOffset;
  final Offset endOffset;
  final Color pieceColor;
  final double pieceRadius;
  final PieceMoveEffect effect;
  final VoidCallback onDone;

  const PieceMoveAnimator({
    super.key,
    required this.startOffset,
    required this.endOffset,
    required this.pieceColor,
    required this.pieceRadius,
    required this.effect,
    required this.onDone,
  });

  @override
  State<PieceMoveAnimator> createState() => _PieceMoveAnimatorState();
}

class _PieceMoveAnimatorState extends State<PieceMoveAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  late PieceMoveParams _params;

  @override
  void initState() {
    super.initState();
    _params = pieceMoveParams[widget.effect]!;
    _ctrl = AnimationController(vsync: this, duration: _params.duration);
    _progress = CurvedAnimation(parent: _ctrl, curve: _params.curve);
    _ctrl.forward().then((_) {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (_, __) {
        final t = _progress.value;
        final dx = widget.startOffset.dx +
            (widget.endOffset.dx - widget.startOffset.dx) * t;

        // Parabolic arc: peak at t=0.5
        final distance = (widget.endOffset - widget.startOffset).distance;
        final arcHeight = distance * _params.arcFactor;
        final dy = widget.startOffset.dy +
            (widget.endOffset.dy - widget.startOffset.dy) * t -
            arcHeight * 4 * t * (1 - t);

        final rotation = _params.rotations * 2 * pi * t;

        return Positioned(
          left: dx - widget.pieceRadius,
          top: dy - widget.pieceRadius,
          child: Transform.rotate(
            angle: rotation,
            child: _PieceCircle(
              radius: widget.pieceRadius,
              color: widget.pieceColor,
              effect: widget.effect,
              progress: t,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _PieceCircle — the piece visual during animation.
// Currently a plain circle; upgrade path: swap in a piece sprite or add
// a motion-blur / trail effect here based on the effect type.
// ---------------------------------------------------------------------------

class _PieceCircle extends StatelessWidget {
  final double radius;
  final Color color;
  final PieceMoveEffect effect;
  final double progress;

  const _PieceCircle({
    required this.radius,
    required this.color,
    required this.effect,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(radius * 2, radius * 2),
      painter: _PieceMovePainter(
        color: color,
        effect: effect,
        progress: progress,
      ),
    );
  }
}

class _PieceMovePainter extends CustomPainter {
  final Color color;
  final PieceMoveEffect effect;
  final double progress;

  _PieceMovePainter({
    required this.color,
    required this.effect,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Shadow grows on approach to landing.
    final shadowOpacity = (progress * 0.4).clamp(0.0, 0.4);
    canvas.drawCircle(
      center + const Offset(2, 3),
      radius * 0.9,
      Paint()..color = Colors.black.withAlpha((shadowOpacity * 255).round()),
    );

    // Main piece circle.
    canvas.drawCircle(center, radius, Paint()..color = color);

    // Inner highlight.
    canvas.drawCircle(
      center - Offset(radius * 0.25, radius * 0.25),
      radius * 0.35,
      Paint()..color = Colors.white.withAlpha(60),
    );

    // ── Effect-specific trail / aura ──────────────────────────────────────
    // TODO: replace each branch with particle systems, shaders, or sprites.
    switch (effect) {
      case PieceMoveEffect.stomp:
        // Red aura that pulses — hints at the impact to come.
        canvas.drawCircle(
          center,
          radius * (1.2 + progress * 0.3),
          Paint()
            ..color = Colors.red.withAlpha(((1 - progress) * 60).round())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      case PieceMoveEffect.slash:
        // Arc trail on the leading edge.
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius * 1.3),
          -0.8, 1.6, false,
          Paint()
            ..color = Colors.white.withAlpha(((1 - progress) * 80).round())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      case PieceMoveEffect.charge:
        // Horizontal speed lines behind the piece.
        final paint = Paint()
          ..color = color.withAlpha(((1 - progress) * 120).round())
          ..strokeWidth = 1.5;
        for (var i = 1; i <= 3; i++) {
          final offset = i * radius * 0.5;
          canvas.drawLine(
            Offset(-offset, size.height * 0.3),
            Offset(-offset - radius, size.height * 0.3),
            paint,
          );
          canvas.drawLine(
            Offset(-offset, size.height * 0.7),
            Offset(-offset - radius * 0.7, size.height * 0.7),
            paint,
          );
        }
      case PieceMoveEffect.spin:
        // Spinning ring.
        canvas.drawCircle(
          center,
          radius * 1.15,
          Paint()
            ..color = color.withAlpha(80)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(_PieceMovePainter old) =>
      old.progress != progress || old.color != color;
}

// ---------------------------------------------------------------------------
// ImpactPainter — shown briefly on the destination cell after landing.
// Hook: replace with a crack sprite, shockwave shader, or slash mark SVG.
// ---------------------------------------------------------------------------

class ImpactOverlay extends StatefulWidget {
  final Offset center;
  final double cellSize;
  final PieceMoveEffect effect;
  final VoidCallback onDone;

  const ImpactOverlay({
    super.key,
    required this.center,
    required this.cellSize,
    required this.effect,
    required this.onDone,
  });

  @override
  State<ImpactOverlay> createState() => _ImpactOverlayState();
}

class _ImpactOverlayState extends State<ImpactOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _ctrl.forward().then((_) {
      if (mounted) widget.onDone();
    });
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
      builder: (_, __) => Positioned(
        left: widget.center.dx - widget.cellSize,
        top: widget.center.dy - widget.cellSize,
        child: CustomPaint(
          size: Size(widget.cellSize * 2, widget.cellSize * 2),
          painter: _ImpactPainter(
            effect: widget.effect,
            progress: _ctrl.value,
          ),
        ),
      ),
    );
  }
}

class _ImpactPainter extends CustomPainter {
  final PieceMoveEffect effect;
  final double progress;

  _ImpactPainter({required this.effect, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final fade = (1 - progress).clamp(0.0, 1.0);

    // TODO: swap these placeholder rings with crack sprites or shader effects.
    switch (effect) {
      case PieceMoveEffect.stomp:
        // Expanding shockwave rings.
        for (var i = 0; i < 3; i++) {
          final r = (size.width * 0.3) * (progress + i * 0.15);
          canvas.drawCircle(
            center, r,
            Paint()
              ..color = Colors.brown.withAlpha((fade * 80).round())
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3 - i.toDouble(),
          );
        }
      case PieceMoveEffect.slash:
        // Slash arc expanding outward.
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: size.width * 0.4 * progress),
          -1.0, 2.0, false,
          Paint()
            ..color = Colors.white.withAlpha((fade * 120).round())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      default:
        // Simple fade ring for other effects.
        canvas.drawCircle(
          center,
          size.width * 0.35 * progress,
          Paint()
            ..color = Colors.white.withAlpha((fade * 60).round())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
    }
  }

  @override
  bool shouldRepaint(_ImpactPainter old) => old.progress != progress;
}
