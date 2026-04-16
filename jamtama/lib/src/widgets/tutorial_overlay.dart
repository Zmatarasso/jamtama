import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/piece.dart';
import '../models/round_state.dart';
import '../providers/match_provider.dart';
import '../providers/tutorial_provider.dart';
import '../services/tutorial_bot.dart';

// ---------------------------------------------------------------------------
// Colours
// ---------------------------------------------------------------------------

const _overlayBg = Color(0xCC000000);
const _cardBg = Color(0xFF2B1810);
const _gold = Color(0xFFFFD700);
const _goldDim = Color(0xFF8B6914);
const _textPrimary = Colors.white;
const _textSecondary = Color(0xFFAA9980);

// ---------------------------------------------------------------------------
// Tutorial content per step
// ---------------------------------------------------------------------------

class _StepContent {
  final String title;
  final String body;
  final bool tapToContinue; // false = wait for game action
  final Alignment anchor;   // where the card appears

  const _StepContent({
    required this.title,
    required this.body,
    this.tapToContinue = true,
    this.anchor = Alignment.center,
  });
}

const _stepContent = <TutorialStep, _StepContent>{
  TutorialStep.welcome: _StepContent(
    title: 'WELCOME TO ROYAL RUMBLE',
    body: "Let's play a quick practice match to learn the basics.",
  ),
  TutorialStep.tapFindMatch: _StepContent(
    title: 'FIND A MATCH',
    body: 'Tap "Find a Match" to face an opponent.',
  ),
  TutorialStep.deckIntro: _StepContent(
    title: 'YOUR DECK',
    body: "This is your deck — 6 cards that determine how your pieces "
        "can move. For now, we'll use the starter deck. Tap confirm to continue.",
  ),
  TutorialStep.boardIntro: _StepContent(
    title: 'THE BATTLEFIELD',
    body: 'This is the 5×5 board. Your pieces start at the bottom, '
        "your opponent's at the top.",
    anchor: Alignment.bottomCenter,
  ),
  TutorialStep.piecesIntro: _StepContent(
    title: 'YOUR PIECES',
    body: 'You have 1 King (your leader) in the center, and '
        '4 Soldiers on either side. Lose your King and you lose the round.',
    anchor: Alignment.bottomCenter,
  ),
  TutorialStep.throneIntro: _StepContent(
    title: 'THE THRONE',
    body: "The golden square at the top center is your opponent's Throne. "
        'Move your King there to win instantly — that\'s called a Conquest.',
    anchor: Alignment.bottomCenter,
  ),
  TutorialStep.handIntro: _StepContent(
    title: 'YOUR CARDS',
    body: 'These are your movement cards. Each card shows a pattern — '
        'the green squares show where a piece can move relative to its position.',
    anchor: Alignment.topCenter,
  ),
  TutorialStep.selectCard: _StepContent(
    title: 'SELECT A CARD',
    body: 'Tap one of your cards to see which moves it allows.',
    tapToContinue: false,
    anchor: Alignment.topCenter,
  ),
  TutorialStep.selectPiece: _StepContent(
    title: 'SELECT A PIECE',
    body: 'Now tap one of your pieces to select it. '
        'Valid destination squares will light up on the board.',
    tapToContinue: false,
    anchor: Alignment.topCenter,
  ),
  TutorialStep.makeMove: _StepContent(
    title: 'MAKE YOUR MOVE',
    body: 'Tap a highlighted square to move your piece there.',
    tapToContinue: false,
    anchor: Alignment.topCenter,
  ),
  TutorialStep.cardSwap: _StepContent(
    title: 'CARD SWAP',
    body: 'After each move, the card you used goes to the community slot, '
        'and the community card joins your hand. '
        'Your options change every turn!',
    anchor: Alignment.topCenter,
  ),
  TutorialStep.opponentTurn: _StepContent(
    title: "OPPONENT'S TURN",
    body: 'Your opponent plays the same way — pick a card, pick a piece, '
        'move. Watch what they do.',
    anchor: Alignment.topCenter,
  ),
  TutorialStep.captureIntro: _StepContent(
    title: 'CAPTURING',
    body: 'When you move onto a square occupied by an enemy piece, you '
        "capture it! Capture the enemy King to win — that's called a Capture.",
  ),
  TutorialStep.winConditions: _StepContent(
    title: 'WIN CONDITIONS',
    body: 'Remember: win by Capture (take the enemy King) or by '
        'Conquest (move your King onto their Throne).',
  ),
  TutorialStep.freePlay: _StepContent(
    title: 'YOUR TURN',
    body: "You've got the basics! Finish this round on your own.",
    tapToContinue: false,
    anchor: Alignment.topCenter,
  ),
  TutorialStep.roundOver: _StepContent(
    title: 'ROUND OVER',
    body: 'Nice work! Matches are best of 3 rounds. Between rounds, '
        "you'll select from new cards drawn from your deck.",
  ),
  TutorialStep.draftIntro: _StepContent(
    title: 'SELECT NEW CARDS',
    body: "Pick 2 of these 3 cards for your next round's hand. "
        "The one you don't pick goes back in your deck.",
  ),
  TutorialStep.complete: _StepContent(
    title: "YOU'RE READY!",
    body: "The rest of this match is all you. Good luck!",
  ),
};

