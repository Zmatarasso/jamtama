/// The visual behaviour style of a move effect.
///
/// [slide] — piece glides smoothly to the target square (default, no assets).
/// [fireTrail] — animated fire/ember trail follows the piece path.
/// [shadowStep] — piece blinks out with a shadow afterimage and reappears.
/// [teleport] — instant dissolve-out / dissolve-in with a flash.
enum MoveEffectType { slide, fireTrail, shadowStep, teleport }

/// Cosmetic bundle for move animations and sound effects.
///
/// [type] drives which animation widget is used at render time — each type
/// has its own implementation, so purely swapping assets is not enough for
/// different effect styles.
///
/// All asset paths are optional; null means that portion of the effect is
/// skipped (e.g. no sound, or fall back to the plain slide).
class MoveEffectCosmetic {
  final String id;
  final String name;
  final MoveEffectType type;

  // Animation assets (Rive / Lottie file paths)
  final String? trailAnimationAsset;
  final String? landingAnimationAsset;

  // Sound assets
  final String? moveSoundAsset;
  final String? captureSoundAsset;

  const MoveEffectCosmetic({
    required this.id,
    required this.name,
    required this.type,
    this.trailAnimationAsset,
    this.landingAnimationAsset,
    this.moveSoundAsset,
    this.captureSoundAsset,
  });
}
