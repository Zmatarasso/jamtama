import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_state.dart';
import '../providers/match_provider.dart';

const _bg = Color(0xFF1A0F08);
const _surface = Color(0xFF2B1810);
const _gold = Color(0xFFFFD700);
const _textSecondary = Color(0xFFAA9980);

class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  static const _searchSeconds = 15;
  int _secondsLeft = _searchSeconds;
  Timer? _ticker;
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSearch());
  }

  Future<void> _startSearch() async {
    await ref.read(matchProvider.notifier).startNetworkMatch();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _secondsLeft = (_secondsLeft - 1).clamp(0, _searchSeconds);
      });
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pop automatically once match state moves out of menu (AI fallback fires).
    ref.listen<MatchState>(matchProvider, (prev, next) {
      if (!mounted || _hasPopped) return;
      if (next.phase != MatchPhase.menu && next.phase != MatchPhase.matchOver) {
        _hasPopped = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: Colors.white,
        title: const Text(
          'FINDING OPPONENT',
          style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(color: _gold, strokeWidth: 2),
            ),
            const SizedBox(height: 32),
            const Text(
              'Searching for opponent…',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _secondsLeft > 0
                  ? '$_secondsLeft seconds left'
                  : 'Falling back to AI…',
              style: const TextStyle(color: _textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 48),
            OutlinedButton(
              onPressed: () {
                ref.read(matchProvider.notifier).cancelMatchmaking();
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _gold,
                side: const BorderSide(color: _gold),
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
