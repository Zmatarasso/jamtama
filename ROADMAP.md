# Royal Rumble — App Store Readiness Checklist

Work through these in order. Items marked 🔴 block the game from being completable.
Items marked 🟡 are required for store submission. 🟠 are expected by players.
🟢 are post-launch / v1.1.

---

## 🕹️ Game Flow Improvements — Pre-launch UX pass (separate session)

End-of-match flows need finishing. The game ends cleanly mechanically but dumps
the player back to the menu without ceremony. These two items close that gap.

### 1. Local match — "Play again" modal
- [ ] After a local (hot-seat) match ends, show an in-game modal with two choices:
  - **Play Again** — resets match state and returns both players to deck selection (`MatchPhase.deckSelection`, `GameMode.local`), skipping the menu entirely. Calls `startLocalMatch()` on `MatchNotifier`.
  - **Exit to Menu** — calls `returnToMenu()`.
- [ ] Modal should be visually distinct from the round-over dialog that already exists. The round-over dialog already fires from `_RootRouter`'s `ref.listen`; the match-over modal replaces it (or layers on top of it) when `isMatchOver == true`.
- [ ] Make sure the winner is clearly announced — "Red wins the match!" / "Blue wins the match!" with the right team colour before the two action buttons.
- [ ] Check that dismissing the modal programmatically (e.g. pressing Back) does not leave the match in a broken state — default back-gesture should be suppressed (`barrierDismissible: false`).

### 2. Network / AI match — Full-screen end-game summary
- [ ] After a matchmaking (or AI fallback) game ends, overlay a large summary screen that covers most of the game board.
- [ ] Must show:
  - **Win / Loss headline** — large, prominent, with distinct styling per outcome (e.g. gold "VICTORY" vs muted "DEFEAT"). If animatable, entrance from above or scale-in.
  - **Coins earned** — display the reward with a coin icon; value should pulse or count-up animate when the overlay appears. Use the values already defined (`matchWinReward` / `matchLossReward` in `wallet_provider.dart`) — but only award coins once (guard against double-award if the widget rebuilds).
  - **Opponent name** — pulled from `MatchNotifier.currentOpponent` (the `Opponent` model set during matchmaking). Shows who the player faced (even if it was an AI fallback).
  - **Confirm / Continue button** — single button (label: "Continue" or "Back to Menu") that calls `returnToMenu()` and pops back to `MenuScreen`.
- [ ] All visual layers must be designed to accept animation controllers so they can be individually orchestrated (headline slides in → coin count counts up → button fades in). Implementation can ship with animations stubbed to instant-on; animating them is a follow-up pass.
- [ ] The overlay is a separate widget (`MatchSummaryOverlay`) rendered inside the existing `Stack` in `_RootRouter` (or as a `showGeneralDialog`), keyed on `match.phase == MatchPhase.matchOver && match.gameMode != GameMode.local` so it never fires in local matches (which get the simpler modal above).

---

## 🎨 Visual Polish — Pre-launch art pass (separate session)

Mechanics are effectively done. These items are the final art/visual pass before
store submission. Each bullet should become its own focused session; art assets
may be commissioned separately and dropped into `assets/` slots the code
already expects.

### 1. Menu screen background
- [ ] Replace the plain dark-brown background with a real illustrated asset (PNG).
  - Define a single drop-in slot (`assets/branding/menu_bg.png`) at a known resolution (e.g. 1080×2400) so an artist can deliver one file.
  - Wire `MenuScreen` to render it as a full-bleed background with the buttons floated on top.
  - Title treatment becomes an asset too (see item 7) — no more hard-coded `Text('JAMTAMA', ...)`.

### 2. Piece art (master + students)
- [ ] Replace the circular placeholders with actual little-soldier / king figures.
  - Correct sizing: currently pieces fill the whole square; want them to sit **inside** the square with a small margin so the board tile colour still reads around the piece.
  - Master and student must be visually distinct at a glance (crown vs. helmet, taller silhouette, etc.).
  - Deliver as PNG per `PieceCosmetic` / `MasterPieceCosmetic` slot so cosmetics swap cleanly.
  - Consider team tinting: one set of grayscale PNGs, tinted red / blue at render time, OR two pre-coloured variants per piece.

### 3. Collection screen — equip preview + layered cosmetic display
- [ ] The screen currently runs equips through the sidebar with no preview. Two fixes:
  - **Tapping a sidebar option opens a confirmation modal** showing the cosmetic preview before it's equipped. Modal has "Equip" and "Cancel".
  - **Main display becomes a layered composition**, not a flat image. Background → board → throne → pieces → profile picture are separate PNG layers stacked via `Stack` so swapping a single slot updates only that layer.
  - Each visible cosmetic in the composition is itself the clickable button for its slot (tap the board to change the board, tap a piece to change the piece). Sidebar becomes a secondary nav rather than the primary interaction.
  - Asset layout should mirror what the cosmetic model already exposes (board, throne, masterPiece, studentPiece, scenery, profilePicture, cardBack).

