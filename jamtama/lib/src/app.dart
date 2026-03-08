import 'package:flutter/material.dart';
import 'package:jamtama/src/screens/game_screen.dart';  // Full package path for consistency.

class OnitamaApp extends StatelessWidget {
  const OnitamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jamtama',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}