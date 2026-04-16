import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_user_data_repository.dart';
import '../data/user_data_repository_provider.dart';

/// Live Firebase auth state. Rebuilds widgets whenever sign-in status changes.
final authProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

/// The display name the player has set, or null.
/// Backed by [UserDataRepository] so it works offline too.
class DisplayNameNotifier extends Notifier<String?> {
  @override
  String? build() =>
      ref.read(userDataRepositoryProvider).loadDisplayName();

  Future<void> save(String name) async {
    await ref.read(userDataRepositoryProvider).saveDisplayName(name);
    state = name;
  }
}

final displayNameProvider =
    NotifierProvider<DisplayNameNotifier, String?>(DisplayNameNotifier.new);

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
