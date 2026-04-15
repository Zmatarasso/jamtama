import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_prefs_user_data_repository.dart';
import 'user_data_repository.dart';

/// Provides the [UserDataRepository] implementation.
///
/// Overridden in main() with a pre-loaded [SharedPreferences] instance
/// so reads remain synchronous throughout the app.
final userDataRepositoryProvider = Provider<UserDataRepository>(
  (ref) => throw UnimplementedError(
    'userDataRepositoryProvider must be overridden in main() '
    'after SharedPreferences.getInstance() resolves.',
  ),
);

/// Convenience helper — call in main() before runApp.
Future<dynamic> buildUserDataRepositoryOverride() async {
  final prefs = await SharedPreferences.getInstance();
  return userDataRepositoryProvider
      .overrideWithValue(SharedPrefsUserDataRepository(prefs));
}
