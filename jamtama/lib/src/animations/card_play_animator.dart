import 'package:flutter/material.dart';

import '../models/card.dart';
import 'card_animation_styles.dart';

// ---------------------------------------------------------------------------
// CardPlayAnimator
//
// Animates a card flying from [startOffset] (hand position) toward
// [endOffset] (board center) when a move is confirmed. The card follows a
// parabolic arc, rotates according to its [CardPlayStyle], and fades out
// as it approaches the destination.
//
// Upgrade path: replace the card widget child with a 3D-flipping widget,
// add particle trails, or trigger a screen shake via a callback.
// ---------------------------------------------------------------------------

class CardPlayAnimator extends StatefulWidget {
  final Offset startOffset;
  final Offset endOffset;
  final CardDefinition card;
  final Size cardSize;
  final VoidCallback onDone;

  const CardPlayAnimator({
    super.key,
    required this.startOffset,
    required this.endOffset,
    required this.card,
    required this.cardSize,
    required this.onDone,
  });

  @override
  State<CardPlayAnimator> createState() => _CardPlayAnimatorState();
}

class _CardPlayAnimatorState extends State<CardPlayAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  late CardPlayParams _params;

  @override
  void initState() {
    super.initState();
    _params = cardPlayParams[widget.card.playStyle]!;
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
    final screenH = MediaQuery.sizeOf(context).height;

    return AnimatedBuilder(
      animation: _progress,
      builder: (_, __) {
        final t = _progress.value;
        final dx = widget.startOffset.dx +
            (widget.endOffset.dx - widget.startOffset.dx) * t -
            widget.cardSize.width / 2;

        final arcHeight = screenH * _params.arcHeight;
        final dy = widget.startOffset.dy +
            (widget.endOffset.dy - widget.startOffset.dy) * t -
            arcHeight * 4 * t * (1 - t) -
            widget.cardSize.height / 2;

        final rotation = _params.rotation * t;
        final opacity = t < 0.7 ? 1.0 : (1.0 - t) / 0.3;

        return Positioned(
          left: dx,
          top: dy,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: rotation,
              child: _MiniCard(card: widget.card, size: widget.cardSize),
            ),
          ),
        );
      },
    );
  }
}

class _MiniCard extends StatelessWidget {
  final CardDefinition card;
  final Size size;
  const _MiniCard({required this.card, required this.size});

  @override
  Widget build(BuildContext context) {
    // TODO: swap with a proper CardWidget once art is in place.
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: const Color(0xFF1A0F08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: card.stampColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: card.stampColor.withAlpha(120),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          card.name,
          style: TextStyle(
            color: card.stampColor,
            fontSize: size.width * 0.12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KingCaptureHook
//
// Called when a King piece is captured. Currently shows a dramatic
// scale-out + fade effect. Upgrade path: replace the builder with a
// video_player widget playing a short capture clip per piece cosmetic.
// ---------------------------------------------------------------------------

class KingCaptureOverlay extends StatefulWidget {
  /// Screen-space center of the captured king's cell.
  final Offset kingCenter;

  /// Color of the captured king's player.
  final Color kingColor;

  final VoidCallback onDone;

  const KingCaptureOverlay({
    super.key,
    required this.kingCenter,
    required this.kingColor,
    required this.onDone,
  });

  @override
  State<KingCaptureOverlay> createState() => _KingCaptureOverlayState();
}

class _KingCaptureOverlayState extends State<KingCaptureOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scale = Tween(begin: 1.0, end: 3.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _fade = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
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
        left: widget.kingCenter.dx - 40,
        top: widget.kingCenter.dy - 40,
        child: Opacity(
          opacity: _fade.value,
          child: Transform.scale(
            scale: _scale.value,
            child: _KingCapturePainter(color: widget.kingColor),
          ),
        ),
      ),
    );
  }
}

class _KingCapturePainter extends StatelessWidget {
  final Color color;
  const _KingCapturePainter({required this.color});

  @override
  Widget build(BuildContext context) {
    // TODO: replace with video_player widget or sprite sheet animation.
    // The hook is here — just swap this builder's return value.
    return CustomPaint(
      size: const Size(80, 80),
      painter: _CrownBurstPainter(color: color),
    );
  }
}

class _CrownBurstPainter extends CustomPainter {
  final Color color;
  _CrownBurstPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Burst lines radiating from center — placeholder for explosion sprite.
    for (var i = 0; i < 8; i++) {
      final cos = [1.0, 0.707, 0.0, -0.707, -1.0, -0.707, 0.0, 0.707][i];
      final sin = [0.0, 0.707, 1.0, 0.707, 0.0, -0.707, -1.0, -0.707][i];
      canvas.drawLine(
        center + Offset(cos * 12, sin * 12),
        center + Offset(cos * 36, sin * 36),
        paint,
      );
    }

    canvas.drawCircle(center, 8, Paint()..color = color);
    canvas.drawCircle(
      center, 14,
      Paint()
        ..color = color.withAlpha(120)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_CrownBurstPainter old) => old.color != color;
}
