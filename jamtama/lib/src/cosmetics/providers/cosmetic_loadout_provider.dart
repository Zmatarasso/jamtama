import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/user_data_repository_provider.dart';
import '../defaults/default_cosmetics.dart';
import '../models/board_cosmetic.dart';
import '../models/card_back_cosmetic.dart';
import '../models/cosmetic_loadout.dart';
import '../models/master_piece_cosmetic.dart';
import '../models/move_effect_cosmetic.dart';
import '../models/profile_picture_cosmetic.dart';
import '../models/scenery_cosmetic.dart';
import '../models/sound_pack.dart';
import '../models/student_piece_cosmetic.dart';
import '../models/throne_cosmetic.dart';
import 'cosmetic_collection_provider.dart';

final cosmeticLoadoutProvider =
    NotifierProvider<CosmeticLoadoutNotifier, CosmeticLoadout>(
  CosmeticLoadoutNotifier.new,
);

/// Manages the currently-equipped cosmetic loadout.
///
/// Loads from [UserDataRepository] on first build (synchronous — prefs are
/// already in memory by the time the app starts). Saves to the repository
/// after every equip call.
///
/// Widgets should use [cosmeticLoadoutProvider.select] to subscribe to only
/// the slot they render:
///
/// ```dart
/// final board = ref.watch(cosmeticLoadoutProvider.select((l) => l.board));
/// ```
class CosmeticLoadoutNotifier extends Notifier<CosmeticLoadout> {
  @override
  CosmeticLoadout build() {
    final repo = ref.read(userDataRepositoryProvider);
    final ids = repo.loadLoadoutIds();
    if (ids == null) return defaultLoadout;
    return _loadoutFromIds(ids);
  }

  // ── Equip methods ────────────────────────────────────────────────────────

  void equipProfilePicture(ProfilePictureCosmetic item) =>
      _update(state.copyWith(profilePicture: item));

  void equipMasterPiece(MasterPieceCosmetic item) =>
      _update(state.copyWith(masterPiece: item));

  void equipStudentPiece(StudentPieceCosmetic item) =>
      _update(state.copyWith(studentPiece: item));

  void equipThrone(ThroneCosmetic item) =>
      _update(state.copyWith(throne: item));

  void equipBoard(BoardCosmetic item) =>
      _update(state.copyWith(board: item));

  void equipScenery(SceneryCosmetic item) =>
      _update(state.copyWith(scenery: item));

  void equipCardBack(CardBackCosmetic item) =>
      _update(state.copyWith(cardBack: item));

  void equipMoveEffect(MoveEffectCosmetic item) =>
      _update(state.copyWith(moveEffect: item));

  void equipSoundPack(SoundPack item) =>
      _update(state.copyWith(soundPack: item));

  // ── Internal ────────────────────────────────────────────────────────────

  void _update(CosmeticLoadout next) {
    state = next;
    // Fire-and-forget; UI never waits for this.
    ref.read(userDataRepositoryProvider).saveLoadoutIds(_idsFromLoadout(next));
  }

  /// Resolve persisted IDs back to cosmetic objects via the collection.
  /// Falls back to defaults for any ID that isn't found (e.g. after an item
  /// is removed from the catalogue).
  CosmeticLoadout _loadoutFromIds(Map<String, String> ids) {
    final c = ref.read(cosmeticCollectionProvider);

    T pick<T>(List<T> list, String? id, T fallback, String Function(T) getId) =>
        list.firstWhere((e) => getId(e) == id, orElse: () => fallback);

    return CosmeticLoadout(
      profilePicture: pick(c.profilePictures, ids['profilePictureId'],
          defaultLoadout.profilePicture, (e) => e.id),
      masterPiece: pick(c.masterPieces, ids['masterPieceId'],
          defaultLoadout.masterPiece, (e) => e.id),
      studentPiece: pick(c.studentPieces, ids['studentPieceId'],
          defaultLoadout.studentPiece, (e) => e.id),
      throne: pick(
          c.thrones, ids['throneId'], defaultLoadout.throne, (e) => e.id),
      board: pick(c.boards, ids['boardId'], defaultLoadout.board, (e) => e.id),
      scenery: pick(
          c.sceneries, ids['sceneryId'], defaultLoadout.scenery, (e) => e.id),
      cardBack: pick(c.cardBacks, ids['cardBackId'], defaultLoadout.cardBack,
          (e) => e.id),
      moveEffect: pick(c.moveEffects, ids['moveEffectId'],
          defaultLoadout.moveEffect, (e) => e.id),
      soundPack: pick(c.soundPacks, ids['soundPackId'],
          defaultLoadout.soundPack, (e) => e.id),
    );
  }

  Map<String, String> _idsFromLoadout(CosmeticLoadout l) => {
        'profilePictureId': l.profilePicture.id,
        'masterPieceId': l.masterPiece.id,
        'studentPieceId': l.studentPiece.id,
        'throneId': l.throne.id,
        'boardId': l.board.id,
        'sceneryId': l.scenery.id,
        'cardBackId': l.cardBack.id,
        'moveEffectId': l.moveEffect.id,
        'soundPackId': l.soundPack.id,
      };
}