// ---------------------------------------------------------------------------
// Main overlay
// ---------------------------------------------------------------------------

/// Wrap around the entire app body. Shows tutorial prompts when active.
class TutorialOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const TutorialOverlay({super.key, required this.child});

  @override
  ConsumerState<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends ConsumerState<TutorialOverlay> {
  bool _botPlaying = false;

  @override
  Widget build(BuildContext context) {
    final tutorial = ref.watch(tutorialProvider);
    if (!tutorial.active) return widget.child;

    final step = tutorial.step;
    final content = _stepContent[step];

    // Listen for game-action steps that should auto-advance.
    _listenForAutoAdvance(step);

    return Stack(
      children: [
        widget.child,
        if (content != null) _buildPrompt(step, content),
      ],
    );
  }

  void _listenForAutoAdvance(TutorialStep step) {
    ref.listen(matchProvider, (prev, next) {
      final tut = ref.read(tutorialProvider);
      if (!tut.active) return;

      switch (tut.step) {
        case TutorialStep.selectCard:
          // Advance when a card is selected.
          if (next.round?.pendingCard != null &&
              prev?.round?.pendingCard == null) {
            ref.read(tutorialProvider.notifier).advance();
          }

        case TutorialStep.selectPiece:
          // Advance when a piece is selected.
          if (next.round?.selectedPiece != null &&
              prev?.round?.selectedPiece == null) {
            ref.read(tutorialProvider.notifier).advance();
          }

        case TutorialStep.makeMove:
          // Advance when the move executes (turn switches to blue).
          if (prev?.round?.currentTurn == Player.red &&
              next.round?.currentTurn == Player.blue &&
              next.round?.phase == RoundPhase.playing) {
            ref.read(tutorialProvider.notifier).jumpTo(TutorialStep.cardSwap);
          }

        case TutorialStep.opponentTurn:
          // After this step is shown, trigger the bot.
          // Handled in the tap callback.
          break;

        case TutorialStep.freePlay:
          // Watch for round end.
          if (next.round?.phase == RoundPhase.over &&
              prev?.round?.phase != RoundPhase.over) {
            ref.read(tutorialProvider.notifier).jumpTo(TutorialStep.roundOver);
          }
          // Also trigger bot for blue's turns during free play.
          if (next.round?.currentTurn == Player.blue &&
              next.round?.phase == RoundPhase.playing &&
              !_botPlaying) {
            _scheduleBotMove();
          }

        default:
          break;
      }
    });
  }

  void _scheduleBotMove() {
    if (_botPlaying) return;
    _botPlaying = true;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      botMove(ref);
      _botPlaying = false;
    });
  }

  Widget _buildPrompt(TutorialStep step, _StepContent content) {
    final isTap = content.tapToContinue;
    return GestureDetector(
      behavior: isTap ? HitTestBehavior.opaque : HitTestBehavior.translucent,
      onTap: isTap ? () => _handleTap(step) : null,
      child: Container(
        color: isTap ? _overlayBg : Colors.transparent,
        child: SafeArea(
          child: Align(
            alignment: content.anchor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: _PromptCard(
                title: content.title,
                body: content.body,
                showTapHint: isTap,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(TutorialStep step) {
    final notifier = ref.read(tutorialProvider.notifier);

    switch (step) {
      case TutorialStep.tapFindMatch:
        // Start the tutorial match and advance.
        ref.read(matchProvider.notifier).startTestMatch();
        notifier.advance(); // → deckIntro... actually skip deck for test match
        // Test match skips deck selection + drafting, jump to boardIntro.
        notifier.jumpTo(TutorialStep.boardIntro);

      case TutorialStep.cardSwap:
        // After explaining card swap, trigger the bot move.
        notifier.jumpTo(TutorialStep.opponentTurn);

      case TutorialStep.opponentTurn:
        // Trigger bot, then advance to capture intro.
        _scheduleBotMove();
        notifier.jumpTo(TutorialStep.captureIntro);

      case TutorialStep.complete:
        notifier.end();

      default:
        notifier.advance();
    }
  }
}

// ---------------------------------------------------------------------------
// Prompt card widget
// ---------------------------------------------------------------------------

class _PromptCard extends StatelessWidget {
  final String title;
  final String body;
  final bool showTapHint;

  const _PromptCard({
    required this.title,
    required this.body,
    this.showTapHint = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _goldDim, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _gold.withAlpha(30),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _gold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (showTapHint) ...[
            const SizedBox(height: 16),
            const Text(
              'TAP TO CONTINUE',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
