import 'package:flutter/material.dart';

import '../models/card.dart';

/// Renders a single card with its name and a 5×5 move diagram.
///
/// The diagram uses the player-relative coordinate convention:
///   centre (2,2) = current position
///   dy > 0 = forward (up on the diagram)
///   dx > 0 = right
///
/// When displayed inside a RotatedBox(quarterTurns:2) for the opposing
/// player, the diagram automatically appears from that player's viewpoint.
class CardWidget extends StatelessWidget {
  final CardDefinition card;
  final bool selected;
  final bool dimmed;
  final VoidCallback? onTap;

  const CardWidget({
    super.key,
    required this.card,
    this.selected = false,
    this.dimmed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 76,
        height: 100,
        transform: Matrix4.translationValues(0, selected ? -6.0 : 0, 0),
        decoration: BoxDecoration(
          color: dimmed
              ? const Color(0xFF3A3028)
              : const Color(0xFFF5F0E0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Colors.amber : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? Colors.amber.withAlpha(120)
                  : Colors.black54,
              blurRadius: selected ? 10 : 4,
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
              _MoveDiagram(card: card, dimmed: dimmed),
              Container(
                width: 16,
                height: 6,
                decoration: BoxDecoration(
                  color: card.stampColor.withAlpha(dimmed ? 80 : 200),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoveDiagram extends StatelessWidget {
  final CardDefinition card;
  final bool dimmed;

  const _MoveDiagram({required this.card, required this.dimmed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 55,
      height: 55,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
        ),
        itemCount: 25,
        itemBuilder: (_, i) {
          final r = i ~/ 5;
          final c = i % 5;
          final isCenter = r == 2 && c == 2;
          // Move (dx,dy) maps to diagram cell (2 - dy, 2 + dx).
          final isMove =
              card.moves.any((m) => (2 - m.dy) == r && (2 + m.dx) == c);

          Color cellColor;
          if (isCenter) {
            cellColor = dimmed ? Colors.grey[600]! : Colors.grey[700]!;
          } else if (isMove) {
            cellColor = dimmed
                ? Colors.green.withAlpha(80)
                : const Color(0xFF4CAF50);
          } else {
            cellColor = dimmed ? Colors.grey[800]! : Colors.grey[300]!;
          }

          return Container(
            decoration: BoxDecoration(
              color: cellColor,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        },
      ),
    );
  }
}
