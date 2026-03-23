import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/match_state.dart';
import 'models/round_state.dart';
import 'providers/match_provider.dart';
import 'screens/card_draft_screen.dart';
import 'screens/deck_selection_screen.dart';
import 'screens/game_screen.dart';

class JamtamaApp extends StatelessWidget {
  const JamtamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jamtama',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends ConsumerWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchProvider);

    // Show round-over dialog when we're in the playing phase but the round ended.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (match.phase == MatchPhase.playing &&
          match.round?.phase == RoundPhase.over) {
        // Only show if no dialog is already up.
        if (ModalRoute.of(context)?.isCurrent ?? true) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => RoundOverDialog(
              round: match.round!,
              redWins: match.redWins,
              blueWins: match.blueWins,
              isMatchOver: false,
            ),
          );
        }
      } else if (match.phase == MatchPhase.matchOver &&
          match.round?.phase == RoundPhase.over) {
        if (ModalRoute.of(context)?.isCurrent ?? true) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => RoundOverDialog(
              round: match.round!,
              redWins: match.redWins,
              blueWins: match.blueWins,
              isMatchOver: true,
            ),
          );
        }
      }
    });

    return switch (match.phase) {
      MatchPhase.deckSelection => const DeckSelectionScreen(),
      MatchPhase.draftingRed ||
      MatchPhase.draftingBlue =>
        const CardDraftScreen(),
      MatchPhase.playing || MatchPhase.matchOver => const GameScreen(),
    };
  }
}
