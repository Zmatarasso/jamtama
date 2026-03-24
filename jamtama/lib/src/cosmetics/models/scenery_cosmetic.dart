import 'package:flutter/material.dart';

/// Cosmetic for the environment surrounding the board — backgrounds, scenery
/// layers (grassy meadow, city, castle, etc.).
///
/// [backgroundAsset] is a full-bleed image rendered behind the board.
/// When null, [backgroundColor] is used as a solid fill.
/// [ambientTint] is an optional color overlay applied to the whole scene at
/// low opacity to unify lighting across all elements.
class SceneryCosmetic {
  final String id;
  final String name;
  final String? backgroundAsset;
  final Color backgroundColor;
  final Color ambientTint;

  const SceneryCosmetic({
    required this.id,
    required this.name,
    this.backgroundAsset,
    required this.backgroundColor,
    this.ambientTint = Colors.transparent,
  });
}
