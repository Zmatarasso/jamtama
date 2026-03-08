import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamtama/src/providers/game_provider.dart';
import 'package:jamtama/src/models/piece.dart';  // Add for Player.

void main() {
  test('Game initializes correctly', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.initGame();
    final state = container.read(gameProvider);

    expect(state.pieces.length, 10);
    expect(state.currentTurn, Player.red);
  });
}