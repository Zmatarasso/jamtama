import 'package:flutter/material.dart';

/// How individual tiles are rendered on the board.
/// [flat] uses a solid color (default).
/// [woodGrain] draws procedural grain lines on top of the tile color.
enum BoardTileStyle { flat, woodGrain, stone }

/// Cosmetic data for the 5×5 board surface.
///
/// Asset paths (optional) override the programmatic color fallbacks when set.
/// This allows swapping between procedural looks (wood, stone, tatami) via
/// colors alone, or providing high-fidelity tile images for premium cosmetics.
class BoardCosmetic {
  final String id;
  final String name;

  // --- Optional image assets (null = use color fallbacks) ---
  final String? lightTileAsset;
  final String? darkTileAsset;
  final String? templeTileAsset;
  final String? borderAsset;

  // --- Programmatic fallback colors (always present) ---
  final Color lightTileColor;
  final Color darkTileColor;
  final Color templeHighlightColor;
  final Color backgroundColor;
  final Color validMoveColor;
  final Color hoverColor;
  final BoardTileStyle tileStyle;

  const BoardCosmetic({
    required this.id,
    required this.name,
    this.lightTileAsset,
    this.darkTileAsset,
    this.templeTileAsset,
    this.borderAsset,
    required this.lightTileColor,
    required this.darkTileColor,
    required this.templeHighlightColor,
    required this.backgroundColor,
    required this.validMoveColor,
    required this.hoverColor,
    this.tileStyle = BoardTileStyle.flat,
  });

  BoardCosmetic copyWith({
    String? id,
    String? name,
    String? lightTileAsset,
    String? darkTileAsset,
    String? templeTileAsset,
    String? borderAsset,
    Color? lightTileColor,
    Color? darkTileColor,
    Color? templeHighlightColor,
    Color? backgroundColor,
    Color? validMoveColor,
    Color? hoverColor,
  }) =>
      BoardCosmetic(
        id: id ?? this.id,
        name: name ?? this.name,
        lightTileAsset: lightTileAsset ?? this.lightTileAsset,
        darkTileAsset: darkTileAsset ?? this.darkTileAsset,
        templeTileAsset: templeTileAsset ?? this.templeTileAsset,
        borderAsset: borderAsset ?? this.borderAsset,
        lightTileColor: lightTileColor ?? this.lightTileColor,
        darkTileColor: darkTileColor ?? this.darkTileColor,
        templeHighlightColor: templeHighlightColor ?? this.templeHighlightColor,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        validMoveColor: validMoveColor ?? this.validMoveColor,
        hoverColor: hoverColor ?? this.hoverColor,
      );
}
