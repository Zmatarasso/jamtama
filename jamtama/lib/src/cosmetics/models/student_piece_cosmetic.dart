import 'piece_cosmetic.dart';

/// Cosmetic data for the student piece sprite.
///
/// [assetPath] is a neutral/grayscale image tinted per-player at render time.
/// When null the widget falls back to the built-in programmatic shape.
class StudentPieceCosmetic extends PieceCosmetic {
  const StudentPieceCosmetic({
    required super.id,
    required super.name,
    super.style,
    super.assetPath,
  });
}
