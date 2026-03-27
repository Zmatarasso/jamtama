import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../defaults/default_cosmetics.dart';
import '../models/board_cosmetic.dart';
import '../models/card_back_cosmetic.dart';
import '../models/master_piece_cosmetic.dart';
import '../models/move_effect_cosmetic.dart';
import '../models/scenery_cosmetic.dart';
import '../models/student_piece_cosmetic.dart';
import '../models/throne_cosmetic.dart';
import '../models/ui_sounds_cosmetic.dart';

/// Everything the player currently owns, indexed by slot type.
///
/// For now each slot only contains the built-in default. When unlock / purchase
/// mechanics are added, make this a [NotifierProvider] and append items.
class CosmeticCollection {
  final List<MasterPieceCosmetic> masterPieces;
  final List<StudentPieceCosmetic> studentPieces;
  final List<ThroneCosmetic> thrones;
  final List<BoardCosmetic> boards;
  final List<SceneryCosmetic> sceneries;
  final List<CardBackCosmetic> cardBacks;
  final List<MoveEffectCosmetic> moveEffects;
  final List<UiSoundsCosmetic> uiSoundSets;

  const CosmeticCollection({
    required this.masterPieces,
    required this.studentPieces,
    required this.thrones,
    required this.boards,
    required this.sceneries,
    required this.cardBacks,
    required this.moveEffects,
    required this.uiSoundSets,
  });
}

final cosmeticCollectionProvider = Provider<CosmeticCollection>((_) {
  return const CosmeticCollection(
    masterPieces: [defaultMasterPiece, woodMasterPiece, stoneMasterPiece],
    studentPieces: [defaultStudentPiece, woodStudentPiece, stoneStudentPiece],
    thrones: [defaultThrone, beatingHeartThrone],
    boards: [defaultBoard, woodGrainBoard, stoneBoard],
    sceneries: [defaultScenery],
    cardBacks: [defaultCardBack],
    moveEffects: [defaultMoveEffect, glitterMoveEffect],
    uiSoundSets: [defaultUiSounds],
  );
});
