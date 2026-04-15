import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/data/shared_prefs_user_data_repository.dart';
import 'src/data/user_data_repository_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load SharedPreferences once before the app starts.
  // After this point all reads via SharedPrefsUserDataRepository are
  // synchronous — no loading states needed in the UI.
  final prefs = await SharedPreferences.getInstance();
  final repo = SharedPrefsUserDataRepository(prefs);

  runApp(
    ProviderScope(
      overrides: [
        userDataRepositoryProvider.overrideWithValue(repo),
      ],
      child: const JamtamaApp(),
    ),
  );
}
