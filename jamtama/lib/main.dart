import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'src/app.dart';
import 'src/data/firebase_user_data_repository.dart';
import 'src/data/shared_prefs_user_data_repository.dart';
import 'src/data/user_data_repository_provider.dart';
import 'src/profile/profile_provider.dart';
import 'src/profile/profile_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Local cache — always available synchronously.
  final prefs = await SharedPreferences.getInstance();
  final localRepo = SharedPrefsUserDataRepository(prefs);

  // Firebase-backed repository wraps the local cache.
  final repo = FirebaseUserDataRepository(local: localRepo);

  // Public profile (display name, avatar) — separate collection from game data.
  final profileRepo = ProfileRepository(prefs: prefs);

  runApp(
    ProviderScope(
      overrides: [
        userDataRepositoryProvider.overrideWithValue(repo),
        profileRepositoryProvider.overrideWithValue(profileRepo),
      ],
      child: const JamtamaApp(),
    ),
  );
}
