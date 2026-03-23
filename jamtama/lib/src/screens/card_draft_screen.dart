import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card.dart';
import '../models/match_state.dart';
import '../models/piece.dart';
import '../providers/match_provider.dart';
import '../widgets/card_widget.dart';

class CardDraftScreen extends ConsumerStatefulWidget {
  const CardDraftScreen({super.key});

  @override
  ConsumerState<CardDraftScreen> createState() => _CardDraftScreenState();
}

class _CardDraftScreenState extends ConsumerState<CardDraftScreen> {
  final Set<CardDefinition> _selected = {};

  @override
  void didUpdateWidget(CardDraftScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear selection when the phase changes (red → blue draft handoff).
    _selected.clear();
  }

  void _toggle(CardDefinition card) {
    setState(() {
      if (_selected.contains(card)) {
        _selected.remove(card);
      } else if (_selected.length < 2) {
        _selected.add(card);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      backgroundColor: const Color(0xFF2B1810),
      body: SafeArea(
        child: Padding(
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

              const Spacer(),

              // Card row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: drafted.map((card) {
                  final isSelected = effectiveSelected.contains(card);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: CardWidget(
                      card: card,
                      selected: isSelected,
                      dimmed: !isSelected && effectiveSelected.length == 2,
                      onTap: mustTakeAll ? null : () => _toggle(card),
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
        ),
      ),
    );
  }
}
