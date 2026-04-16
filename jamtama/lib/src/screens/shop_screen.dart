import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cosmetics/models/cosmetic_slot_type.dart';
import '../data/card_definitions.dart';
import '../models/card.dart';
import '../providers/wallet_provider.dart';
import '../widgets/card_widget.dart';

// ---------------------------------------------------------------------------
// Colours (consistent with collection_screen)
// ---------------------------------------------------------------------------

const _bg = Color(0xFF1A0F08);
const _surface = Color(0xFF2B1810);
const _gold = Color(0xFFFFD700);
const _goldDim = Color(0xFF8B6914);
const _textPrimary = Colors.white;
const _textSecondary = Color(0xFFAA9980);

// ---------------------------------------------------------------------------
// Shop data
// ---------------------------------------------------------------------------

const int randomCardPrice = 100;

/// Placeholder cosmetic shop items — expand as new cosmetics are added.
class ShopCosmeticItem {
  final String id;
  final String name;
  final CosmeticSlotType slot;
  final int price;
  final IconData icon;

  const ShopCosmeticItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.price,
    required this.icon,
  });
}

const _cosmeticShopItems = <ShopCosmeticItem>[
  ShopCosmeticItem(
    id: 'board_stone',
    name: 'Stone Board',
    slot: CosmeticSlotType.board,
    price: 200,
    icon: Icons.grid_on,
  ),
  ShopCosmeticItem(
    id: 'scenery_forest',
    name: 'Forest Scenery',
    slot: CosmeticSlotType.scenery,
    price: 150,
    icon: Icons.landscape,
  ),
  ShopCosmeticItem(
    id: 'card_back_dragon',
    name: 'Dragon Card Back',
    slot: CosmeticSlotType.cardBack,
    price: 120,
    icon: Icons.style,
  ),
  ShopCosmeticItem(
    id: 'move_fire',
    name: 'Fire Trail Effect',
    slot: CosmeticSlotType.moveEffect,
    price: 250,
    icon: Icons.auto_awesome,
  ),
];

// ---------------------------------------------------------------------------
// Shop screen entry
// ---------------------------------------------------------------------------

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

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
            'SHOP',
            style: TextStyle(
              letterSpacing: 4,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          actions: const [_CoinDisplay()],
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
            _CardsShopTab(),
            _CosmeticsShopTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Coin display in app bar
// ---------------------------------------------------------------------------

class _CoinDisplay extends ConsumerWidget {
  const _CoinDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(walletProvider);
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: _gold, size: 20),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              color: _gold,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// CARDS SHOP TAB — Random card packs
// ===========================================================================

class _CardsShopTab extends ConsumerWidget {
  const _CardsShopTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mystery card pack artwork
            Container(
              width: 140,
              height: 190,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3A2418), Color(0xFF5A3828)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _goldDim, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withAlpha(40),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.help_outline, size: 48, color: _gold),
                  SizedBox(height: 12),
                  Text(
                    '???',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'RANDOM CARD',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Receive a random card for your collection',
              style: TextStyle(color: _textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _BuyButton(
              price: randomCardPrice,
              onPressed: () => _startRandomCardPurchase(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _startRandomCardPurchase(BuildContext context, WidgetRef ref) {
    final wallet = ref.read(walletProvider.notifier);
    if (!wallet.canAfford(randomCardPrice)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough coins!'),
          backgroundColor: Color(0xFF8B2020),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RandomCardConfirmDialog(ref: ref),
    );
  }
}

// ---------------------------------------------------------------------------
// Buy button
// ---------------------------------------------------------------------------

class _BuyButton extends ConsumerWidget {
  final int price;
  final VoidCallback onPressed;

  const _BuyButton({required this.price, required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAfford = ref.watch(walletProvider) >= price;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canAfford ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        splashColor: _gold.withAlpha(60),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: canAfford ? _gold : _goldDim.withAlpha(60),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
            color: canAfford ? _gold.withAlpha(30) : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monetization_on,
                color: canAfford ? _gold : _goldDim.withAlpha(80),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '$price',
                style: TextStyle(
                  color: canAfford ? _gold : _goldDim.withAlpha(80),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Random card confirm dialog
// ---------------------------------------------------------------------------

class _RandomCardConfirmDialog extends StatelessWidget {
  final WidgetRef ref;

  const _RandomCardConfirmDialog({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PURCHASE RANDOM CARD',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Spend $randomCardPrice coins to receive a random card?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(color: _textSecondary, letterSpacing: 1),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _goldDim,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    final wallet = ref.read(walletProvider.notifier);
                    if (!wallet.spend(randomCardPrice)) {
                      Navigator.of(context).pop();
                      return;
                    }
                    // Pick a random card
                    final card =
                        allCards[Random().nextInt(allCards.length)];
                    Navigator.of(context).pop();
                    // Launch the reveal animation
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => _CardRevealAnimation(card: card),
                    );
                  },
                  child: const Text('CONFIRM', style: TextStyle(letterSpacing: 1)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Card Reveal Animation — 3D parallax spin that slows to reveal
// ===========================================================================

class _CardRevealAnimation extends StatefulWidget {
  final CardDefinition card;

  const _CardRevealAnimation({required this.card});

  @override
  State<_CardRevealAnimation> createState() => _CardRevealAnimationState();
}

class _CardRevealAnimationState extends State<_CardRevealAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _spinAnimation;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );

    // The spin goes through many full rotations, decelerating.
    // Total rotations: ~6 full spins (6 * 2π) ending face-up (0 mod 2π).
    _spinAnimation = Tween<double>(
      begin: 0,
      end: 6 * 2 * pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutExpo,
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _revealed = true);
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 280,
            width: 200,
            child: AnimatedBuilder(
              animation: _spinAnimation,
              builder: (context, child) {
                final angle = _spinAnimation.value;
                // Determine if we're showing the back (card is facing away)
                // The card flips around the Y axis — when cos(angle) < 0 we
                // see the back.
                final showBack = cos(angle) < 0;
                final perspectiveAngle = showBack ? angle + pi : angle;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateY(perspectiveAngle),
                  child: showBack
                      ? _CardBack()
                      : _revealed
                          ? _RevealedCard(card: widget.card)
                          : _SpinningCardFace(),
                );
              },
            ),
          ),
          if (_revealed) ...[
            const SizedBox(height: 20),
            Text(
              'You got: ${widget.card.name}!',
              style: const TextStyle(
                color: _gold,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _goldDim,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('NICE!', style: TextStyle(letterSpacing: 2)),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 140,
        height: 190,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A2418), Color(0xFF5A3828)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _goldDim, width: 2),
        ),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: _goldDim.withAlpha(120), width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: _goldDim.withAlpha(150),
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpinningCardFace extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 140,
        height: 190,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0E0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _goldDim, width: 2),
        ),
        child: const Center(
          child: Icon(Icons.help_outline, size: 48, color: Color(0xFF8B6914)),
        ),
      ),
    );
  }
}

class _RevealedCard extends StatelessWidget {
  final CardDefinition card;

  const _RevealedCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.scale(
        scale: 1.8,
        child: CardWidget(card: card),
      ),
    );
  }
}

