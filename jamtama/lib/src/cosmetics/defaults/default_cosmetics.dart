import 'package:flutter/material.dart';

import '../models/board_cosmetic.dart' show BoardCosmetic, BoardTileStyle;
import '../models/card_back_cosmetic.dart';
import '../models/cosmetic_loadout.dart';
import '../models/master_piece_cosmetic.dart';
import '../models/piece_cosmetic.dart' show PieceStyle;
import '../models/move_effect_cosmetic.dart';
import '../models/scenery_cosmetic.dart';
import '../models/student_piece_cosmetic.dart';
import '../models/throne_cosmetic.dart' show ThroneCosmetic, ThroneStyle;
import '../data/sound_packs.dart';

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

const woodMasterPiece = MasterPieceCosmetic(
  id: 'master_wood',
  name: 'Wood Master',
  style: PieceStyle.wood,
);

const woodStudentPiece = StudentPieceCosmetic(
  id: 'student_wood',
  name: 'Wood Student',
  style: PieceStyle.wood,
);

const stoneMasterPiece = MasterPieceCosmetic(
  id: 'master_stone',
  name: 'Stone Master',
  style: PieceStyle.stone,
);

const stoneStudentPiece = StudentPieceCosmetic(
  id: 'student_stone',
  name: 'Stone Student',
  style: PieceStyle.stone,
);

const defaultThrone = ThroneCosmetic(
  id: 'throne_default',
  name: 'Classic Throne',
  fallbackColor: Color(0xFFFFD700),
);

const beatingHeartThrone = ThroneCosmetic(
  id: 'throne_beating_heart',
  name: 'Beating Heart',
  style: ThroneStyle.beatingHeart,
  fallbackColor: Color(0xFFDC143C),
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

const woodGrainBoard = BoardCosmetic(
  id: 'board_wood_grain',
  name: 'Wood Grain',
  lightTileColor: Color(0xFFDEB887),
  darkTileColor: Color(0xFF8B5E3C),
  templeHighlightColor: Color(0xFFFFD700),
  backgroundColor: Color(0xFF2A1005),
  validMoveColor: Color(0xFF6DBF67),
  hoverColor: Color(0xFFA5C46A),
  tileStyle: BoardTileStyle.woodGrain,
);

const stoneBoard = BoardCosmetic(
  id: 'board_stone',
  name: 'Stone',
  lightTileColor: Color(0xFFA8A098),
  darkTileColor: Color(0xFF6A6058),
  templeHighlightColor: Color(0xFFFFD700),
  backgroundColor: Color(0xFF1A1A1E),
  validMoveColor: Color(0xFF64B5F6),
  hoverColor: Color(0xFF78C8FF),
  tileStyle: BoardTileStyle.stone,
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
);

const glitterMoveEffect = MoveEffectCosmetic(
  id: 'move_glitter',
  name: 'Glitter',
  type: MoveEffectType.glitter,
);

const defaultLoadout = CosmeticLoadout(
  masterPiece: defaultMasterPiece,
  studentPiece: defaultStudentPiece,
  throne: defaultThrone,
  board: defaultBoard,
  scenery: defaultScenery,
  cardBack: defaultCardBack,
  moveEffect: defaultMoveEffect,
  soundPack: defaultSoundPack,
);
