import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_data_repository.dart';

/// Provides the active [UserDataRepository].
///
/// main() overrides this with the concrete implementation before runApp:
///
/// ```dart
/// runApp(ProviderScope(
///   overrides: [
///     userDataRepositoryProvider.overrideWithValue(
///       SharedPrefsUserDataRepository(prefs),
///     ),
///   ],
///   child: const JamtamaApp(),
/// ));
/// ```
///
/// When Firebase is added, swap in FirebaseUserDataRepository here.
final userDataRepositoryProvider = Provider<UserDataRepository>(
  (_) => throw UnimplementedError(
    'userDataRepositoryProvider must be overridden in main() before runApp.',
  ),
);
