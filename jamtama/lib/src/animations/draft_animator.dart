import 'dart:math' show Random;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// DeckShuffleAnimator
//
// Shows a brief shuffle animation: a stack of face-down cards fans out
// slightly then snaps back before the deal begins. Call [onDone] to
// transition to the deal phase.
// ---------------------------------------------------------------------------

class DeckShuffleAnimator extends StatefulWidget {
  final VoidCallback onDone;

  const DeckShuffleAnimator({super.key, required this.onDone});

  @override
  State<DeckShuffleAnimator> createState() => _DeckShuffleAnimatorState();
}

class _DeckShuffleAnimatorState extends State<DeckShuffleAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fan;
  late Animation<double> _collapse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Fan out 0→0.5, collapse back 0.5→1.0
    _fan = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _collapse = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
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
      builder: (_, __) {
        final spreadT = _fan.value - _collapse.value;
        return Center(
          child: SizedBox(
            width: 200,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(6, (i) {
                final baseAngle = (i - 2.5) * 0.18; // fan spread
                final angle = baseAngle * spreadT;
                final lift = (i * 2.0) * spreadT;
                return Transform.translate(
                  offset: Offset(0, -lift),
                  child: Transform.rotate(
                    angle: angle,
                    child: _FaceDownCard(index: i),
                  ),
                );
              }).reversed.toList(),
            ),
          ),
        );
      },
    );
  }
}

class _FaceDownCard extends StatelessWidget {
  final int index;
  const _FaceDownCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF1A0F08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF8B6914).withAlpha(180),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(2, 3)),
        ],
      ),
      child: const Center(
        child: Icon(Icons.shield, color: Color(0xFF8B6914), size: 28),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CardDealAnimator
//
// Animates [count] cards flying in from a central deck position to their
// final laid-out positions in the draft row. Cards deal one after another
// with a short stagger between each.
// ---------------------------------------------------------------------------

class CardDealAnimator extends StatefulWidget {
  /// Number of cards to deal.
  final int count;

  /// Final positions of each card in screen space.
  final List<Offset> destinations;

  /// The deck's screen-space center (cards fly out from here).
  final Offset deckCenter;

  /// Called when all cards have finished dealing.
  final VoidCallback onDone;

  const CardDealAnimator({
    super.key,
    required this.count,
    required this.destinations,
    required this.deckCenter,
    required this.onDone,
  });

  @override
  State<CardDealAnimator> createState() => _CardDealAnimatorState();
}

class _CardDealAnimatorState extends State<CardDealAnimator>
    with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];
  final List<Animation<double>> _progresses = [];
  // ignore: unused_field — reserved for future per-card random variation
  final _rng = Random();
  int _doneCount = 0;

  static const _stagger = Duration(milliseconds: 120);
  static const _cardDuration = Duration(milliseconds: 380);

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.count; i++) {
      final ctrl = AnimationController(vsync: this, duration: _cardDuration);
      final anim = CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic);
      _ctrls.add(ctrl);
      _progresses.add(anim);

      final delay = _stagger * i;
      Future.delayed(delay, () {
        if (mounted) {
          ctrl.forward().then((_) {
            _doneCount++;
            if (_doneCount == widget.count && mounted) widget.onDone();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.count, (i) {
        final dest = widget.destinations[i];
        return AnimatedBuilder(
          animation: _progresses[i],
          builder: (_, __) {
            final t = _progresses[i].value;
            // Slight random initial rotation that settles to near-zero.
            final startAngle = (i % 2 == 0 ? 1 : -1) * 0.3;
            final angle = startAngle * (1 - t);

            final dx = widget.deckCenter.dx +
                (dest.dx - widget.deckCenter.dx) * t;
            final dy = widget.deckCenter.dy +
                (dest.dy - widget.deckCenter.dy) * t -
                30 * (1 - t) * t * 4; // small arc

            return Positioned(
              left: dx - 35,
              top: dy - 50,
              child: Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: angle,
                  child: _FaceDownCard(index: i),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// RoundOverDialogAnimator
//
// Wraps any child widget with a scale + fade entrance. Use as the builder
// for RoundOverDialog to give it a dramatic entrance.
// Win and loss have different animation personalities.
// ---------------------------------------------------------------------------

class RoundOverEntrance extends StatefulWidget {
  final Widget child;
  final bool isWin;

  const RoundOverEntrance({
    super.key,
    required this.child,
    required this.isWin,
  });

  @override
  State<RoundOverEntrance> createState() => _RoundOverEntranceState();
}

class _RoundOverEntranceState extends State<RoundOverEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.isWin
          ? const Duration(milliseconds: 520)
          : const Duration(milliseconds: 380),
    );

    if (widget.isWin) {
      // Win: punchy overshoot bounce.
      _scale = TweenSequence([
        TweenSequenceItem(
          tween: Tween(begin: 0.5, end: 1.08)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 70,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.08, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 30,
        ),
      ]).animate(_ctrl);
    } else {
      // Loss: drop in from above, no bounce.
      _scale = Tween(begin: 0.85, end: 1.0)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    }

    _fade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slide = Tween(begin: widget.isWin ? 20.0 : -20.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    _ctrl.forward();
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
      builder: (_, child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        ),
      ),
      child: widget.child,
    );
  }
}
