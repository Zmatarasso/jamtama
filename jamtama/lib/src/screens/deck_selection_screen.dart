import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/deck.dart';
import '../models/card.dart';
import '../providers/match_provider.dart';
import '../widgets/card_widget.dart';

class DeckSelectionScreen extends ConsumerWidget {
  const DeckSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF2B1810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0F08),
        title: const Text(
          'Deck Selection',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PlayerDeckSection(
              label: 'Player 2 — Blue',
              color: const Color(0xFF4169E1),
              deck: match.blueDeck,
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white24),
            const SizedBox(height: 24),
            _PlayerDeckSection(
              label: 'Player 1 — Red',
              color: const Color(0xFFDC143C),
              deck: match.redDeck,
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () =>
                    ref.read(matchProvider.notifier).confirmDeckSelection(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B6914),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Begin Match'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerDeckSection extends StatelessWidget {
  final String label;
  final Color color;
  final Deck deck;

  const _PlayerDeckSection({
    required this.label,
    required this.color,
    required this.deck,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DeckGrid(cards: deck.cards),
      ],
    );
  }
}

class _DeckGrid extends StatelessWidget {
  final List<CardDefinition> cards;
  const _DeckGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: cards.map((c) => CardWidget(card: c)).toList(),
    );
  }
}
