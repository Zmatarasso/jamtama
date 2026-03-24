import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../defaults/default_cosmetics.dart';
import '../models/board_cosmetic.dart';
import '../models/card_back_cosmetic.dart';
import '../models/cosmetic_loadout.dart';
import '../models/master_piece_cosmetic.dart';
import '../models/move_effect_cosmetic.dart';
import '../models/scenery_cosmetic.dart';
import '../models/student_piece_cosmetic.dart';
import '../models/throne_cosmetic.dart';
import '../models/ui_sounds_cosmetic.dart';

final cosmeticLoadoutProvider =
    NotifierProvider<CosmeticLoadoutNotifier, CosmeticLoadout>(
  CosmeticLoadoutNotifier.new,
);

/// Manages the currently-equipped cosmetic loadout.
///
/// Each slot is independently swappable. Widgets should use
/// [cosmeticLoadoutProvider.select] to subscribe to only the slot they
/// render, so unrelated slot changes don't trigger unnecessary rebuilds:
///
/// ```dart
/// final board = ref.watch(cosmeticLoadoutProvider.select((l) => l.board));
/// ```
class CosmeticLoadoutNotifier extends Notifier<CosmeticLoadout> {
  @override
  CosmeticLoadout build() => defaultLoadout;

  void equipMasterPiece(MasterPieceCosmetic item) =>
      state = state.copyWith(masterPiece: item);

  void equipStudentPiece(StudentPieceCosmetic item) =>
      state = state.copyWith(studentPiece: item);

  void equipThrone(ThroneCosmetic item) =>
      state = state.copyWith(throne: item);

  void equipBoard(BoardCosmetic item) =>
      state = state.copyWith(board: item);

  void equipScenery(SceneryCosmetic item) =>
      state = state.copyWith(scenery: item);

  void equipCardBack(CardBackCosmetic item) =>
      state = state.copyWith(cardBack: item);

  void equipMoveEffect(MoveEffectCosmetic item) =>
      state = state.copyWith(moveEffect: item);

  void equipUiSounds(UiSoundsCosmetic item) =>
      state = state.copyWith(uiSounds: item);
}
