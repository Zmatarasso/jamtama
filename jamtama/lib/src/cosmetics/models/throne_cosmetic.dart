import 'package:flutter/material.dart';

/// Which programmatic style to use when [ThroneCosmetic.assetPath] is null.
enum ThroneStyle {
  /// Concentric ring in [ThroneCosmetic.fallbackColor].
  classic,

  /// Animated anatomical beating heart.
  beatingHeart,
}

/// Cosmetic for the throne marker placed on each player's starting square
/// (row 0 col 2 for Red, row 4 col 2 for Blue).
///
/// [assetPath] is an image asset rendered as an overlay on the temple tile.
/// When null, [style] controls the programmatic fallback.
class ThroneCosmetic {
  final String id;
  final String name;
  final String? assetPath;
  final Color fallbackColor;
  final ThroneStyle style;

  const ThroneCosmetic({
    required this.id,
    required this.name,
    this.assetPath,
    required this.fallbackColor,
    this.style = ThroneStyle.classic,
  });
}
