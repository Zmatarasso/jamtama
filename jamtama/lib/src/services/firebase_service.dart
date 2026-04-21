import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper around the Firebase SDK singletons so services can be
/// constructed via Riverpod without reaching for globals in tests.
class FirebaseService {
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<String?> signInAnonymously() async {
    final cred = await FirebaseAuth.instance.signInAnonymously();
    return cred.user?.uid;
  }

  Future<void> saveUnlockables(String userId, List<String> cardNames) async {
    // No-op stub — real unlockable persistence lives in UserDataRepository.
  }

  Stream<Map<String, dynamic>> getMatchQueue(String userId) =>
      const Stream.empty();
}

final firebaseServiceProvider = Provider<FirebaseService>(
  (_) => FirebaseService(),
);
