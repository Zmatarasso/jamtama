# Royal Rumble — App Store Readiness Checklist

Work through these in order. Items marked 🔴 block the game from being completable.
Items marked 🟡 are required for store submission. 🟠 are expected by players.
🟢 are post-launch / v1.1.

---

## 🔴 Blocking — Game isn't completable without these

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
- [ ] Create app icon (all required sizes — iOS needs many variants; use a tool like AppIconMaker)
- [ ] Create splash screen
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
- [x] How-to-play / tutorial — 18-step overlay, fires automatically on first "Find a Match"; bot plays opponent; resets from Options
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

- [ ] Online multiplayer (Firebase Realtime or Firestore turn-based)
- [ ] AI opponent (single-player mode)
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
