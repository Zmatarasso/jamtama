/// Simple model for AI fallback opponent in network mode.
/// Keeps cosmetics shape compatible with player loadout.
class Opponent {
  final String name;
  final Map<String, dynamic> cosmetics; // mirrors player cosmetic loadout

  Opponent(this.name, this.cosmetics);

  /// Generates a fun AI name (deterministic enough for testing, varied enough for feel)
  static String generateName() {
    const prefixes = ['Ruckus', 'Throne', 'Blade', 'Shadow', 'Royal'];
    const suffixes = ['Bot', 'Lord', 'King', 'Master', 'Rebel'];
    final rng = DateTime.now().millisecondsSinceEpoch % 999;
    return '${prefixes[rng % prefixes.length]}${suffixes[rng % suffixes.length]}#$rng';
  }
}