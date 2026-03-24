import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/match_provider.dart';
import 'collection_screen.dart';
import 'options_screen.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      // TODO: matchmaking
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Matchmaking coming soon'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Color(0xFF3A2010),
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
          'JAMTAMA',
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