### 4. Shop screen
- [x] Layout is fine as-is.
- [ ] Re-theme once the app-wide colour pass lands (see Colour scheme below). No structural changes needed here.

### 5. Card art — weapon imagery + per-card effects
- [ ] Each card needs a weapon illustration on the face (war hammer, katana, etc.) — currently just move-pattern grids.
- [ ] Extend `CardDefinition` so individual cards can carry their own effect/cosmetic bundle:
  - e.g. `warHammer.moveEffect = PieceMoveEffect.fireTrail`, `katana.moveEffect = PieceMoveEffect.lightningTrail`.
  - Right now move effects come from the player's equipped `MoveEffectCosmetic` — that becomes the *default*, and the card can override. Default resolution: card override > equipped cosmetic > hardcoded fallback.
  - Similarly allow per-card sound / impact variants so each weapon feels unique.

### 6. Card name overflow
- [ ] Long card names trigger Flutter overflow warnings in the card draft screen, in-hand strip, and possibly the community card slot.
  - Audit every `Text` widget that renders `card.name`.
  - Fix options: `AutoSizeText` (add package if acceptable), `FittedBox`, or manual `maxLines: 1` + `overflow: TextOverflow.ellipsis` + smaller font on long names.
  - Whichever approach is picked, apply it consistently in one utility widget (`CardNameLabel`) so future cards don't reintroduce the bug.

### 7. Remove "Jamtama" branding
- [ ] Menu screen still shows hardcoded text `'JAMTAMA'` — replace with an art asset title (`assets/branding/title.png`) commissioned alongside the menu background.
- [ ] Audit the entire codebase and user-facing strings for any remaining "Jamtama" references. Internal file paths (`lib/src/`, `jamtama/` repo folder, etc.) can stay — only user-visible strings need to change.
  - Search: `grep -ri "jamtama" lib/ assets/` — expected hits are `JamtamaApp` class name (internal, OK) and any stray UI strings (NOT ok).
  - Check: menu title text, splash screen text, `AccountGate` welcome copy (currently reads "WELCOME TO JAMTAMA"), options screen headers, any dialog titles.

### 8. App icon — clean "RR" mark
- [ ] Current icon doesn't read well. Replace with a clean **"RR" mark**: first R in red (`#DC143C`), second R in blue (`#4169E1`) and horizontally mirrored (so the two Rs face each other — R and ꓤ).
- [ ] Check `tool/gen_branding.py` and `assets/branding/` for any better existing icons before drawing a new one.
- [ ] Re-run `flutter pub run flutter_launcher_icons` after the source PNG is in place so Android and iOS variants regenerate.

### Colour scheme (app-wide, touches all screens)
- [ ] Lock a final palette (primary / secondary / accent / background / surface / text) and audit every hard-coded `Color(0x…)` across the codebase. Current codebase has colours scattered inline — centralise into a `theme/colors.dart` constants file so the next re-theme is a one-file change.

---

## 🔴 Blocking — Game isn't completable without these

