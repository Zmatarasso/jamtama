import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'shared_prefs_user_data_repository.dart';
import 'user_data_repository.dart';

/// [UserDataRepository] that uses Firebase Auth + Firestore for cloud storage
/// while keeping a [SharedPrefsUserDataRepository] as a local, synchronous
/// cache.
///
/// Strategy:
///   - All load* calls return from the local cache (instant, no futures).
///   - All save* calls write locally first, then push to Firestore in the
///     background (fire-and-forget — the UI never waits).
///   - On sign-in (anonymous or email), [pullFromCloud] is called to merge
///     any cloud data into the local cache so the device is up to date.
///
/// Anonymous → email upgrade:
///   Call [linkEmail] with an email + password. Firebase links the credential
///   to the existing anonymous UID, preserving all cloud data.
class FirebaseUserDataRepository implements UserDataRepository {
  FirebaseUserDataRepository({required this.local}) {
    _auth = FirebaseAuth.instance;
    _db = FirebaseFirestore.instance;
    _initAuth();
  }

  final SharedPrefsUserDataRepository local;
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _db;

  // ── Auth ───────────────────────────────────────────────────────────────────

  void _initAuth() {
    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        // No user — sign in anonymously.
        await _auth.signInAnonymously();
      } else {
        // Signed in — pull cloud data into local cache.
        await pullFromCloud();
      }
    });
  }

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('data').doc('gameData');
  }

  /// Pull the cloud copy of game data and merge it into local storage.
  /// Cloud wins on conflict (cross-device sync).
  Future<void> pullFromCloud() async {
    final doc = _doc;
    if (doc == null) return;
    try {
      final snap = await doc.get();
      if (!snap.exists) return;
      final data = snap.data()!;

      // Loadout
      final loadout = data['loadoutIds'];
      if (loadout is Map) {
        await local.saveLoadoutIds(Map<String, String>.from(loadout));
      }

      // Selected deck
      final selectedDeck = data['selectedDeckId'] as String?;
      await local.saveSelectedDeckId(selectedDeck);

      // Decks
      final decksList = data['decks'];
      if (decksList is List) {
        final decks = decksList
            .whereType<Map<String, dynamic>>()
            .map(PersistedDeck.fromJson)
            .toList();
        await local.saveDecks(decks);
      }

      // Tutorial
      final tutorialDone = data['tutorialDone'] as bool?;
      if (tutorialDone != null) {
        await local.saveTutorialDone(tutorialDone);
      }

      // Display name
      final displayName = data['displayName'] as String?;
      if (displayName != null) {
        await local.saveDisplayName(displayName);
      }
    } catch (_) {
      // Offline or error — silently use local cache.
    }
  }

  /// Push the full local state to Firestore.
  Future<void> _pushToCloud(Map<String, dynamic> fields) async {
    final doc = _doc;
    if (doc == null) return;
    try {
      await doc.set(fields, SetOptions(merge: true));
    } catch (_) {
      // Offline — local write already succeeded; Firestore will sync when back online.
    }
  }

  // ── Email upgrade ──────────────────────────────────────────────────────────

  /// Link an email + password to the current anonymous account.
  /// Returns null on success, or an error message string on failure.
  Future<String?> linkEmail(String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await _auth.currentUser?.linkWithCredential(credential);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred';
    }
  }

  /// Sign in with email + password (for returning users on a new device).
  /// Returns null on success, or an error message string on failure.
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred';
    }
  }

  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;
  String? get email => _auth.currentUser?.email;

  Future<void> signOut() => _auth.signOut();

  // ── UserDataRepository ─────────────────────────────────────────────────────

  @override
  Map<String, String>? loadLoadoutIds() => local.loadLoadoutIds();

  @override
  Future<void> saveLoadoutIds(Map<String, String> ids) async {
    await local.saveLoadoutIds(ids);
    _pushToCloud({'loadoutIds': ids});
  }

  @override
  List<PersistedDeck>? loadDecks() => local.loadDecks();

  @override
  Future<void> saveDecks(List<PersistedDeck> decks) async {
    await local.saveDecks(decks);
    _pushToCloud({
      'decks': decks.map((d) => d.toJson()).toList(),
    });
  }

  @override
  String? loadSelectedDeckId() => local.loadSelectedDeckId();

  @override
  Future<void> saveSelectedDeckId(String? id) async {
    await local.saveSelectedDeckId(id);
    _pushToCloud({'selectedDeckId': id});
  }

  @override
  bool loadTutorialDone() => local.loadTutorialDone();

  @override
  Future<void> saveTutorialDone(bool done) async {
    await local.saveTutorialDone(done);
    _pushToCloud({'tutorialDone': done});
  }

  @override
  String? loadDisplayName() => local.loadDisplayName();

  @override
  Future<void> saveDisplayName(String name) async {
    await local.saveDisplayName(name);
    // Also update the Firebase Auth profile so it shows in the console.
    await _auth.currentUser?.updateDisplayName(name);
    _pushToCloud({'displayName': name});
  }
}
