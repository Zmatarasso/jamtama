import 'package:flutter/material.dart';

/// Cosmetic for the face-down side of a card (opponent's hand, deck reveals,
/// draft face-down states).
///
/// [assetPath] is a card-back image. When null, a programmatic pattern using
/// [fallbackColor] and [fallbackPatternColor] is rendered instead.
class CardBackCosmetic {
  final String id;
  final String name;
  final String? assetPath;
  final Color fallbackColor;
  final Color fallbackPatternColor;

  const CardBackCosmetic({
    required this.id,
    required this.name,
    this.assetPath,
    required this.fallbackColor,
    required this.fallbackPatternColor,
  });
}
