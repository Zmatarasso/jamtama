import 'master_piece_cosmetic.dart';
import 'student_piece_cosmetic.dart';
import 'throne_cosmetic.dart';
import 'board_cosmetic.dart';
import 'scenery_cosmetic.dart';
import 'card_back_cosmetic.dart';
import 'move_effect_cosmetic.dart';
import 'ui_sounds_cosmetic.dart';

/// The full set of independently-equippable cosmetic slots for one player
/// session. Each slot can be swapped without affecting the others — this is
/// the data model behind the unlockable cosmetics system.
class CosmeticLoadout {
  final MasterPieceCosmetic masterPiece;
  final StudentPieceCosmetic studentPiece;
  final ThroneCosmetic throne;
  final BoardCosmetic board;
  final SceneryCosmetic scenery;
  final CardBackCosmetic cardBack;
  final MoveEffectCosmetic moveEffect;

  /// UI interaction sounds (card select, piece select, draft flip, win fanfares).
  final UiSoundsCosmetic uiSounds;

  const CosmeticLoadout({
    required this.masterPiece,
    required this.studentPiece,
    required this.throne,
    required this.board,
    required this.scenery,
    required this.cardBack,
    required this.moveEffect,
    required this.uiSounds,
  });

  CosmeticLoadout copyWith({
    MasterPieceCosmetic? masterPiece,
    StudentPieceCosmetic? studentPiece,
    ThroneCosmetic? throne,
    BoardCosmetic? board,
    SceneryCosmetic? scenery,
    CardBackCosmetic? cardBack,
    MoveEffectCosmetic? moveEffect,
    UiSoundsCosmetic? uiSounds,
  }) =>
      CosmeticLoadout(
        masterPiece: masterPiece ?? this.masterPiece,
        studentPiece: studentPiece ?? this.studentPiece,
        throne: throne ?? this.throne,
        board: board ?? this.board,
        scenery: scenery ?? this.scenery,
        cardBack: cardBack ?? this.cardBack,
        moveEffect: moveEffect ?? this.moveEffect,
        uiSounds: uiSounds ?? this.uiSounds,
      );
}