### Network matchmaking
- [ ] Network-based matchmaking (Firestore queue) — 15-second client-side timeout → fallback to AI opponent (randomized cosmetics from player unlocks + auto-generated name e.g. RuckusBot#472). `GameMode.net` fully wired; seamless transition into existing match flow using `BotPlayer` and `_autoConfirmBlue`.

### Gameplay
- [x] Verify win conditions end-to-end — throne capture AND master capture both trigger round-over dialog correctly in all cases
- [x] Draft phase (`CardDraftScreen`) — works; stale-selection bug fixed; round 3 correctly draws 2 cards when only 2 remain
- [x] Round-over → rematch / return-to-menu flow — state update made atomic; dialog fires exactly once via `ref.listen`; startNextRound returns to draft correctly
- [x] Hot-seat hand-hide between turns — treating as public-info board game; no pass-device screen needed

### Audio
- [x] Audio code complete — `SoundPack` model consolidates all 7 sounds; `AudioService` respects volume sliders; all call sites wired (card select, piece select, card draft, move, capture, round/match win); drop files in `assets/audio/packs/default/` and uncomment paths in `lib/src/cosmetics/data/sound_packs.dart`

---

## 🟡 Required for store submission

### Platform setup
- [x] Change package name → `io.royalruckus.app` in `android/app/build.gradle.kts` and iOS `project.pbxproj`
- [x] Resolve name conflict — app renamed to **Royal Ruckus**
- [x] Create app icon — placeholder "R vs R" wrestling-ring art; `tool/gen_branding.py` generates the source PNGs, `flutter_launcher_icons` generates platform variants
- [x] Create splash screen — generated via `flutter_native_splash` from `assets/branding/splash.png`
- [ ] iOS build setup — requires a Mac + Xcode; provisioning profile, App ID, signing certificates
- [ ] Android keystore + signing config in `build.gradle`

### App Store content
- [ ] Privacy policy — publish a URL (required by both stores even for fully offline apps)
- [ ] App Store screenshots — minimum 3 per device size class
- [ ] Short description (30 chars) + long description
- [ ] Age / content rating questionnaire (both stores)
- [ ] Support email or URL

### Code hygiene
- [x] Flag-gate the debug layout panel so it never appears in release builds (`kDebugMode` or a compile-time flag)
- [x] Bump `version` in `pubspec.yaml` to a real version number (0.1.0+1)
- [x] Fix all tests — updated card names from animal→weapon theme; fixed `completeDraft` helper; 47/47 passing
- [ ] Run `flutter build` for iOS and Android — fix any build errors

---

## 🟠 Expected by players (missing = bad reviews)

### UX / Onboarding
- [x] How-to-play / tutorial — step overlay, fires automatically on first "Find a Match"; bot plays opponent across all rounds (not just round 1); tutorial completion saves correctly; resets from Options
- [ ] Tutorial modal precision — currently all in-game modals are anchored to the play-bar strip as a placeholder; replace with contextual annotations (arrow tooltips, highlights) positioned next to the specific piece/card/square being described
- [x] First-time user flow — tutorial handles first-time context; daily login bonus shown after tutorial completes
- [x] Display name entry — saves via UserDataRepository; shown in Options screen

### Polish
- [ ] Card art — move-pattern grids are functional but not shippable; even simple illustrated weapon backgrounds per card would help
- [ ] Menu screen visual polish — currently very plain
- [x] Wire volume sliders in Options to `AudioService` master/sfx/music levels
- [x] Verify piece move animation looks good with current cosmetics (the "slide" effect)
- [x] Glitter drag effect — orbit particles now visible during drag (z-order and orbit radius fixed)

### Account / identity
- [x] Decided: anonymous auth on first launch → optional email upgrade; Firebase Auth + Firestore wired up
- [x] Email upgrade UI — "Create Account" / "Sign In" buttons in Options open an auth dialog that calls `FirebaseUserDataRepository.linkEmail()` / `signInWithEmail()`
- [ ] Google Sign-In — add as third auth option alongside email/password

### Cosmetics / Persistence
- [x] Cosmetic loadout persists between restarts — SharedPreferences (local) + Firestore (cloud) via UserDataRepository; verified working on web

---

## 🟢 Post-launch / v1.1

- [x] Online multiplayer infrastructure — `MultiplayerService`, `MatchmakingScreen`, `Opponent` model, `startNetworkMatch` / `cancelMatchmaking` / `_fallbackToAi` all implemented; see 🔴 section above for wire-up verification checklist
- [x] AI opponent — `BotPlayer` widget drives Blue automatically in `GameMode.ai`; active across all rounds (not just tutorial); `GameMode` split into `local` / `ai` / `net` for clean future net-play support
- [x] Card unlock / shop system — random card purchase with 3D spin reveal; cosmetic purchases with sold stamp; coin economy (wallet, daily login bonus, win/loss rewards)
- [ ] Additional cosmetics (more boards, pieces, thrones, effects)
- [ ] Leaderboard / match history
- [ ] Landscape support
- [ ] Crash reporting (Firebase Crashlytics or Sentry)
- [ ] Analytics (Firebase Analytics or PostHog)
- [ ] iPad / tablet layout pass

---

## Implementation notes

**Debug panel gate (quick win):**
```dart
// In _GameScreenState.build, wrap the _DebugPanel:
if (kDebugMode) _DebugPanel(...),
```
Add `import 'package:flutter/foundation.dart';`

**Package name change files:**
- `android/app/build.gradle` → `applicationId`
- `android/app/src/main/AndroidManifest.xml` → `package`
- `ios/Runner/Info.plist` → `CFBundleIdentifier`
- `ios/Runner.xcodeproj/project.pbxproj` → `PRODUCT_BUNDLE_IDENTIFIER`

**win condition test:**
Check `game_logic.dart` — look for throne capture (piece lands on opponent's throne row/col)
and master capture (opponent's master piece is removed from board).
