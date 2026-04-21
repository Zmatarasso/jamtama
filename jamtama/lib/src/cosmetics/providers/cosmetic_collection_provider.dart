import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sound_packs.dart';
import '../defaults/default_cosmetics.dart';
import '../models/board_cosmetic.dart';
import '../models/card_back_cosmetic.dart';
import '../models/master_piece_cosmetic.dart';
import '../models/move_effect_cosmetic.dart';
import '../models/profile_picture_cosmetic.dart';
import '../models/scenery_cosmetic.dart';
import '../models/sound_pack.dart';
import '../models/student_piece_cosmetic.dart';
import '../models/throne_cosmetic.dart';

/// Everything the player currently owns, indexed by slot type.
///
/// For now each slot only contains the built-in defaults. When unlock /
/// purchase mechanics are added, make this a [NotifierProvider] and append
/// items to the appropriate list.
class CosmeticCollection {
  final List<ProfilePictureCosmetic> profilePictures;
  final List<MasterPieceCosmetic> masterPieces;
  final List<StudentPieceCosmetic> studentPieces;
  final List<ThroneCosmetic> thrones;
  final List<BoardCosmetic> boards;
  final List<SceneryCosmetic> sceneries;
  final List<CardBackCosmetic> cardBacks;
  final List<MoveEffectCosmetic> moveEffects;
  final List<SoundPack> soundPacks;

  const CosmeticCollection({
    required this.profilePictures,
    required this.masterPieces,
    required this.studentPieces,
    required this.thrones,
    required this.boards,
    required this.sceneries,
    required this.cardBacks,
    required this.moveEffects,
    required this.soundPacks,
  });
}

final cosmeticCollectionProvider = Provider<CosmeticCollection>((_) {
  return const CosmeticCollection(
    profilePictures: [
      defaultProfilePicture,
      crownProfilePicture,
      starProfilePicture,
      shieldProfilePicture,
    ],
    masterPieces: [defaultMasterPiece, woodMasterPiece, stoneMasterPiece],
    studentPieces: [defaultStudentPiece, woodStudentPiece, stoneStudentPiece],
    thrones: [defaultThrone, beatingHeartThrone],
    boards: [defaultBoard, woodGrainBoard, stoneBoard],
    sceneries: [defaultScenery],
    cardBacks: [defaultCardBack],
    moveEffects: [defaultMoveEffect, glitterMoveEffect],
    soundPacks: allSoundPacks,
  );
});