// ===========================================================================
// COSMETICS SHOP TAB
// ===========================================================================

class _CosmeticsShopTab extends StatelessWidget {
  const _CosmeticsShopTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cosmeticShopItems.length,
      itemBuilder: (context, index) {
        final item = _cosmeticShopItems[index];
        return _CosmeticShopTile(item: item);
      },
    );
  }
}

class _CosmeticShopTile extends ConsumerWidget {
  final ShopCosmeticItem item;

  const _CosmeticShopTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: _gold.withAlpha(30),
          onTap: () => _showPreview(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _goldDim.withAlpha(60)),
                  ),
                  child: Icon(item.icon, color: _goldDim, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.slot.label,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, color: _gold, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${item.price}',
                      style: const TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPreview(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _CosmeticPreviewDialog(item: item, ref: ref),
    );
  }
}

// ---------------------------------------------------------------------------
// Cosmetic preview dialog — close-up view + confirm
// ---------------------------------------------------------------------------

class _CosmeticPreviewDialog extends StatelessWidget {
  final ShopCosmeticItem item;
  final WidgetRef ref;

  const _CosmeticPreviewDialog({required this.item, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close-up preview
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _goldDim.withAlpha(80), width: 1.5),
              ),
              child: Icon(item.icon, color: _gold, size: 56),
            ),
            const SizedBox(height: 20),
            Text(
              item.name,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.slot.label,
              style: const TextStyle(color: _textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(color: _textSecondary, letterSpacing: 1),
                  ),
                ),
                _BuyButton(
                  price: item.price,
                  onPressed: () {
                    final wallet = ref.read(walletProvider.notifier);
                    if (!wallet.spend(item.price)) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Not enough coins!'),
                          backgroundColor: Color(0xFF8B2020),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => _SoldStampDialog(itemName: item.name),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Sold stamp animation
// ===========================================================================

class _SoldStampDialog extends StatefulWidget {
  final String itemName;

  const _SoldStampDialog({required this.itemName});

  @override
  State<_SoldStampDialog> createState() => _SoldStampDialogState();
}

class _SoldStampDialogState extends State<_SoldStampDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Stamp slams in from large scale → bounces to final size
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 3.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Slight rotation for that rubber-stamp feel
    _rotationAnimation = Tween<double>(
      begin: -0.15,
      end: -0.08,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 140,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFCC3333),
                              width: 4,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'SOLD',
                            style: TextStyle(
                              color: Color(0xFFCC3333),
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.itemName,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Added to your collection!',
              style: TextStyle(color: _textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _goldDim,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(letterSpacing: 2)),
            ),
          ],
        ),
      ),
    );
  }
}
