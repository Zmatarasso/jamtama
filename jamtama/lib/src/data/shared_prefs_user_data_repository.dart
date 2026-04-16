import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'user_data_repository.dart';

/// [UserDataRepository] backed by [SharedPreferences].
///
/// Reads are synchronous because [SharedPreferences] caches everything in
/// memory after the initial async [SharedPreferences.getInstance] call.
/// That call is made once in main() before runApp, so by the time any
/// widget reads state the data is already available.
///
/// To switch to Firebase: implement [UserDataRepository] with a Firestore
/// class, do the same pre-load dance in main(), and update the provider
/// override. Nothing else changes.
class SharedPrefsUserDataRepository implements UserDataRepository {
  SharedPrefsUserDataRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _loadoutKey      = 'cosmetic_loadout_v1';
  static const _decksKey        = 'saved_decks_v1';
  static const _selectedDeckKey = 'selected_deck_id_v1';
  static const _tutorialDoneKey = 'tutorial_done_v1';
  static const _displayNameKey        = 'display_name_v1';
  static const _unlockedCardsKey      = 'unlocked_cards_v1';
  static const _unlockedCosmeticsKey  = 'unlocked_cosmetics_v1';

  // ── Cosmetic loadout ───────────────────────────────────────────────────────

  @override
  Map<String, String>? loadLoadoutIds() {
    final raw = _prefs.getString(_loadoutKey);
    if (raw == null) return null;
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveLoadoutIds(Map<String, String> ids) =>
      _prefs.setString(_loadoutKey, jsonEncode(ids));

  // ── Decks ──────────────────────────────────────────────────────────────────

  @override
  List<PersistedDeck>? loadDecks() {
    final raw = _prefs.getString(_decksKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => PersistedDeck.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDecks(List<PersistedDeck> decks) =>
      _prefs.setString(_decksKey, jsonEncode(decks.map((d) => d.toJson()).toList()));

  @override
  String? loadSelectedDeckId() => _prefs.getString(_selectedDeckKey);

  @override
  Future<void> saveSelectedDeckId(String? id) {
    if (id == null) return _prefs.remove(_selectedDeckKey);
    return _prefs.setString(_selectedDeckKey, id);
  }

  // ── Tutorial ───────────────────────────────────────────────────────────────

  @override
  bool loadTutorialDone() => _prefs.getBool(_tutorialDoneKey) ?? false;

  @override
  Future<void> saveTutorialDone(bool done) =>
      _prefs.setBool(_tutorialDoneKey, done);

  // ── Profile ────────────────────────────────────────────────────────────────

  @override
  String? loadDisplayName() => _prefs.getString(_displayNameKey);

  @override
  Future<void> saveDisplayName(String name) =>
      _prefs.setString(_displayNameKey, name);

  // ── Unlocks ────────────────────────────────────────────────────────────────

  @override
  Set<String>? loadUnlockedCardIds() {
    final raw = _prefs.getString(_unlockedCardsKey);
    if (raw == null) return null;
    try {
      return Set<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveUnlockedCardIds(Set<String> ids) =>
      _prefs.setString(_unlockedCardsKey, jsonEncode(ids.toList()));

  @override
  Set<String>? loadUnlockedCosmeticIds() {
    final raw = _prefs.getString(_unlockedCosmeticsKey);
    if (raw == null) return null;
    try {
      return Set<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveUnlockedCosmeticIds(Set<String> ids) =>
      _prefs.setString(_unlockedCosmeticsKey, jsonEncode(ids.toList()));
}
