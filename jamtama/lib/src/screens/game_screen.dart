import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';  // For firstWhereOrNull.
import '../providers/game_provider.dart';
import '../models/piece.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    ref.read(gameProvider.notifier).initGame();  // One-time init.

    return Scaffold(
      appBar: AppBar(title: const Text('Jamtama Game')),
      body: Center(
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 1,
          ),
          itemCount: 25,
          itemBuilder: (context, index) {
            final row = index ~/ 5;
            final col = index % 5;
            final piece = game.pieces.firstWhereOrNull((p) => p.row == row && p.col == col);
            return GestureDetector(
              onTap: () {
                if (piece != null) {
                  ref.read(gameProvider.notifier).selectPiece(piece);
                } else if (game.selectedPiece != null) {
                  ref.read(gameProvider.notifier).movePiece(row, col);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: (piece?.player == Player.red ? Colors.red[100] : Colors.blue[100]) ??
                    (index % 2 == 0 ? Colors.grey[200] : Colors.white),
                child: Center(
                  child: Text(piece?.type.name[0].toUpperCase() ?? ''),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}