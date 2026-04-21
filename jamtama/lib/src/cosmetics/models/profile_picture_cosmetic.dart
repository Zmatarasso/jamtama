import 'package:flutter/material.dart';

/// Cosmetic representing the player's avatar — shown in the options account
/// row, multiplayer opponent cards, and the paper-doll Avatar slot.
///
/// [assetPath] is the image asset. When null, [fallbackIcon] is drawn on a
/// disk of [fallbackColor] instead (lets us ship options before we have art).
class ProfilePictureCosmetic {
  final String id;
  final String name;
  final String? assetPath;
  final IconData fallbackIcon;
  final Color fallbackColor;

  const ProfilePictureCosmetic({
    required this.id,
    required this.name,
    this.assetPath,
    required this.fallbackIcon,
    required this.fallbackColor,
  });
}
