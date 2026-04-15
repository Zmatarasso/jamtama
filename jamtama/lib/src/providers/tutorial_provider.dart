import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_data_repository_provider.dart';

/// Each step in the gameplay tutorial.
enum TutorialStep {
  // -- Menu --
  welcome,         // 1. Welcome overlay
  tapFindMatch,    // 2. Highlight "Find a Match"

  // -- Deck selection --
  deckIntro,       // 3. Explain the starter deck

  // -- In-game --
  boardIntro,      // 4. "This is the battlefield"
  piecesIntro,     // 5. Your King + Soldiers
  throneIntro,     // 6. Opponent's Throne → Conquest
  handIntro,       // 7. Your two movement cards
  selectCard,      // 8. "Tap a card"
  selectPiece,     // 9. "Tap one of your pieces"
  makeMove,        // 10. "Tap a highlighted square"
  cardSwap,        // 11. Explain the card swap
  opponentTurn,    // 12. Bot plays, explain
  captureIntro,    // 13. Capturing explanation
  winConditions,   // 14. Recap: Capture vs Conquest
  freePlay,        // 15. "Finish this round on your own"

  // -- Between rounds --
  roundOver,       // 16. Round result + best-of-3
  draftIntro,      // 17. Card selection explanation

  // -- Done --
  complete,        // 18. "You're ready!"
}

class TutorialState {
  final bool active;
  final TutorialStep step;

  const TutorialState({this.active = false, this.step = TutorialStep.welcome});

  TutorialState copyWith({bool? active, TutorialStep? step}) => TutorialState(
        active: active ?? this.active,
        step: step ?? this.step,
      );
}

class TutorialNotifier extends Notifier<TutorialState> {
  @override
  TutorialState build() => const TutorialState();

  /// Returns true if the tutorial has been completed before.
  bool get isDone =>
      ref.read(userDataRepositoryProvider).loadTutorialDone();

  /// Start the tutorial. No-op if it has already been completed.
  void start() {
    if (isDone) return;
    state = const TutorialState(active: true, step: TutorialStep.welcome);
  }

  /// Force-start the tutorial regardless of completion status (used by reset).
  void forceStart() =>
      state = const TutorialState(active: true, step: TutorialStep.welcome);

  void advance() {
    if (!state.active) return;
    final values = TutorialStep.values;
    final idx = values.indexOf(state.step);
    if (idx >= values.length - 1) {
      end();
      return;
    }
    state = state.copyWith(step: values[idx + 1]);
  }

  void jumpTo(TutorialStep step) {
    if (!state.active) return;
    state = state.copyWith(step: step);
  }

  void end() {
    ref.read(userDataRepositoryProvider).saveTutorialDone(true);
    state = const TutorialState();
  }

  Future<void> reset() async {
    await ref.read(userDataRepositoryProvider).saveTutorialDone(false);
  }
}

final tutorialProvider =
    NotifierProvider<TutorialNotifier, TutorialState>(TutorialNotifier.new);
