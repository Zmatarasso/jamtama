import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import 'display_name_validator.dart';
import 'profile.dart';
import 'profile_repository.dart';

/// Overridden in main() with the initialized repository.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (_) => throw UnimplementedError('override profileRepositoryProvider in main'),
);

/// Rate-limit: one display-name change per 24 hours for signed-in users.
const displayNameChangeCooldown = Duration(hours: 24);

final profileProvider =
    NotifierProvider<ProfileNotifier, Profile>(ProfileNotifier.new);

class ProfileNotifier extends Notifier<Profile> {
  @override
  Profile build() {
    final repo = ref.read(profileRepositoryProvider);

    // Reflect external changes (cloud sync, sign-in pull) into state.
    final sub = repo.changes.listen((p) => state = p);
    ref.onDispose(sub.cancel);

    // On auth state change — pull the cloud profile for the new uid.
    ref.listen<AsyncValue<User?>>(
      authProvider,
      (_, next) {
        final uid = next.asData?.value?.uid;
        if (uid != null && uid.isNotEmpty) {
          repo.syncFromCloud(uid);
        }
      },
      fireImmediately: true,
    );

    return repo.loadLocal() ?? Profile.empty;
  }

  /// True if the user is allowed to change their display name right now.
  /// Anonymous users have no cooldown; the clock starts at sign-up.
  bool get canChangeDisplayName {
    final last = state.lastDisplayNameChangeAt;
    if (last == null) return true;
    final user = ref.read(authProvider).asData?.value;
    if (user == null || user.isAnonymous) return true;
    return DateTime.now().difference(last) >= displayNameChangeCooldown;
  }

  /// Remaining cooldown, or null if a change is allowed now.
  Duration? get timeUntilNextChange {
    if (canChangeDisplayName) return null;
    final last = state.lastDisplayNameChangeAt!;
    final remaining = displayNameChangeCooldown -
        DateTime.now().difference(last);
    return remaining.isNegative ? null : remaining;
  }

  /// Change the display name. Returns null on success, or an error string.
  Future<String?> updateDisplayName(String raw) async {
    final v = validateDisplayName(raw);
    if (!v.ok) return v.error;
    if (!canChangeDisplayName) {
      return 'You can only change your display name once per day.';
    }
    final uid = _currentUid();
    if (uid == null) return 'Not signed in.';
    final next = state.copyWith(
      uid: uid,
      displayName: raw.trim(),
      lastDisplayNameChangeAt: DateTime.now(),
      createdAt: state.createdAt ?? DateTime.now(),
    );
    await ref.read(profileRepositoryProvider).save(next);
    await FirebaseAuth.instance.currentUser?.updateDisplayName(raw.trim());
    state = next;
    return null;
  }

  Future<void> equipAvatar(String avatarCosmeticId) async {
    final uid = _currentUid();
    if (uid == null) return;
    final next = state.copyWith(uid: uid, avatarCosmeticId: avatarCosmeticId);
    await ref.read(profileRepositoryProvider).save(next);
    state = next;
  }

  /// Seed the profile at sign-up — sets the chosen name and starts the
  /// rate-limit clock. Called after `linkEmail` succeeds.
  ///
  /// Returns null on success, or an error string.
  Future<String?> initializeOnSignUp(String displayName) async {
    final v = validateDisplayName(displayName);
    if (!v.ok) return v.error;
    final uid = _currentUid();
    if (uid == null) return 'Not signed in.';
    final now = DateTime.now();
    final next = Profile(
      uid: uid,
      displayName: displayName.trim(),
      avatarCosmeticId: state.avatarCosmeticId,
      lastDisplayNameChangeAt: now,
      createdAt: state.createdAt ?? now,
    );
    await ref.read(profileRepositoryProvider).save(next);
    await FirebaseAuth.instance.currentUser?.updateDisplayName(displayName.trim());
    state = next;
    return null;
  }

  /// Reset local state when the user signs out. Cloud profile is untouched.
  Future<void> clearLocal() async {
    await ref.read(profileRepositoryProvider).clearLocal();
    state = Profile.empty;
  }

  String? _currentUid() {
    final uid = ref.read(authProvider).asData?.value?.uid;
    if (uid != null && uid.isNotEmpty) return uid;
    return state.uid.isEmpty ? null : state.uid;
  }
}
