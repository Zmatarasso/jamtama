# Default Sound Pack

Drop your `.ogg` (recommended), `.mp3`, or `.wav` files here.
Filenames must match exactly:

| File | Event |
|---|---|
| `card_select.ogg`  | Player taps a card to select it |
| `piece_select.ogg` | Player taps or starts dragging a piece |
| `card_draft.ogg`   | Card revealed during draft phase |
| `move.ogg`         | Piece slides to an empty square |
| `capture.ogg`      | Piece lands on an opponent's piece |
| `round_win.ogg`    | Short sting — round over |
| `match_win.ogg`    | Full fanfare — match over |

After adding a file, uncomment its path in
`lib/src/cosmetics/data/sound_packs.dart` → `defaultSoundPack`.

## Adding a new sound pack

1. Create `assets/audio/packs/<your_pack>/` with the same filenames above.
2. Declare it in `pubspec.yaml` under `flutter: assets:`.
3. Add a new `SoundPack` const in `sound_packs.dart` (copy `defaultSoundPack`,
   change `id`, `name`, and paths to `audio/packs/<your_pack>/...`).
4. Append it to `allSoundPacks`.
5. The pack is now available in the cosmetics collection automatically.
