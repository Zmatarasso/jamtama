import 'master_piece_cosmetic.dart';
import 'profile_picture_cosmetic.dart';
import 'student_piece_cosmetic.dart';
import 'throne_cosmetic.dart';
import 'board_cosmetic.dart';
import 'scenery_cosmetic.dart';
import 'card_back_cosmetic.dart';
import 'move_effect_cosmetic.dart';
import 'sound_pack.dart';

/// The full set of independently-equippable cosmetic slots for one player
/// session. Each slot can be swapped without affecting the others — this is
/// the data model behind the unlockable cosmetics system.
class CosmeticLoadout {
  final ProfilePictureCosmetic profilePicture;
  final MasterPieceCosmetic masterPiece;
  final StudentPieceCosmetic studentPiece;
  final ThroneCosmetic throne;
  final BoardCosmetic board;
  final SceneryCosmetic scenery;
  final CardBackCosmetic cardBack;
  final MoveEffectCosmetic moveEffect;

  /// All game sounds — swap to replace every sound at once.
  final SoundPack soundPack;

  const CosmeticLoadout({
    required this.profilePicture,
    required this.masterPiece,
    required this.studentPiece,
    required this.throne,
    required this.board,
    required this.scenery,
    required this.cardBack,
    required this.moveEffect,
    required this.soundPack,
  });

  CosmeticLoadout copyWith({
    ProfilePictureCosmetic? profilePicture,
    MasterPieceCosmetic? masterPiece,
    StudentPieceCosmetic? studentPiece,
    ThroneCosmetic? throne,
    BoardCosmetic? board,
    SceneryCosmetic? scenery,
    CardBackCosmetic? cardBack,
    MoveEffectCosmetic? moveEffect,
    SoundPack? soundPack,
  }) =>
      CosmeticLoadout(
        profilePicture: profilePicture ?? this.profilePicture,
        masterPiece: masterPiece ?? this.masterPiece,
        studentPiece: studentPiece ?? this.studentPiece,
        throne: throne ?? this.throne,
        board: board ?? this.board,
        scenery: scenery ?? this.scenery,
        cardBack: cardBack ?? this.cardBack,
        moveEffect: moveEffect ?? this.moveEffect,
        soundPack: soundPack ?? this.soundPack,
      );
}
