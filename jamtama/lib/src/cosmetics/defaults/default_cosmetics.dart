import 'package:flutter/material.dart';

import '../models/board_cosmetic.dart';
import '../models/card_back_cosmetic.dart';
import '../models/cosmetic_loadout.dart';
import '../models/master_piece_cosmetic.dart';
import '../models/move_effect_cosmetic.dart';
import '../models/scenery_cosmetic.dart';
import '../models/student_piece_cosmetic.dart';
import '../models/throne_cosmetic.dart';
import '../models/ui_sounds_cosmetic.dart';

// ---------------------------------------------------------------------------
// Default (built-in) cosmetic instances.
// These match the hardcoded constants previously in game_screen.dart, so
// the visual result is identical until custom cosmetics are equipped.
// ---------------------------------------------------------------------------

const defaultMasterPiece = MasterPieceCosmetic(
  id: 'master_default',
  name: 'Classic Master',
);

const defaultStudentPiece = StudentPieceCosmetic(
  id: 'student_default',
  name: 'Classic Student',
);

const defaultThrone = ThroneCosmetic(
  id: 'throne_default',
  name: 'Classic Throne',
  fallbackColor: Color(0xFFFFD700),
);

const defaultBoard = BoardCosmetic(
  id: 'board_default',
  name: 'Classic Wood',
  lightTileColor: Color(0xFFDEB887),
  darkTileColor: Color(0xFFA0522D),
  templeHighlightColor: Color(0xFFFFD700),
  backgroundColor: Color(0xFF2B1810),
  validMoveColor: Color(0xFF4CAF50),
  hoverColor: Color(0xFF8BC34A),
);

const defaultScenery = SceneryCosmetic(
  id: 'scenery_default',
  name: 'Classic Dojo',
  backgroundColor: Color(0xFF1A0F08),
);

const defaultCardBack = CardBackCosmetic(
  id: 'card_back_default',
  name: 'Classic',
  fallbackColor: Color(0xFF3A3028),
  fallbackPatternColor: Color(0xFF5A4535),
);

const defaultMoveEffect = MoveEffectCosmetic(
  id: 'move_default',
  name: 'Slide',
  type: MoveEffectType.slide,
  // Sound placeholders — set asset paths here when audio files are ready:
  // moveSoundAsset: 'audio/move_slide.ogg',
  // captureSoundAsset: 'audio/capture_default.ogg',
);

/// Default UI sounds — all null until real audio files are added.
/// Drop files in assets/audio/ and uncomment the paths below.
const defaultUiSounds = UiSoundsCosmetic(
  id: 'ui_sounds_default',
  name: 'Classic',
  // cardSelectSound: 'audio/card_select.ogg',
  // pieceSelectSound: 'audio/piece_select.ogg',
  // cardDraftSound: 'audio/card_draft.ogg',
  // roundWinSound: 'audio/round_win.ogg',
  // matchWinSound: 'audio/match_win.ogg',
);

const defaultLoadout = CosmeticLoadout(
  masterPiece: defaultMasterPiece,
  studentPiece: defaultStudentPiece,
  throne: defaultThrone,
  board: defaultBoard,
  scenery: defaultScenery,
  cardBack: defaultCardBack,
  moveEffect: defaultMoveEffect,
  uiSounds: defaultUiSounds,
);
