import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile.dart';

/// Read/write the user's [Profile] with a local SharedPreferences cache
/// and Firestore (`profiles/{uid}`) as the cloud source of truth.
///
/// Reads are synchronous from the local cache. Writes update local first
/// then push to Firestore fire-and-forget.
class ProfileRepository {
  ProfileRepository({required SharedPreferences prefs}) : _prefs = prefs {
    _db = FirebaseFirestore.instance;
  }

  static const _localKey = 'profile_v1';

  final SharedPreferences _prefs;
  late final FirebaseFirestore _db;

  // Fires whenever the locally-cached profile changes (set from anywhere).
  final _changes = StreamController<Profile>.broadcast();
  Stream<Profile> get changes => _changes.stream;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('profiles').doc(uid);

  // ── Local cache ──────────────────────────────────────────────────────────

  Profile? loadLocal() {
    final raw = _prefs.getString(_localKey);
    if (raw == null) return null;
    try {
      return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveLocal(Profile p) async {
    await _prefs.setString(_localKey, jsonEncode(p.toJson()));
    _changes.add(p);
  }

  Future<void> clearLocal() async {
    await _prefs.remove(_localKey);
  }

  // ── Cloud ────────────────────────────────────────────────────────────────

  /// Fetch the cloud profile for [uid]. Returns null if the doc doesn't
  /// exist yet. On error (offline etc.) returns null too.
  Future<Profile?> fetchFromCloud(String uid) async {
    try {
      final snap = await _doc(uid).get();
      if (!snap.exists) return null;
      final data = snap.data()!;
      return Profile.fromJson({...data, 'uid': uid});
    } catch (_) {
      return null;
    }
  }

  /// Merge-write the profile to Firestore. Fire-and-forget — caller does
  /// not wait for the network.
  Future<void> pushToCloud(Profile p) async {
    if (p.uid.isEmpty) return;
    try {
      await _doc(p.uid).set(p.toJson(), SetOptions(merge: true));
    } catch (_) {
      // Offline — local is already up to date; Firestore will sync later.
    }
  }

  /// Pull cloud profile into local cache and return it. If no cloud doc
  /// exists, creates one seeded from the local cache (so a fresh sign-in
  /// on a new device starts with something). Also handles one-time
  /// migration from the legacy `users/{uid}/data/gameData.displayName`.
  Future<Profile> syncFromCloud(String uid) async {
    final cloud = await fetchFromCloud(uid);
    if (cloud != null) {
      await _saveLocal(cloud);
      return cloud;
    }

    // No cloud profile — check for legacy displayName in gameData and migrate.
    String? legacyName;
    try {
      final legacySnap = await _db
          .collection('users')
          .doc(uid)
          .collection('data')
          .doc('gameData')
          .get();
      legacyName = legacySnap.data()?['displayName'] as String?;
    } catch (_) {
      // ignore
    }

    final local = loadLocal();
    final seeded = Profile(
      uid: uid,
      displayName: legacyName ?? local?.displayName,
      avatarCosmeticId: local?.avatarCosmeticId,
      lastDisplayNameChangeAt: local?.lastDisplayNameChangeAt,
      createdAt: local?.createdAt ?? DateTime.now(),
    );
    await _saveLocal(seeded);
    // Fire-and-forget push so the cloud doc exists.
    pushToCloud(seeded);
    return seeded;
  }

  /// Save a new profile state: local first, then push.
  Future<void> save(Profile p) async {
    await _saveLocal(p);
    pushToCloud(p);
  }

  void dispose() {
    _changes.close();
  }
}
