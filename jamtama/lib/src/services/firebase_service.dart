// Firebase integration — stubbed until FlutterFire is configured.
// Re-enable by restoring firebase_core/firebase_auth/cloud_firestore in pubspec.yaml
// and running: flutterfire configure

class FirebaseService {
  Future<String?> signInAnonymously() async => null; // stub

  Future<void> saveUnlockables(String userId, List<String> cardNames) async {}

  Stream<Map<String, dynamic>> getMatchQueue(String userId) => const Stream.empty();
}
