import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_state.dart';
import '../models/piece.dart';
import '../models/round_state.dart';
import '../providers/match_provider.dart';
import '../providers/tutorial_provider.dart';

// ---------------------------------------------------------------------------
// Colours
// ---------------------------------------------------------------------------

const _cardBg      = Color(0xFF2B1810);
const _gold        = Color(0xFFFFD700);
const _goldDim     = Color(0xFF8B6914);
const _textPrimary = Colors.white;
const _textSecondary = Color(0xFFAA9980);

// ---------------------------------------------------------------------------
// Play-bar anchor
//
// All in-game descriptive modals sit in the play-bar zone (the strip between
// the board and Red's hand that shows the community card and selected card).
// Nothing in that area requires player interaction, so it's a safe placeholder.
//
// TODO(roadmap): replace this with precisely positioned, contextual annotations
// — e.g. an arrow tooltip next to the specific piece/card being described.
// ---------------------------------------------------------------------------
//
// Alignment(0, 0.72) lands in the lower third of the screen, roughly where
// the card strip sits in the current game layout.
const _anchorPlayBar = Alignment(0.0, 0.72);

// ---------------------------------------------------------------------------
// Step metadata
// ---------------------------------------------------------------------------

class _StepMeta {
  final String title;
  final String body;

  /// true  → NEXT button; user taps to advance.
  /// false → "WAITING FOR YOU…"; advances automatically on the matching action.
  final bool tapToContinue;

  final Alignment anchor;

  const _StepMeta({
    required this.title,
    required this.body,
    this.tapToContinue = true,
    this.anchor = Alignment.center,
  });
}

const _meta = <TutorialStep, _StepMeta>{
  // ── Menu steps ────────────────────────────────────────────────────────────
  TutorialStep.welcome: _StepMeta(
    title: 'WELCOME TO ROYAL RUCKUS',
    body: "Let's play a quick practice match to learn the basics.",
  ),
  TutorialStep.tapFindMatch: _StepMeta(
    title: 'FIND A MATCH',
    body: 'Tap "Find a Match" to start your practice game.',
  ),

  // ── Board intro (all anchored to play-bar placeholder) ────────────────────
  TutorialStep.boardIntro: _StepMeta(
    title: 'THE BATTLEFIELD',
    body: 'This is the 5×5 board. Your pieces start at the bottom, '
        "your opponent's at the top.",
    anchor: _anchorPlayBar,
  ),
  TutorialStep.piecesIntro: _StepMeta(
    title: 'YOUR PIECES',
    body: 'You have 1 King in the center and 4 Soldiers on either side. '
        'Lose your King and you lose the round.',
    anchor: _anchorPlayBar,
  ),
  TutorialStep.throneIntro: _StepMeta(
    title: 'THE THRONE',
    body: "The golden square at the top center is your opponent's Throne. "
        "Move your King there to win — that's a Conquest.",
    anchor: _anchorPlayBar,
  ),
  TutorialStep.handIntro: _StepMeta(
    title: 'YOUR CARDS',
    body: 'Your two cards are below. Tap one to see which moves it unlocks.',
    anchor: _anchorPlayBar,
  ),

  // ── Guided first move (action-driven) ────────────────────────────────────
  TutorialStep.selectCard: _StepMeta(
    title: 'SELECT A CARD',
    body: 'Tap one of your cards to see which moves it allows.',
    tapToContinue: false,
    anchor: _anchorPlayBar,
  ),
  TutorialStep.selectPiece: _StepMeta(
    title: 'SELECT A PIECE',
    body: 'Tap one of your pieces. Valid squares will light up.',
    tapToContinue: false,
    anchor: _anchorPlayBar,
  ),
  TutorialStep.makeMove: _StepMeta(
    title: 'MAKE YOUR MOVE',
    body: 'Tap a highlighted square to move your piece there.',
    tapToContinue: false,
    anchor: _anchorPlayBar,
  ),

  // ── Post-move info ────────────────────────────────────────────────────────
  TutorialStep.cardSwap: _StepMeta(
    title: 'CARD SWAP',
    body: 'The card you used goes to the community slot, and the community '
        'card joins your hand. Your options change every turn!',
    anchor: _anchorPlayBar,
  ),
  TutorialStep.opponentTurn: _StepMeta(
    title: "OPPONENT'S TURN",
    body: "Watch your opponent move. Tap Next when you're ready to continue.",
    anchor: _anchorPlayBar,
  ),
  TutorialStep.captureIntro: _StepMeta(
    title: 'CAPTURING',
    body: 'Move onto an enemy square to capture that piece. '
        "Capture the enemy King to win — that's a Capture victory.",
    anchor: _anchorPlayBar,
  ),
  TutorialStep.winConditions: _StepMeta(
    title: 'WIN CONDITIONS',
    body: 'Two ways to win:\n'
        '• Capture — take the enemy King\n'
        '• Conquest — move your King onto their Throne',
    anchor: _anchorPlayBar,
  ),

  // ── Free play / finish ────────────────────────────────────────────────────
  TutorialStep.freePlay: _StepMeta(
    title: 'YOUR TURN',
    body: "You've got the basics! Finish this round on your own.",
    tapToContinue: false,
    anchor: _anchorPlayBar,
  ),
  TutorialStep.complete: _StepMeta(
    title: "YOU'RE READY!",
    body: 'Good luck out there!',
    anchor: _anchorPlayBar,
  ),
};

