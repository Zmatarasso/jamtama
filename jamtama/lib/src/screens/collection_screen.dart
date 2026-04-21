import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cosmetics/models/cosmetic_loadout.dart';
import '../cosmetics/models/cosmetic_slot_type.dart';
import '../cosmetics/providers/cosmetic_collection_provider.dart';
import '../cosmetics/providers/cosmetic_loadout_provider.dart';
import '../data/card_definitions.dart';
import '../models/card.dart';
import '../models/saved_deck.dart';
import '../providers/deck_builder_provider.dart';

// ---------------------------------------------------------------------------
// Colours (shared across tabs)
// ---------------------------------------------------------------------------

const _bg = Color(0xFF1A0F08);
const _surface = Color(0xFF2B1810);
const _surfaceLight = Color(0xFF3A2418);
const _gold = Color(0xFFFFD700);
const _goldDim = Color(0xFF8B6914);
const _textPrimary = Colors.white;
const _textSecondary = Color(0xFFAA9980);

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _surface,
          foregroundColor: _textPrimary,
          title: const Text(
            'COLLECTION',
            style: TextStyle(
              letterSpacing: 4,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          bottom: const TabBar(
            labelColor: _gold,
            unselectedLabelColor: _textSecondary,
            indicatorColor: _gold,
            indicatorWeight: 2,
            tabs: [
              Tab(text: 'CARDS'),
              Tab(text: 'COSMETICS'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CardsTab(),
            _CosmeticsTab(),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// CARDS TAB — Deck Builder
// ===========================================================================

class _CardsTab extends ConsumerWidget {
  const _CardsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deckBuilderProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Left: deck list ────────────────────────────────────────────────
        _DeckPanel(state: state),

        // Divider
        Container(width: 1, color: _surfaceLight),

        // ── Right: card collection ─────────────────────────────────────────
        Expanded(child: _CollectionPanel(state: state)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Left panel — deck list
// ---------------------------------------------------------------------------

class _DeckPanel extends ConsumerWidget {
  final DeckBuilderState state;
  const _DeckPanel({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(deckBuilderProvider.notifier);

    return SizedBox(
      width: 260,
      child: Container(
        color: _surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              color: _surfaceLight,
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'MY DECKS',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  // Add deck button
                  GestureDetector(
                    onTap: notifier.addDeck,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _goldDim,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Deck list
            Expanded(
              child: state.decks.isEmpty
                  ? const Center(
                      child: Text(
                        'No decks yet.\nTap + to create one.',
                        style: TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                            height: 1.6),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.decks.length,
                      itemBuilder: (context, i) {
                        final deck = state.decks[i];
                        final isSelected =
                            deck.id == state.selectedDeckId;
                        return _DeckListSection(
                          deck: deck,
                          isSelected: isSelected,
                          onSelect: () => notifier.selectDeck(deck.id),
                          onRemoveCard: (card) =>
                              notifier.removeCard(deck.id, card),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One deck row + its expandable card slots
// ---------------------------------------------------------------------------

class _DeckListSection extends StatelessWidget {
  final SavedDeck deck;
  final bool isSelected;
  final VoidCallback onSelect;
  final void Function(CardDefinition) onRemoveCard;

  const _DeckListSection({
    required this.deck,
    required this.isSelected,
    required this.onSelect,
    required this.onRemoveCard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Deck header row
        GestureDetector(
          onTap: onSelect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: isSelected
                ? _gold.withAlpha(25)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.style_outlined,
                  size: 16,
                  color: isSelected ? _gold : _textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    deck.name,
                    style: TextStyle(
                      color:
                          isSelected ? _gold : _textPrimary,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${deck.cardCount}/6',
                  style: TextStyle(
                    color:
                        isSelected ? _gold : _textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  isSelected
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 16,
                  color: isSelected ? _gold : _textSecondary,
                ),
              ],
            ),
          ),
        ),

        // Card slots — 3×2 grid, only visible when this deck is selected
        if (isSelected)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < 6; i++)
                  _CardSlot(
                    slotIndex: i,
                    card: deck.slots[i],
                    onRemove: deck.slots[i] != null
                        ? () => onRemoveCard(deck.slots[i]!)
                        : null,
                  ),
              ],
            ),
          ),

        Divider(height: 1, color: _surfaceLight),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// A single card slot in the deck
// Tap = zoom/inspect dialog  |  Hold 1.4s = remove without dialog
// ---------------------------------------------------------------------------

class _CardSlot extends StatefulWidget {
  final int slotIndex;
  final CardDefinition? card;
  final VoidCallback? onRemove;

  const _CardSlot({
    required this.slotIndex,
    required this.card,
    this.onRemove,
  });

  @override
  State<_CardSlot> createState() => _CardSlotState();
}

class _CardSlotState extends State<_CardSlot>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _pressAnim;
  bool _pressing = false;

  @override
  void initState() {
    super.initState();
    _pressAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pressAnim.dispose();
    super.dispose();
  }

  void _startPress(TapDownDetails _) {
    if (widget.card == null) return;
    setState(() => _pressing = true);
    _pressAnim.forward(from: 0);
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (_pressing && mounted) {
        widget.onRemove?.call();
        setState(() => _pressing = false);
        _pressAnim.reset();
      }
    });
  }

  void _endPress(TapUpDetails _) {
    if (!_pressing) return;
    _timer?.cancel();
    _pressAnim.reset();
    final wasPressed = _pressing;
    setState(() => _pressing = false);
    if (wasPressed && widget.card != null) {
      _showInspector();
    }
  }

  void _cancelPress() {
    _timer?.cancel();
    _pressAnim.reset();
    setState(() => _pressing = false);
  }

  void _showInspector() {
    final card = widget.card;
    if (card == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => _CardInspectorDialog(
        card: card,
        onRemove: widget.onRemove,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCard = widget.card != null;

    return GestureDetector(
      onTapDown: _startPress,
      onTapUp: _endPress,
      onTapCancel: _cancelPress,
      child: SizedBox(
        width: 76,
        height: 100,
        child: Stack(
          children: [
            // Card face or empty placeholder
            if (hasCard)
              _MiniCard(
                card: widget.card!,
                dimmed: false,
                hovering: _pressing,
              )
            else
              _EmptyCardSlot(slotIndex: widget.slotIndex),

            // Long-press progress bar along the bottom edge
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8)),
                child: AnimatedBuilder(
                  animation: _pressAnim,
                  builder: (_, __) => LinearProgressIndicator(
                    value: _pressing ? _pressAnim.value : 0,
                    minHeight: 3,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.redAccent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty card slot placeholder (same footprint as a card)
// ---------------------------------------------------------------------------

class _EmptyCardSlot extends StatelessWidget {
  final int slotIndex;
  const _EmptyCardSlot({required this.slotIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 100,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _textSecondary.withAlpha(45),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, size: 18, color: _textSecondary.withAlpha(60)),
          const SizedBox(height: 4),
          Text(
            '${slotIndex + 1}',
            style: TextStyle(
              fontSize: 10,
              color: _textSecondary.withAlpha(60),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card inspector dialog
// ---------------------------------------------------------------------------

class _CardInspectorDialog extends StatelessWidget {
  final CardDefinition card;
  final VoidCallback? onRemove;

  const _CardInspectorDialog({required this.card, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large card preview
            _BigCardPreview(card: card),
            const SizedBox(height: 20),

            // Card name
            Text(
              card.name.toUpperCase(),
              style: const TextStyle(
                color: _gold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE',
                      style: TextStyle(color: _textSecondary)),
                ),
                if (onRemove != null) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onRemove!();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1A1A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.remove_circle_outline, size: 16),
                    label: const Text('REMOVE',
                        style: TextStyle(letterSpacing: 1.5)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Large card preview (used in inspector dialog)
// ---------------------------------------------------------------------------

class _BigCardPreview extends StatelessWidget {
  final CardDefinition card;
  const _BigCardPreview({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 196,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E0),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Colors.black54, blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              card.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            _BigMoveDiagram(card: card),
            Container(
              width: 32,
              height: 10,
              decoration: BoxDecoration(
                color: card.stampColor.withAlpha(200),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigMoveDiagram extends StatelessWidget {
  final CardDefinition card;
  const _BigMoveDiagram({required this.card});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: 25,
        itemBuilder: (_, i) {
          final r = i ~/ 5;
          final c = i % 5;
          final isCenter = r == 2 && c == 2;
          final isMove =
              card.moves.any((m) => (2 - m.dy) == r && (2 + m.dx) == c);
          return Container(
            decoration: BoxDecoration(
              color: isCenter
                  ? Colors.grey[700]
                  : isMove
                      ? const Color(0xFF4CAF50)
                      : Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Right panel — full card collection
// ---------------------------------------------------------------------------

class _CollectionPanel extends ConsumerWidget {
  final DeckBuilderState state;
  const _CollectionPanel({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(deckBuilderProvider.notifier);
    final selectedDeck = state.selectedDeck;

    return Container(
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: _surfaceLight,
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'CARD COLLECTION',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                if (selectedDeck != null)
                  Text(
                    selectedDeck.isFull
                        ? 'Deck full'
                        : 'Select cards for ${selectedDeck.name}',
                    style: const TextStyle(
                        color: _textSecondary, fontSize: 11),
                  ),
              ],
            ),
          ),

          // No deck selected hint
          if (selectedDeck == null)
            const Expanded(
              child: Center(
                child: Text(
                  'Select a deck on the left\nto start adding cards.',
                  style: TextStyle(
                      color: _textSecondary, fontSize: 13, height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            // Card grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 14,
                  children: [
                    for (final card in allCards)
                      _CollectionCardTile(
                        card: card,
                        inDeck: selectedDeck.contains(card),
                        deckFull:
                            selectedDeck.isFull && !selectedDeck.contains(card),
                        onAdd: () =>
                            notifier.addCard(selectedDeck.id, card),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single card in the collection grid
// ---------------------------------------------------------------------------

class _CollectionCardTile extends StatefulWidget {
  final CardDefinition card;
  final bool inDeck;
  final bool deckFull;
  final VoidCallback onAdd;

  const _CollectionCardTile({
    required this.card,
    required this.inDeck,
    required this.deckFull,
    required this.onAdd,
  });

  @override
  State<_CollectionCardTile> createState() => _CollectionCardTileState();
}

class _CollectionCardTileState extends State<_CollectionCardTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.inDeck || widget.deckFull;
    final lift = (!disabled && _hovering) ? -4.0 : 0.0;

    return MouseRegion(
      cursor:
          disabled ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: disabled ? null : widget.onAdd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          transform: Matrix4.translationValues(0, lift, 0),
          child: Stack(
            children: [
              // Card widget — reuse existing widget
              SizedBox(
                width: 76,
                height: 100,
                child: _MiniCard(
                  card: widget.card,
                  dimmed: disabled,
                  hovering: _hovering && !disabled,
                ),
              ),

              // "In deck" badge
              if (widget.inDeck)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: _goldDim,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '✓',
                      style:
                          TextStyle(fontSize: 8, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal inline card renderer (avoids coupling to CardWidget internals).
class _MiniCard extends StatelessWidget {
  final CardDefinition card;
  final bool dimmed;
  final bool hovering;

  const _MiniCard({
    required this.card,
    required this.dimmed,
    required this.hovering,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 76,
      height: 100,
      decoration: BoxDecoration(
        color: dimmed
            ? const Color(0xFF3A3028)
            : const Color(0xFFF5F0E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hovering ? Colors.amber.withAlpha(140) : Colors.transparent,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hovering
                ? Colors.amber.withAlpha(60)
                : Colors.black54,
            blurRadius: hovering ? 8 : 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              card.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: dimmed ? Colors.grey[500] : Colors.black87,
              ),
            ),
            SizedBox(
              width: 55,
              height: 55,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 1,
                ),
                itemCount: 25,
                itemBuilder: (_, i) {
                  final r = i ~/ 5;
                  final c = i % 5;
                  final isCenter = r == 2 && c == 2;
                  final isMove = card.moves.any(
                      (m) => (2 - m.dy) == r && (2 + m.dx) == c);
                  Color cellColor;
                  if (isCenter) {
                    cellColor =
                        dimmed ? Colors.grey[600]! : Colors.grey[700]!;
                  } else if (isMove) {
                    cellColor = dimmed
                        ? Colors.green.withAlpha(80)
                        : const Color(0xFF4CAF50);
                  } else {
                    cellColor =
                        dimmed ? Colors.grey[800]! : Colors.grey[300]!;
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              ),
            ),
            Container(
              width: 16,
              height: 6,
              decoration: BoxDecoration(
                color:
                    card.stampColor.withAlpha(dimmed ? 80 : 200),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// COSMETICS TAB
// ===========================================================================

class _CosmeticsTab extends ConsumerStatefulWidget {
  const _CosmeticsTab();

  @override
  ConsumerState<_CosmeticsTab> createState() => _CosmeticsTabState();
}

class _CosmeticsTabState extends ConsumerState<_CosmeticsTab> {
  CosmeticSlotType? _selectedSlot;
  CosmeticLoadout? _previewLoadout;

  void _selectSlot(CosmeticSlotType slot) {
    setState(() {
      if (_selectedSlot == slot) {
        _selectedSlot = null;
        _previewLoadout = null;
      } else {
        _selectedSlot = slot;
        _previewLoadout = null;
      }
    });
  }

  void _preview(CosmeticLoadout loadout) {
    setState(() => _previewLoadout = loadout);
  }

  void _confirm() {
    final slot = _selectedSlot;
    final preview = _previewLoadout;
    if (slot == null || preview == null) return;

    final notifier = ref.read(cosmeticLoadoutProvider.notifier);
    switch (slot) {
      case CosmeticSlotType.profilePicture:
        notifier.equipProfilePicture(preview.profilePicture);
      case CosmeticSlotType.masterPiece:
        notifier.equipMasterPiece(preview.masterPiece);
      case CosmeticSlotType.studentPiece:
        notifier.equipStudentPiece(preview.studentPiece);
      case CosmeticSlotType.throne:
        notifier.equipThrone(preview.throne);
      case CosmeticSlotType.board:
        notifier.equipBoard(preview.board);
      case CosmeticSlotType.scenery:
        notifier.equipScenery(preview.scenery);
      case CosmeticSlotType.cardBack:
        notifier.equipCardBack(preview.cardBack);
      case CosmeticSlotType.moveEffect:
        notifier.equipMoveEffect(preview.moveEffect);
      case CosmeticSlotType.uiSounds:
        notifier.equipSoundPack(preview.soundPack);
    }

    setState(() {
      _selectedSlot = null;
      _previewLoadout = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final equipped = ref.watch(cosmeticLoadoutProvider);
    final display = _previewLoadout ?? equipped;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final panelOpen = _selectedSlot != null;
        final dollWidth = panelOpen ? totalWidth / 3 : totalWidth * 2 / 3;
        // Subtract the 1px divider so children don't overflow.
        final rosterWidth = totalWidth - dollWidth - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left: paper-doll panel ──────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              width: dollWidth,
              child: _PaperDoll(
                loadout: display,
                selectedSlot: _selectedSlot,
                onSlotTap: _selectSlot,
              ),
            ),

            // Divider
            Container(width: 1, color: _surfaceLight),

            // ── Right: cosmetics roster ──────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              width: rosterWidth,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _selectedSlot == null
                    ? const _RosterHint()
                    : _CosmeticsRoster(
                        key: ValueKey(_selectedSlot),
                        slot: _selectedSlot!,
                        equipped: equipped,
                        preview: _previewLoadout,
                        onPreview: _preview,
                        onConfirm: _confirm,
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Paper doll
// ---------------------------------------------------------------------------

class _PaperDoll extends StatelessWidget {
  final CosmeticLoadout loadout;
  final CosmeticSlotType? selectedSlot;
  final void Function(CosmeticSlotType) onSlotTap;

  const _PaperDoll({
    required this.loadout,
    required this.selectedSlot,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'EQUIPPED',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 10,
                letterSpacing: 3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _SlotIconGrid(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    loadout: loadout,
                    selectedSlot: selectedSlot,
                    onSlotTap: onSlotTap,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slot icon grid
// ---------------------------------------------------------------------------

class _SlotIconGrid extends StatelessWidget {
  final double width;
  final double height;
  final CosmeticLoadout loadout;
  final CosmeticSlotType? selectedSlot;
  final void Function(CosmeticSlotType) onSlotTap;

  const _SlotIconGrid({
    required this.width,
    required this.height,
    required this.loadout,
    required this.selectedSlot,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = (width * 0.22).clamp(36.0, 56.0);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _surfaceLight, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            const Center(
              child: Text(
                '[ art goes here ]',
                style: TextStyle(color: Color(0xFF3A2418), fontSize: 11),
              ),
            ),
            for (final slot in CosmeticSlotType.values)
              _PositionedSlotIcon(
                slot: slot,
                loadout: loadout,
                containerWidth: width,
                containerHeight: height,
                iconSize: iconSize,
                isSelected: selectedSlot == slot,
                onTap: () => onSlotTap(slot),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Positioned slot icon
// ---------------------------------------------------------------------------

class _PositionedSlotIcon extends StatelessWidget {
  final CosmeticSlotType slot;
  final CosmeticLoadout loadout;
  final double containerWidth;
  final double containerHeight;
  final double iconSize;
  final bool isSelected;
  final VoidCallback onTap;

  const _PositionedSlotIcon({
    required this.slot,
    required this.loadout,
    required this.containerWidth,
    required this.containerHeight,
    required this.iconSize,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pos = slot.paperDollOffset;
    final centerX = containerWidth * pos.dx;
    final centerY = containerHeight * pos.dy;
    final totalH = iconSize + 22;
    final totalW = iconSize + 16;

    return Positioned(
      left: centerX - totalW / 2,
      top: centerY - totalH / 2,
      width: totalW,
      height: totalH,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isSelected
                ? _gold.withAlpha(30)
                : _surfaceLight.withAlpha(180),
            border: Border.all(
              color: isSelected ? _gold : _surfaceLight,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                slot.icon,
                size: iconSize * 0.45,
                color: isSelected ? _gold : _textSecondary,
              ),
              const SizedBox(height: 3),
              Text(
                slot.label,
                style: TextStyle(
                  fontSize: (iconSize * 0.18).clamp(8, 11),
                  color: isSelected ? _gold : _textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Roster hint
// ---------------------------------------------------------------------------

class _RosterHint extends StatelessWidget {
  const _RosterHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_outlined, color: _textSecondary, size: 32),
            SizedBox(height: 12),
            Text(
              'Tap a slot to browse\nyour cosmetics',
              style: TextStyle(
                  color: _textSecondary, fontSize: 13, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cosmetics roster
// ---------------------------------------------------------------------------

class _CosmeticsRoster extends ConsumerWidget {
  final CosmeticSlotType slot;
  final CosmeticLoadout equipped;
  final CosmeticLoadout? preview;
  final void Function(CosmeticLoadout) onPreview;
  final VoidCallback onConfirm;

  const _CosmeticsRoster({
    super.key,
    required this.slot,
    required this.equipped,
    required this.preview,
    required this.onPreview,
    required this.onConfirm,
  });

  List<_RosterEntry> _entries(CosmeticCollection collection) {
    return switch (slot) {
      CosmeticSlotType.profilePicture => collection.profilePictures
          .map((c) => _RosterEntry(
                id: c.id,
                name: c.name,
                isEquipped: equipped.profilePicture.id == c.id,
                isPreviewing: preview?.profilePicture.id == c.id,
                onPreview: () => onPreview(equipped.copyWith(profilePicture: c)),
              ))
          .toList(),
      CosmeticSlotType.masterPiece => collection.masterPieces
          .map((c) => _RosterEntry(
                id: c.id,
                name: c.name,
                isEquipped: equipped.masterPiece.id == c.id,
                isPreviewing: preview?.masterPiece.id == c.id,
                onPreview: () => onPreview(equipped.copyWith(masterPiece: c)),
              ))
          .toList(),
      CosmeticSlotType.studentPiece => collection.studentPieces
          .map((c) => _RosterEntry(
                id: c.id,
                name: c.name,
                isEquipped: equipped.studentPiece.id == c.id,
                isPreviewing: preview?.studentPiece.id == c.id,
                onPreview: () => onPreview(equipped.copyWith(studentPiece: c)),
              ))
          .toList(),
      CosmeticSlotType.throne => collection.thrones
          .map((c) => _RosterEntry(
                id: c.id,
                name: c.name,
                isEquipped: equipped.throne.id == c.id,
                isPreviewing: preview?.throne.id == c.id,
                onPreview: () => onPreview(equipped.copyWith(throne: c)),
              ))
          .toList(),
      CosmeticSlotType.board => collection.boards
          .map((c) => _RosterEntry(
                id: c.id,
                name: c.name,
                isEquipped: equipped.board.id == c.id,
                isPreviewing: preview?.board.id == c.id,
                onPreview: () => onPreview(equipped.copyWith(board: c)),
              ))
          .toList(),
      CosmeticSlotType.scenery => collection.sceneries
          .map((c) => _RosterEntry(
                id: c.id,
                name: c.name,
                isEquipped: equipped.scenery.id == c.id,
                isPreviewing: preview?.scenery.id == c.id,
                onPreview: () => onPreview(equipped.copyWith(scenery: c)),
              ))
          .toList(),
      CosmeticSlotType.cardBack => collection.cardBacks
          .map((c) => _RosterEntry(
                id: c.id,
                name: c.name,
                isEquipped: equipped.cardBack.id == c.id,
                isPreviewing: preview?.cardBack.id == c.id,
                onPreview: () => onPreview(equipped.copyWith(cardBack: c)),
              ))
          .toList(),
      CosmeticSlotType.moveEffect => collection.moveEffects
          .map((c) => _RosterEntry(
                id: c.id,
                name: c.name,
                isEquipped: equipped.moveEffect.id == c.id,
                isPreviewing: preview?.moveEffect.id == c.id,
                onPreview: () => onPreview(equipped.copyWith(moveEffect: c)),
              ))
          .toList(),
      CosmeticSlotType.uiSounds => collection.soundPacks
          .map((c) => _RosterEntry(
                id: c.id,
                name: c.name,
                isEquipped: equipped.soundPack.id == c.id,
                isPreviewing: preview?.soundPack.id == c.id,
                onPreview: () => onPreview(equipped.copyWith(soundPack: c)),
              ))
          .toList(),
    };
  }

  bool get _hasUnsavedPreview {
    if (preview == null) return false;
    return switch (slot) {
      CosmeticSlotType.profilePicture =>
        preview!.profilePicture.id != equipped.profilePicture.id,
      CosmeticSlotType.masterPiece =>
        preview!.masterPiece.id != equipped.masterPiece.id,
      CosmeticSlotType.studentPiece =>
        preview!.studentPiece.id != equipped.studentPiece.id,
      CosmeticSlotType.throne => preview!.throne.id != equipped.throne.id,
      CosmeticSlotType.board => preview!.board.id != equipped.board.id,
      CosmeticSlotType.scenery => preview!.scenery.id != equipped.scenery.id,
      CosmeticSlotType.cardBack =>
        preview!.cardBack.id != equipped.cardBack.id,
      CosmeticSlotType.moveEffect =>
        preview!.moveEffect.id != equipped.moveEffect.id,
      CosmeticSlotType.uiSounds =>
        preview!.soundPack.id != equipped.soundPack.id,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collection = ref.watch(cosmeticCollectionProvider);
    final entries = _entries(collection);

    return Container(
      color: _surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: _surfaceLight,
            child: Row(
              children: [
                Icon(slot.icon, color: _gold, size: 18),
                const SizedBox(width: 10),
                Text(
                  slot.label.toUpperCase(),
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: entries.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: _surfaceLight),
              itemBuilder: (_, i) => _RosterItem(entry: entries[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: _hasUnsavedPreview ? onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _goldDim,
                disabledBackgroundColor: _surfaceLight,
                foregroundColor: Colors.white,
                disabledForegroundColor: _textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'EQUIP',
                style:
                    TextStyle(letterSpacing: 3, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Roster entry data
// ---------------------------------------------------------------------------

class _RosterEntry {
  final String id;
  final String name;
  final bool isEquipped;
  final bool isPreviewing;
  final VoidCallback onPreview;

  const _RosterEntry({
    required this.id,
    required this.name,
    required this.isEquipped,
    required this.isPreviewing,
    required this.onPreview,
  });
}

class _RosterItem extends StatelessWidget {
  final _RosterEntry entry;
  const _RosterItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    final bg = entry.isPreviewing
        ? _gold.withAlpha(20)
        : entry.isEquipped
            ? _surfaceLight
            : Colors.transparent;

    final nameColor = entry.isPreviewing
        ? _gold
        : entry.isEquipped
            ? _textPrimary
            : _textSecondary;

    return GestureDetector(
      onTap: entry.onPreview,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 4,
              height: 36,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: entry.isPreviewing
                    ? _gold
                    : entry.isEquipped
                        ? _goldDim
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Text(
                entry.name,
                style: TextStyle(
                  color: nameColor,
                  fontSize: 14,
                  fontWeight: entry.isPreviewing || entry.isEquipped
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
            if (entry.isEquipped && !entry.isPreviewing)
              const Icon(Icons.check_circle_outline, color: _goldDim, size: 16),
            if (entry.isPreviewing)
              const Text(
                'PREVIEW',
                style: TextStyle(
                  color: _gold,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
