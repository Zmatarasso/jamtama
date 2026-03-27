import 'piece_cosmetic.dart';

/// Cosmetic data for the master piece sprite.
///
/// [assetPath] is a neutral/grayscale image that gets tinted per-player at
/// render time via [ColorFilter]. When null the widget falls back to the
/// built-in programmatic shape.
class MasterPieceCosmetic extends PieceCosmetic {
  const MasterPieceCosmetic({
    required super.id,
    required super.name,
    super.style,
    super.assetPath,
  });
}
