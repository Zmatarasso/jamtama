import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card.dart';
import '../models/piece.dart';
import '../models/saved_deck.dart';
import '../providers/deck_builder_provider.dart';
import '../providers/match_provider.dart';
import '../widgets/card_widget.dart';

// ---------------------------------------------------------------------------
// Colours (matches the rest of the app)
// ---------------------------------------------------------------------------
const _bg = Color(0xFF1A1A2E);
const _surface = Color(0xFF16213E);
const _surfaceLight = Color(0xFF1F2D4A);
const _gold = Color(0xFFD4AF37);
const _red = Color(0xFFDC143C);
const _blue = Color(0xFF4169E1);
const _textPrimary = Color(0xFFE8E0D0);
const _textSecondary = Color(0xFF8A7F7F);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class DeckSelectionScreen extends ConsumerWidget {
  const DeckSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchProvider);
    final decks = ref.watch(deckBuilderProvider).decks;
    final fullDecks = decks.where((d) => d.isFull).toList();

    final canBegin =
        match.redDeckId != null && match.blueDeckId != null;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        title: const Text(
          'Choose Decks',
          style: TextStyle(
            color: _gold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textSecondary),
          onPressed: () =>
              ref.read(matchProvider.notifier).returnToMenu(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: fullDecks.isEmpty
                ? _EmptyState()
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Red player panel
                      Expanded(
                        child: _PlayerDeckPanel(
                          player: Player.red,
                          label: 'Player 1',
                          accentColor: _red,
                          decks: fullDecks,
                          selectedDeckId: match.redDeckId,
                          onSelect: (deck) => ref
                              .read(matchProvider.notifier)
                              .selectDeck(Player.red, deck),
                        ),
                      ),
                      Container(width: 1, color: _surfaceLight),
                      // Blue player panel
                      Expanded(
                        child: _PlayerDeckPanel(
                          player: Player.blue,
                          label: 'Player 2',
                          accentColor: _blue,
                          decks: fullDecks,
                          selectedDeckId: match.blueDeckId,
                          onSelect: (deck) => ref
                              .read(matchProvider.notifier)
                              .selectDeck(Player.blue, deck),
                        ),
                      ),
                    ],
                  ),
          ),

          // Begin Match button
          _BottomBar(
            canBegin: canBegin,
            onBegin: () =>
                ref.read(matchProvider.notifier).confirmDeckSelection(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-player deck selection panel
// ---------------------------------------------------------------------------

class _PlayerDeckPanel extends StatelessWidget {
  final Player player;
  final String label;
  final Color accentColor;
  final List<SavedDeck> decks;
  final String? selectedDeckId;
  final void Function(SavedDeck) onSelect;

  const _PlayerDeckPanel({
    required this.player,
    required this.label,
    required this.accentColor,
    required this.decks,
    required this.selectedDeckId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: _surface,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (selectedDeckId != null)
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: Colors.greenAccent),
                    const SizedBox(width: 4),
                    Text(
                      'Ready',
                      style: TextStyle(
                        color: Colors.greenAccent.withAlpha(200),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: _surfaceLight),

        // Deck list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: decks.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16, color: _surfaceLight),
            itemBuilder: (context, i) => _DeckTile(
              deck: decks[i],
              accentColor: accentColor,
              isSelected: decks[i].id == selectedDeckId,
              onSelect: () => onSelect(decks[i]),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Single deck tile — tap to select, expands to show cards
// ---------------------------------------------------------------------------

class _DeckTile extends StatefulWidget {
  final SavedDeck deck;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onSelect;

  const _DeckTile({
    required this.deck,
    required this.accentColor,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<_DeckTile> createState() => _DeckTileState();
}

class _DeckTileState extends State<_DeckTile> {
  bool _expanded = false;

  @override
  void didUpdateWidget(_DeckTile old) {
    super.didUpdateWidget(old);
    // Auto-expand when selected
    if (widget.isSelected && !old.isSelected) {
      setState(() => _expanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards =
        widget.deck.slots.whereType<CardDefinition>().toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: widget.isSelected
          ? widget.accentColor.withAlpha(18)
          : Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row: select radio + name + expand toggle
          InkWell(
            onTap: () {
              widget.onSelect();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Selection indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isSelected
                          ? widget.accentColor
                          : Colors.transparent,
                      border: Border.all(
                        color: widget.isSelected
                            ? widget.accentColor
                            : _textSecondary.withAlpha(100),
                        width: 2,
                      ),
                    ),
                    child: widget.isSelected
                        ? const Icon(Icons.check,
                            size: 10, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.deck.name,
                      style: TextStyle(
                        color: widget.isSelected
                            ? _textPrimary
                            : _textSecondary,
                        fontSize: 14,
                        fontWeight: widget.isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  // Card count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.deck.cardCount}/6',
                      style: const TextStyle(
                          fontSize: 11, color: _textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 16,
                    color: _textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Card preview (3x2 grid)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cards
                    .map((c) => SizedBox(
                          width: 76,
                          height: 100,
                          child: CardWidget(card: c),
                        ))
                    .toList(),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom bar with Begin Match button
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  final bool canBegin;
  final VoidCallback onBegin;

  const _BottomBar({required this.canBegin, required this.onBegin});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canBegin ? onBegin : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              disabledBackgroundColor: _surfaceLight,
              foregroundColor: _bg,
              disabledForegroundColor: _textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(canBegin ? 'BEGIN MATCH' : 'SELECT A DECK FOR EACH PLAYER'),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state — no full decks built yet
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style_outlined,
              size: 56, color: _textSecondary.withAlpha(80)),
          const SizedBox(height: 16),
          const Text(
            'No complete decks yet',
            style: TextStyle(
                color: _textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Build a full 6-card deck in Collection → Cards',
            style: TextStyle(
                color: _textSecondary.withAlpha(150), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
