import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_state.dart';
import '../models/piece.dart';
import '../models/round_state.dart';
import '../providers/match_provider.dart';
import '../services/tutorial_bot.dart';

/// Invisible widget that drives the AI (Blue) player in [GameMode.ai] matches.
///
/// Lives above [TutorialOverlay] in the tree so it is never torn down by screen
/// transitions.  Uses [ref.listenManual] — registered once in [initState] and
/// never re-registered on rebuild — to guarantee every match-state transition
/// is observed, including across round boundaries.
///
/// Ownership: bot logic belongs here, not in [TutorialOverlay].  The overlay is
/// purely UI + tutorial step advancement.
class BotPlayer extends ConsumerStatefulWidget {
  final Widget child;
  const BotPlayer({super.key, required this.child});

  @override
  ConsumerState<BotPlayer> createState() => _BotPlayerState();
}

class _BotPlayerState extends ConsumerState<BotPlayer> {
  bool _botPlaying = false;

  late final ProviderSubscription<MatchState> _matchSub;

  @override
  void initState() {
    super.initState();
    _matchSub = ref.listenManual(
      matchProvider,
      _onMatchChanged,
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _matchSub.close();
    super.dispose();
  }

  void _onMatchChanged(MatchState? prev, MatchState next) {
    // Only act in AI mode.
    if (next.gameMode != GameMode.ai) return;

    final round = next.round;
    if (round == null) return;
    if (round.phase != RoundPhase.playing) return;
    if (round.currentTurn != Player.blue) return;
    if (_botPlaying) return;

    _scheduleBotMove();
  }

  void _scheduleBotMove() {
    _botPlaying = true;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        _botPlaying = false;
        return;
      }
      botMove(ref);
      _botPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
