import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_user_data_repository.dart';
import '../data/user_data_repository_provider.dart';

/// Live Firebase user state.
///
/// Uses `userChanges()` rather than `authStateChanges()` so the stream
/// fires on credential linking (anonymous → email) and profile updates
/// (updateDisplayName), not only sign-in / sign-out. Without this, the
/// UI will not refresh after [FirebaseUserDataRepository.linkEmail].
final authProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.userChanges(),
);

/// Convenience — true if the current user is anonymous (or not signed in).
final isAnonymousProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  return auth.when(
    data: (user) => user?.isAnonymous ?? true,
    loading: () => true,
    error: (_, __) => true,
  );
});

/// The signed-in email, or null for anonymous users.
final userEmailProvider = Provider<String?>((ref) {
  final auth = ref.watch(authProvider);
  return auth.whenOrNull(data: (user) => user?.email);
});

/// Convenience access to auth methods. Returns null if the repo isn't a
/// [FirebaseUserDataRepository] (e.g. in tests).
FirebaseUserDataRepository? firebaseRepo(WidgetRef ref) {
  final repo = ref.read(userDataRepositoryProvider);
  return repo is FirebaseUserDataRepository ? repo : null;
}
