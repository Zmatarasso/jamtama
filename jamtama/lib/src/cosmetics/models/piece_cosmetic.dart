/// How a piece is rendered.
/// [classic] — solid colored circle with a symbol (default).
/// [wood]    — procedural wood grain with player color tint.
/// [stone]   — procedural stone texture with player color tint.
enum PieceStyle { classic, wood, stone }

/// Shared base for [MasterPieceCosmetic] and [StudentPieceCosmetic].
///
/// Both piece types store the same data (an optional neutral asset path that
/// gets tinted at render time), so the base class carries all of it. The
/// subclasses exist purely to keep the slot types distinct in [CosmeticLoadout].
abstract class PieceCosmetic {
  final String id;
  final String name;
  final PieceStyle style;

  /// Neutral/grayscale image asset path. Null = use the programmatic shape.
  /// Tinted with the player's color via [ColorFilter] at render time.
  final String? assetPath;

  const PieceCosmetic({
    required this.id,
    required this.name,
    this.style = PieceStyle.classic,
    this.assetPath,
  });
}