// ---------------------------------------------------------------------------
// Overlay widget
// ---------------------------------------------------------------------------

/// Wraps the entire app body. Shows floating tutorial prompts when active.
/// Only the prompt card's own bounding box intercepts touches — the rest of
/// the game is always accessible.
class TutorialOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const TutorialOverlay({super.key, required this.child});

  @override
  ConsumerState<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends ConsumerState<TutorialOverlay> {
  /// Registered once in initState — never re-registered on rebuild.
  /// Using listenManual guarantees we never miss a matchProvider transition
  /// because of a simultaneous tutorialProvider rebuild.
  late final ProviderSubscription<MatchState> _matchSub;

  @override
  void initState() {
    super.initState();
    _matchSub = ref.listenManual(
      matchProvider,
      _onMatchChanged,
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _matchSub.close();
    super.dispose();
  }

  // ── Match listener ────────────────────────────────────────────────────────

  void _onMatchChanged(MatchState? prev, MatchState next) {
    final tut = ref.read(tutorialProvider);
    if (!tut.active) return;

    // ── Smart step advancement ────────────────────────────────────────────
    // Compute the furthest-forward tutorial step implied by what just happened.
    // If the player is already past that step, nothing changes.
    // If they acted ahead of the scripted step, we jump them forward.
    TutorialStep? minRequired;

    // Card selected → player has passed selectCard; should be at selectPiece+
    if (next.round?.pendingCard != null && prev?.round?.pendingCard == null) {
      minRequired = _maxStep(minRequired, TutorialStep.selectPiece);
    }

    // Piece selected → should be at makeMove+
    if (next.round?.selectedPiece != null &&
        prev?.round?.selectedPiece == null) {
      minRequired = _maxStep(minRequired, TutorialStep.makeMove);
    }

    // Red made a move (turn passes to Blue) → should be at cardSwap+
    if (prev?.round?.currentTurn == Player.red &&
        next.round?.currentTurn == Player.blue &&
        next.round?.phase == RoundPhase.playing) {
      minRequired = _maxStep(minRequired, TutorialStep.cardSwap);
    }

    // Blue's move landed (turn passes back to Red) and we haven't explained
    // capturing yet → jump to captureIntro.
    // Guard: only fire if we're still before captureIntro — during freePlay
    // every bot move would otherwise snap back to captureIntro.
    if (prev?.round?.currentTurn == Player.blue &&
        next.round?.currentTurn == Player.red &&
        next.round?.phase == RoundPhase.playing &&
        tut.step.index < TutorialStep.captureIntro.index) {
      minRequired = _maxStep(minRequired, TutorialStep.captureIntro);
    }

    // Round ended → jump straight to complete
    if (next.round?.phase == RoundPhase.over &&
        prev?.round?.phase != RoundPhase.over) {
      minRequired = TutorialStep.complete;
    }

    // Apply only if it moves the step forward
    if (minRequired != null && minRequired.index > tut.step.index) {
      ref.read(tutorialProvider.notifier).jumpTo(minRequired);
    }
  }

  static TutorialStep _maxStep(TutorialStep? a, TutorialStep b) =>
      (a != null && a.index > b.index) ? a : b;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tutorial = ref.watch(tutorialProvider);
    if (!tutorial.active) return widget.child;

    final meta = _meta[tutorial.step];

    return Stack(
      children: [
        widget.child,
        if (meta != null) _buildPrompt(tutorial.step, meta),
      ],
    );
  }

  Widget _buildPrompt(TutorialStep step, _StepMeta meta) {
    return SafeArea(
      child: Align(
        alignment: meta.anchor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: _PromptCard(
            title: meta.title,
            body: meta.body,
            showNext: meta.tapToContinue,
            onNext: meta.tapToContinue ? () => _handleNext(step) : null,
          ),
        ),
      ),
    );
  }

  // ── NEXT handler ──────────────────────────────────────────────────────────

  void _handleNext(TutorialStep step) {
    final notifier = ref.read(tutorialProvider.notifier);

    switch (step) {
      case TutorialStep.tapFindMatch:
        ref.read(matchProvider.notifier).startTestMatch();
        notifier.jumpTo(TutorialStep.boardIntro);

      case TutorialStep.cardSwap:
        notifier.jumpTo(TutorialStep.opponentTurn);

      case TutorialStep.opponentTurn:
        // Bot fires automatically via the match listener; just advance the UI.
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
  final bool showNext;
  final VoidCallback? onNext;

  const _PromptCard({
    required this.title,
    required this.body,
    this.showNext = true,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg.withAlpha(230),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _goldDim, width: 1.5),
        boxShadow: [
          BoxShadow(color: _gold.withAlpha(30), blurRadius: 12, spreadRadius: 1),
          const BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
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
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          if (showNext && onNext != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _goldDim,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                child: const Text('NEXT'),
              ),
            )
          else
            const Text(
              'WAITING FOR YOU…',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}
