import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/match_provider.dart';
import '../providers/tutorial_provider.dart';
import '../providers/wallet_provider.dart';
import 'collection_screen.dart';
import 'matchmaking_screen.dart';
import 'options_screen.dart';
import 'shop_screen.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Auto-start the tutorial the very first time the menu is shown.
      final tutorialNotifier = ref.read(tutorialProvider.notifier);
      if (!tutorialNotifier.isDone) {
        tutorialNotifier.start();
        return; // skip daily bonus snackbar during tutorial
      }

      // Daily login bonus — only shown if tutorial is already done.
      final claimed = ref.read(dailyLoginProvider.notifier).claim();
      if (claimed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 20),
                const SizedBox(width: 8),
                Text('Daily login bonus: +$dailyLoginBonus coins!'),
              ],
            ),
            backgroundColor: const Color(0xFF3A2010),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0F08),
      body: SafeArea(
        child: Column(
          children: [
            // ── Title ──
            const Spacer(flex: 2),
            const _Title(),
            const Spacer(flex: 3),

            // ── Menu buttons ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MenuButton(
                    label: 'Find a Match',
                    icon: Icons.search,
                    onTap: () {
                      final notifier = ref.read(tutorialProvider.notifier);
                      if (!notifier.isDone) {
                        notifier.start();
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MatchmakingScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _MenuButton(
                    label: 'Local Match',
                    icon: Icons.people,
                    primary: true,
                    onTap: () =>
                        ref.read(matchProvider.notifier).startLocalMatch(),
                  ),
                  const SizedBox(height: 14),
                  _MenuButton(
                    label: 'Test Match',
                    icon: Icons.science_outlined,
                    onTap: () =>
                        ref.read(matchProvider.notifier).startTestMatch(),
                  ),
                  const SizedBox(height: 14),
                  _MenuButton(
                    label: 'Shop',
                    icon: Icons.storefront,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ShopScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MenuButton(
                    label: 'Collection',
                    icon: Icons.style,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CollectionScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MenuButton(
                    label: 'Options',
                    icon: Icons.settings,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OptionsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'ROYAL RUCKUS',
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w900,
            letterSpacing: 10,
            color: Colors.white,
            shadows: [
              Shadow(
                color: const Color(0xFF8B6914).withAlpha(200),
                blurRadius: 24,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          width: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.transparent, Color(0xFF8B6914), Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        splashColor: const Color(0xFF8B6914).withAlpha(60),
        highlightColor: const Color(0xFF8B6914).withAlpha(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: primary
                  ? const Color(0xFF8B6914)
                  : const Color(0xFF8B6914).withAlpha(80),
              width: primary ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
            color: primary
                ? const Color(0xFF8B6914).withAlpha(30)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: primary
                    ? const Color(0xFFD4A843)
                    : const Color(0xFF8B6914),
                size: 20,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: primary ? const Color(0xFFD4A843) : Colors.white70,
                  fontSize: 16,
                  fontWeight:
                      primary ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

