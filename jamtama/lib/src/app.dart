import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cosmetics/providers/cosmetic_loadout_provider.dart';
import 'models/match_state.dart';
import 'models/round_state.dart';
import 'providers/match_provider.dart';
import 'screens/card_draft_screen.dart';
import 'screens/deck_selection_screen.dart';
import 'screens/game_screen.dart';
import 'screens/menu_screen.dart';
import 'services/audio_service.dart';

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

    // Play win fanfare exactly once when a round/match ends.
    ref.listen(matchProvider, (prev, next) {
      final wasOver = prev?.round?.phase == RoundPhase.over;
      final isNowOver = next.round?.phase == RoundPhase.over;
      if (!wasOver && isNowOver) {
        final audio = ref.read(audioServiceProvider);
        final sounds = ref.read(cosmeticLoadoutProvider).uiSounds;
        if (next.phase == MatchPhase.matchOver) {
          audio.playMatchWin(sounds);
        } else {
          audio.playRoundWin(sounds);
        }
      }
    });

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
      MatchPhase.menu => const MenuScreen(),
      MatchPhase.deckSelection => const DeckSelectionScreen(),
      MatchPhase.draftingRed ||
      MatchPhase.draftingBlue =>
        const CardDraftScreen(),
      MatchPhase.playing || MatchPhase.matchOver => const GameScreen(),
    };
  }
}
