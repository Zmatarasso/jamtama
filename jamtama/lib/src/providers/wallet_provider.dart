import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Reward constants
// ---------------------------------------------------------------------------

const int dailyLoginBonus = 50;
const int matchWinReward = 25;
const int matchLossReward = 15;

// ---------------------------------------------------------------------------
// Wallet
// ---------------------------------------------------------------------------

/// Simple in-memory wallet. Persists for the session only — wire to
/// local storage or a backend when accounts are added.
class WalletNotifier extends Notifier<int> {
  @override
  int build() => 500; // starter coins

  bool canAfford(int price) => state >= price;

  /// Returns true if the purchase succeeded.
  bool spend(int amount) {
    if (state < amount) return false;
    state = state - amount;
    return true;
  }

  void earn(int amount) {
    state = state + amount;
  }
}

final walletProvider = NotifierProvider<WalletNotifier, int>(WalletNotifier.new);

// ---------------------------------------------------------------------------
// Daily login bonus
// ---------------------------------------------------------------------------

/// Tracks the last day the login bonus was claimed.
/// Returns `true` once per calendar day, then `false` until the next day.
class DailyLoginNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  /// Attempt to claim. Returns true if this is the first claim today.
  bool claim() {
    final now = DateTime.now();
    final last = state;
    if (last != null &&
        last.year == now.year &&
        last.month == now.month &&
        last.day == now.day) {
      return false; // already claimed today
    }
    state = now;
    ref.read(walletProvider.notifier).earn(dailyLoginBonus);
    return true;
  }
}

final dailyLoginProvider =
    NotifierProvider<DailyLoginNotifier, DateTime?>(DailyLoginNotifier.new);
