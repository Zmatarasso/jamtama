import '../models/sound_pack.dart';

// ---------------------------------------------------------------------------
// Sound pack registry
// ---------------------------------------------------------------------------
//
// ADDING A NEW PACK
// -----------------
// 1. Create assets/audio/packs/<id>/ — see that folder's README.md.
// 2. Declare the new directory in pubspec.yaml under flutter: assets:.
// 3. Define a new SoundPack const below (copy defaultSoundPack template).
// 4. Append it to allSoundPacks.
//
// Done. The pack is then available in the cosmetics equip screen.
// ---------------------------------------------------------------------------

/// Built-in "classic" pack.
///
/// All paths are commented-out until the matching file is dropped in
/// assets/audio/packs/default/ — silence is the safe default.
const defaultSoundPack = SoundPack(
  id: 'sound_default',
  name: 'Classic Steel',
  // ── Uncomment each line after adding the file to assets/audio/packs/default/ ──
  // cardSelect:  'audio/packs/default/card_select.ogg',
  // pieceSelect: 'audio/packs/default/piece_select.ogg',
  // cardDraft:   'audio/packs/default/card_draft.ogg',
  // move:        'audio/packs/default/move.ogg',
  // capture:     'audio/packs/default/capture.ogg',
  // roundWin:    'audio/packs/default/round_win.ogg',
  // matchWin:    'audio/packs/default/match_win.ogg',
);

// ---------------------------------------------------------------------------
// Add new packs below and append to allSoundPacks.
// Example:
//
// const steelOnSteelPack = SoundPack(
//   id: 'sound_steel',
//   name: 'Steel on Steel',
//   cardSelect:  'audio/packs/steel/card_select.ogg',
//   pieceSelect: 'audio/packs/steel/piece_select.ogg',
//   cardDraft:   'audio/packs/steel/card_draft.ogg',
//   move:        'audio/packs/steel/move.ogg',
//   capture:     'audio/packs/steel/capture.ogg',
//   roundWin:    'audio/packs/steel/round_win.ogg',
//   matchWin:    'audio/packs/steel/match_win.ogg',
// );
// ---------------------------------------------------------------------------

/// All registered sound packs — shown in the cosmetics equip screen.
const allSoundPacks = <SoundPack>[
  defaultSoundPack,
  // steelOnSteelPack,
];
