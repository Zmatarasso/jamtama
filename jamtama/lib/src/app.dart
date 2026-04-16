import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cosmetics/providers/cosmetic_loadout_provider.dart';
import 'models/match_state.dart';
import 'models/round_state.dart';
import 'providers/match_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/card_draft_screen.dart';
import 'screens/deck_selection_screen.dart';
import 'screens/game_screen.dart';
import 'screens/menu_screen.dart';
import 'services/audio_service.dart';
import 'widgets/tutorial_overlay.dart';

class JamtamaApp extends StatelessWidget {
  const JamtamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Royal Rumble',
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

    // Single listener handles audio, dialog, and coin rewards — fires exactly
    // once per round-over transition.
    ref.listen(matchProvider, (prev, next) {
      final wasOver = prev?.round?.phase == RoundPhase.over;
      final isNowOver = next.round?.phase == RoundPhase.over;
      if (!wasOver && isNowOver) {
        // Play fanfare.
        final audio = ref.read(audioServiceProvider);
        final pack = ref.read(cosmeticLoadoutProvider).soundPack;
        if (next.phase == MatchPhase.matchOver) {
          audio.playMatchWin(pack);
          // Award coins — local match: both sides are the same player,
          // so give win + loss reward for completing the match.
          final wallet = ref.read(walletProvider.notifier);
          wallet.earn(matchWinReward + matchLossReward);
        } else {
          audio.playRoundWin(pack);
        }

        // Show dialog after the frame so the board paint finishes first.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => RoundOverDialog(
              round: next.round!,
              redWins: next.redWins,
              blueWins: next.blueWins,
              isMatchOver: next.phase == MatchPhase.matchOver,
            ),
          );
        });
      }
    });

    final screen = switch (match.phase) {
      MatchPhase.menu => const MenuScreen(),
      MatchPhase.deckSelection => const DeckSelectionScreen(),
      MatchPhase.draftingRed ||
      MatchPhase.draftingBlue =>
        const CardDraftScreen(),
      MatchPhase.playing || MatchPhase.matchOver => const GameScreen(),
    };

    return TutorialOverlay(child: screen);
  }
}
