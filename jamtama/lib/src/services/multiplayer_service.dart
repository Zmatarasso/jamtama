import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import 'firebase_service.dart';

/// Thin, testable wrapper for Firestore matchmaking.
/// Only queue + active match document ops. No game logic here.
class MultiplayerService {
  final FirebaseFirestore _firestore;
  final String currentUserId;

  MultiplayerService(this._firestore, this.currentUserId);

  CollectionReference get _queueRef => _firestore.collection('matchmaking_queue');

  /// Enqueue player. Returns queue doc ID for later removal.
  Future<String> enqueue({
    required Map<String, dynamic> cosmeticLoadout,
  }) async {
    final docRef = await _queueRef.add({
      'userId': currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'cosmetics': cosmeticLoadout,
      'status': 'searching',
    });
    return docRef.id;
  }

  /// Remove from queue (cancel or timeout).
  Future<void> dequeue(String queueDocId) async {
    await _queueRef.doc(queueDocId).delete();
  }

  // For v1: simple 15s client timeout + fallback. 
  // Future extension: listen for real pairing and create active_matches doc.
}

final multiplayerServiceProvider = Provider<MultiplayerService>((ref) {
  // Rebuild on auth change so currentUserId reflects the active session.
  ref.watch(authProvider);
  final firebase = ref.read(firebaseServiceProvider);
  return MultiplayerService(firebase.firestore, firebase.currentUserId ?? '');
});