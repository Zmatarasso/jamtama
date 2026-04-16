import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// CardPlayStyle — how a card flies out of the hand when a move is confirmed
// ---------------------------------------------------------------------------

enum CardPlayStyle {
  /// Fast, direct arc — aggressive lunge forward.
  lunge,

  /// Wide sweeping arc with rotation — heavy, spinning weapons.
  sweep,

  /// Slow, high arc that drops hard — overhead slam weapons.
  slam,

  /// Quick, flat straight shot — piercing weapons.
  pierce,

  /// Slow, graceful float — light or precise weapons.
  drift,
}

/// Animation parameters for a [CardPlayStyle].
class CardPlayParams {
  final Duration duration;
  final Curve curve;

  /// How high above the card origin the arc peaks (as fraction of screen height).
  final double arcHeight;

  /// How much the card rotates (radians) during flight.
  final double rotation;

  const CardPlayParams({
    required this.duration,
    required this.curve,
    required this.arcHeight,
    required this.rotation,
  });
}

const cardPlayParams = <CardPlayStyle, CardPlayParams>{
  CardPlayStyle.lunge: CardPlayParams(
    duration: Duration(milliseconds: 280),
    curve: Curves.easeInCubic,
    arcHeight: 0.08,
    rotation: 0.2,
  ),
  CardPlayStyle.sweep: CardPlayParams(
    duration: Duration(milliseconds: 420),
    curve: Curves.easeInOut,
    arcHeight: 0.15,
    rotation: 1.2,
  ),
  CardPlayStyle.slam: CardPlayParams(
    duration: Duration(milliseconds: 500),
    curve: Curves.easeInExpo,
    arcHeight: 0.25,
    rotation: 0.0,
  ),
  CardPlayStyle.pierce: CardPlayParams(
    duration: Duration(milliseconds: 180),
    curve: Curves.easeIn,
    arcHeight: 0.04,
    rotation: 0.0,
  ),
  CardPlayStyle.drift: CardPlayParams(
    duration: Duration(milliseconds: 600),
    curve: Curves.easeInOut,
    arcHeight: 0.12,
    rotation: -0.4,
  ),
};

// ---------------------------------------------------------------------------
// PieceMoveEffect — how the piece travels across the board after a move
// ---------------------------------------------------------------------------

enum PieceMoveEffect {
  /// Heavy, slow arc — lands with a shockwave crack on the tile.
  stomp,

  /// Fast rotation during travel — spins and chops into the square.
  slash,

  /// Low, fast slide — charge/dash across the board.
  charge,

  /// Smooth bezier curve — elegant, controlled glide.
  glide,

  /// Piece rotates continuously while moving.
  spin,

  /// Fast straight dart — no arc, maximum speed.
  pierce,
}

/// Animation parameters for a [PieceMoveEffect].
class PieceMoveParams {
  final Duration duration;
  final Curve curve;

  /// Arc height as a multiple of the cell size (0 = straight line).
  final double arcFactor;

  /// Full rotations the piece completes during travel.
  final double rotations;

  /// Whether to show an impact effect on landing.
  final bool hasImpact;

  const PieceMoveParams({
    required this.duration,
    required this.curve,
    required this.arcFactor,
    required this.rotations,
    required this.hasImpact,
  });
}

const pieceMoveParams = <PieceMoveEffect, PieceMoveParams>{
  PieceMoveEffect.stomp: PieceMoveParams(
    duration: Duration(milliseconds: 480),
    curve: Curves.easeInExpo,
    arcFactor: 1.6,
    rotations: 0.0,
    hasImpact: true, // crack / shockwave hook
  ),
  PieceMoveEffect.slash: PieceMoveParams(
    duration: Duration(milliseconds: 320),
    curve: Curves.easeInCubic,
    arcFactor: 0.4,
    rotations: 0.75,
    hasImpact: true, // slash mark hook
  ),
  PieceMoveEffect.charge: PieceMoveParams(
    duration: Duration(milliseconds: 220),
    curve: Curves.easeIn,
    arcFactor: 0.0,
    rotations: 0.0,
    hasImpact: false,
  ),
  PieceMoveEffect.glide: PieceMoveParams(
    duration: Duration(milliseconds: 400),
    curve: Curves.easeInOut,
    arcFactor: 0.3,
    rotations: 0.0,
    hasImpact: false,
  ),
  PieceMoveEffect.spin: PieceMoveParams(
    duration: Duration(milliseconds: 360),
    curve: Curves.easeInOut,
    arcFactor: 0.2,
    rotations: 1.5,
    hasImpact: false,
  ),
  PieceMoveEffect.pierce: PieceMoveParams(
    duration: Duration(milliseconds: 160),
    curve: Curves.linear,
    arcFactor: 0.0,
    rotations: 0.0,
    hasImpact: false,
  ),
};
