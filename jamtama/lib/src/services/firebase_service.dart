import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/card.dart';  // Extend for cosmetics.

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> signInAnonymously() async => (await _auth.signInAnonymously()).user;

  Future<void> saveUnlockables(String userId, List<MoveCard> cards) async {
    await _db.collection('users').doc(userId).set({'cards': cards.map((c) => c.name).toList()});
  }

  // Mock matchmaking: Add to queue, listen for match.
  Stream<DocumentSnapshot> getMatchQueue(String userId) {
    return _db.collection('queues').doc(userId).snapshots();
  }
}