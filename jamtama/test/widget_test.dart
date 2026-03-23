import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamtama/src/providers/match_provider.dart';
import 'package:jamtama/src/models/match_state.dart';

void main() {
  test('Match initializes to deckSelection phase', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = container.read(matchProvider);

    expect(state.phase, MatchPhase.deckSelection);
    expect(state.redDeck.cards.length, 6);
    expect(state.blueDeck.cards.length, 6);
  });
}
