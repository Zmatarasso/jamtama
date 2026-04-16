import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../animations/draft_animator.dart';
import '../cosmetics/providers/cosmetic_loadout_provider.dart';
import '../models/card.dart';
import '../models/match_state.dart';
import '../models/piece.dart';
import '../providers/match_provider.dart';
import '../services/audio_service.dart';
import '../widgets/card_widget.dart';

// ---------------------------------------------------------------------------
// Draft intro phases
//
//   shuffle → deal → ready
//
// Only the very first draft (round 1, red's turn) plays the intro.
// All subsequent drafts skip straight to [ready].
// ---------------------------------------------------------------------------

enum _DraftIntroPhase { shuffle, deal, ready }

class CardDraftScreen extends ConsumerStatefulWidget {
  const CardDraftScreen({super.key});

  @override
  ConsumerState<CardDraftScreen> createState() => _CardDraftScreenState();
}

class _CardDraftScreenState extends ConsumerState<CardDraftScreen> {
  final Set<CardDefinition> _selected = {};
  late _DraftIntroPhase _introPhase;

  @override
  void initState() {
    super.initState();
    final match = ref.read(matchProvider);
    // Only play the shuffle + deal intro for the very first draft of the match.
    final isFirstDraft =
        match.currentRound == 1 && match.phase == MatchPhase.draftingRed;
    _introPhase =
        isFirstDraft ? _DraftIntroPhase.shuffle : _DraftIntroPhase.ready;
  }

  void _toggle(CardDefinition card) {
    ref.read(audioServiceProvider).playCardDraft(
        ref.read(cosmeticLoadoutProvider).soundPack);
    setState(() {
      if (_selected.contains(card)) {
        _selected.remove(card);
      } else if (_selected.length < 2) {
        _selected.add(card);
      }
    });
  }

  // Draft card dimensions — match the in-game hand card size (scale 1.47 of
  // the native 76×100 CardWidget).
  static const double _cardW = 112.0;
  static const double _cardH = 147.0;

  /// Approximate screen-space centres for [count] draft cards.
  ///
  /// Cards are displayed in a centred [Row] at [_cardW] wide with 16 px gap
  /// between them.  The vertical position is estimated as 50 % of the
  /// available height (between the two equal Spacers that bracket the card
  /// row).
  ///
  /// These positions are relative to the [Stack]'s origin (top-left of
  /// SafeArea), so they match the coordinate space that [CardDealAnimator]
  /// uses for its [Positioned] children.
  List<Offset> _cardDestinations(Size available, int count) {
    const gap = 16.0;
    final totalW = count * _cardW + (count - 1) * gap;
    final startX = (available.width - totalW) / 2 + _cardW / 2;
    final cardY = available.height * 0.50;
    return List.generate(
      count,
      (i) => Offset(startX + i * (_cardW + gap), cardY),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Clear selection whenever the draft phase changes (red → blue or new round).
    ref.listen(
      matchProvider.select((m) => m.phase),
      (_, __) => setState(() => _selected.clear()),
    );

    final match = ref.watch(matchProvider);
    final isDraftingRed = match.phase == MatchPhase.draftingRed;
    final player = isDraftingRed ? Player.red : Player.blue;
    final drafted = isDraftingRed ? match.redDrafted : match.blueDrafted;
    final playerLabel =
        isDraftingRed ? 'Player 1 — Red' : 'Player 2 — Blue';
    final playerColor =
        isDraftingRed ? const Color(0xFFDC143C) : const Color(0xFF4169E1);

    // If only 2 cards remain, auto-select both (no choice).
    final mustTakeAll = drafted.length <= 2;
    final effectiveSelected = mustTakeAll ? drafted.toSet() : _selected;
    final canConfirm = mustTakeAll || _selected.length == 2;

    // ── Normal draft content ──────────────────────────────────────────────
    final draftContent = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: playerColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                playerLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mustTakeAll
                ? 'Take both remaining cards'
                : 'Choose 2 cards for this round',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Round ${match.currentRound} of 3',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Builder(builder: (_) {
            // Loser of last round goes first; Red goes first in round 1.
            final firstPlayer = match.round?.winner == Player.red
                ? Player.blue
                : Player.red;
            final label = firstPlayer == Player.red
                ? 'Player 1 (Red) goes first'
                : 'Player 2 (Blue) goes first';
            final dot = firstPlayer == Player.red
                ? const Color(0xFFDC143C)
                : const Color(0xFF4169E1);
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            );
          }),

          // Table card — the 5th card in the game, owned by neither player.
          // It is seeded randomly at the start of round 1 and carried forward
          // between rounds. Hidden on round 1 before any round has been played.
          if (match.tableCard != null) ...[
            const SizedBox(height: 20),
            const Text(
              'COMMUNITY CARD',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8B6914),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: _cardW,
                height: _cardH,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: CardWidget(card: match.tableCard!),
                ),
              ),
            ),
          ],

          const Spacer(),

          // Card row — each card sized to match the in-game hand card size.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: drafted.map((card) {
              final isSelected = effectiveSelected.contains(card);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: _cardW,
                  height: _cardH,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: CardWidget(
                      card: card,
                      selected: isSelected,
                      dimmed: !isSelected && effectiveSelected.length == 2,
                      onTap: mustTakeAll ? null : () => _toggle(card),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const Spacer(),

          // Confirm button
          AnimatedOpacity(
            opacity: canConfirm ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: canConfirm
                  ? () {
                      ref
                          .read(matchProvider.notifier)
                          .confirmDraft(player, effectiveSelected.toList());
                      if (!mustTakeAll) setState(() => _selected.clear());
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B6914),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Confirm Selection'),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF2B1810),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final available =
                Size(constraints.maxWidth, constraints.maxHeight);

            return Stack(
              children: [
                // ── Draft content ─────────────────────────────────────────
                // Always built so the layout is stable; hidden + non-interactive
                // during the intro animations.
                IgnorePointer(
                  ignoring: _introPhase != _DraftIntroPhase.ready,
                  child: AnimatedOpacity(
                    opacity: _introPhase == _DraftIntroPhase.ready ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: draftContent,
                  ),
                ),

                // ── Shuffle animation ─────────────────────────────────────
                if (_introPhase == _DraftIntroPhase.shuffle)
                  DeckShuffleAnimator(
                    onDone: () =>
                        setState(() => _introPhase = _DraftIntroPhase.deal),
                  ),

                // ── Deal animation ────────────────────────────────────────
                if (_introPhase == _DraftIntroPhase.deal)
                  CardDealAnimator(
                    count: drafted.length,
                    destinations: _cardDestinations(available, drafted.length),
                    deckCenter: Offset(
                      available.width / 2,
                      available.height / 2,
                    ),
                    onDone: () =>
                        setState(() => _introPhase = _DraftIntroPhase.ready),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
