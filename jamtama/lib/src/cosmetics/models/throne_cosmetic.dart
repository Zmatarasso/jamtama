import 'package:flutter/material.dart';

/// Cosmetic for the throne marker placed on each player's starting square
/// (row 0 col 2 for Red, row 4 col 2 for Blue).
///
/// [assetPath] is an image asset rendered as an overlay on the temple tile.
/// When null, a programmatic indicator using [fallbackColor] is shown instead.
class ThroneCosmetic {
  final String id;
  final String name;
  final String? assetPath;
  final Color fallbackColor;

  const ThroneCosmetic({
    required this.id,
    required this.name,
    this.assetPath,
    required this.fallbackColor,
  });
}
