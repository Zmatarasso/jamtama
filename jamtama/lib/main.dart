import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamtama/src/app.dart';
import 'package:jamtama/src/data/user_data_repository_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repoOverride = await buildUserDataRepositoryOverride();
  runApp(
    ProviderScope(
      overrides: [repoOverride],
      child: const JamtamaApp(),
    ),
  );
}
