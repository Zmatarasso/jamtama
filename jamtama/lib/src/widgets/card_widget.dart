import 'package:flutter/material.dart';

import '../models/card.dart';

/// Renders a single card with its name and a 5×5 move diagram.
class CardWidget extends StatefulWidget {
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
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final lift = widget.selected ? -8.0 : (_hovering ? -4.0 : 0.0);
    final borderColor = widget.selected
        ? Colors.amber
        : (_hovering ? Colors.amber.withAlpha(140) : Colors.transparent);
    final shadowColor = widget.selected
        ? Colors.amber.withAlpha(120)
        : (_hovering ? Colors.amber.withAlpha(60) : Colors.black54);
    final shadowBlur = widget.selected ? 12.0 : (_hovering ? 8.0 : 4.0);

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 76,
          height: 100,
          transform: Matrix4.translationValues(0, lift, 0),
          decoration: BoxDecoration(
            color: widget.dimmed
                ? const Color(0xFF3A3028)
                : const Color(0xFFF5F0E0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: shadowBlur,
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
                  widget.card.name,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: widget.dimmed ? Colors.grey[500] : Colors.black87,
                  ),
                ),
                _MoveDiagram(card: widget.card, dimmed: widget.dimmed),
                Container(
                  width: 16,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.card.stampColor
                        .withAlpha(widget.dimmed ? 80 : 200),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
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
          final isMove =
              card.moves.any((m) => (2 - m.dy) == r && (2 + m.dx) == c);

          Color cellColor;
          if (isCenter) {
            cellColor = dimmed ? Colors.grey[600]! : Colors.grey[700]!;
          } else if (isMove) {
            cellColor =
                dimmed ? Colors.green.withAlpha(80) : const Color(0xFF4CAF50);
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
