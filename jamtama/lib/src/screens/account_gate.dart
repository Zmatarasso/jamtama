import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../profile/display_name_validator.dart';
import '../profile/profile_provider.dart';
import '../providers/auth_provider.dart';

const _bg = Color(0xFF1A0F08);
const _surface = Color(0xFF2B1810);
const _surfaceLight = Color(0xFF3A2010);
const _gold = Color(0xFFD4A843);
const _goldDim = Color(0xFF8B6914);
const _textPrimary = Color(0xFFE8E0D0);
const _textSecondary = Color(0xFFAA9980);

const _accountChoiceKey = 'account_choice_made_v1';

/// True when the user has explicitly chosen sign-in / sign-up / guest on first
/// boot. Until this flips true, [AccountGate] shows a blocking overlay.
final accountChoiceMadeProvider =
    NotifierProvider<_AccountChoiceNotifier, bool>(_AccountChoiceNotifier.new);

class _AccountChoiceNotifier extends Notifier<bool> {
  SharedPreferences? _prefs;

  @override
  bool build() {
    // Load synchronously if possible. The first call may race main(), so we
    // optimistically return false; once _prefs is attached, rebuild.
    SharedPreferences.getInstance().then((p) {
      _prefs = p;
      final v = p.getBool(_accountChoiceKey) ?? false;
      if (v != state) state = v;
    });
    return false;
  }

  Future<void> markChosen() async {
    state = true;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_accountChoiceKey, true);
  }
}

/// Wraps [child] with a first-launch overlay that asks the user to sign in,
/// create an account, or continue as guest. Once a choice is persisted, the
/// overlay never shows again.
class AccountGate extends ConsumerWidget {
  final Widget child;
  const AccountGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = ref.watch(accountChoiceMadeProvider);
    return Stack(
      children: [
        child,
        if (!chosen) const _GateOverlay(),
      ],
    );
  }
}

class _GateOverlay extends ConsumerWidget {
  const _GateOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned.fill(
      child: ColoredBox(
        color: _bg.withAlpha(240),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _goldDim),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'WELCOME TO JAMTAMA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _gold,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sign in to sync your progress across devices, or start playing right away.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    _GateButton(
                      label: 'Create Account',
                      icon: Icons.person_add,
                      primary: true,
                      onTap: () => _openCreateAccount(context, ref),
                    ),
                    const SizedBox(height: 10),
                    _GateButton(
                      label: 'Sign In',
                      icon: Icons.login,
                      onTap: () => _openSignIn(context, ref),
                    ),
                    const SizedBox(height: 10),
                    _GateButton(
                      label: 'Continue as Guest',
                      icon: Icons.person_outline,
                      onTap: () =>
                          ref.read(accountChoiceMadeProvider.notifier).markChosen(),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Guest progress lives only on this device. Create an account any time from Options.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateAccount(BuildContext context, WidgetRef ref) async {
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CreateAccountDialog(),
    );
    if (success == true) {
      await ref.read(accountChoiceMadeProvider.notifier).markChosen();
    }
  }

  Future<void> _openSignIn(BuildContext context, WidgetRef ref) async {
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SignInDialog(),
    );
    if (success == true) {
      await ref.read(accountChoiceMadeProvider.notifier).markChosen();
    }
  }
}

class _GateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;
  const _GateButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: primary ? _gold : _goldDim,
              width: primary ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
            color: primary ? _goldDim.withAlpha(30) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: primary ? _gold : _goldDim, size: 18),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: primary ? _gold : _textPrimary,
                  fontSize: 15,
                  fontWeight:
                      primary ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create Account dialog — email + password + display name (all required).
// ---------------------------------------------------------------------------

class _CreateAccountDialog extends ConsumerStatefulWidget {
  const _CreateAccountDialog();

  @override
  ConsumerState<_CreateAccountDialog> createState() =>
      _CreateAccountDialogState();
}

class _CreateAccountDialogState extends ConsumerState<_CreateAccountDialog> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pw = _password.text;
    final name = _name.text.trim();

    if (email.isEmpty || pw.isEmpty || name.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    final nameValidation = validateDisplayName(name);
    if (!nameValidation.ok) {
      setState(() => _error = nameValidation.error);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = firebaseRepo(ref);
    if (repo == null) {
      setState(() {
        _error = 'Auth unavailable.';
        _loading = false;
      });
      return;
    }
    final err = await repo.linkEmail(email, pw);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _error = err;
        _loading = false;
      });
      return;
    }
    final nameErr = await ref
        .read(profileProvider.notifier)
        .initializeOnSignUp(name);
    if (!mounted) return;
    if (nameErr != null) {
      setState(() {
        _error = nameErr;
        _loading = false;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _surface,
      title: const Text('Create Account',
          style: TextStyle(
              color: _textPrimary, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Your current guest progress will carry over.',
            style: TextStyle(color: _textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _Field(controller: _name, label: 'Display Name'),
          const SizedBox(height: 10),
          _Field(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 10),
          _Field(
            controller: _password,
            label: 'Password',
            obscure: _obscure,
            suffix: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                  color: _textSecondary, size: 18),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel',
              style: TextStyle(color: _textSecondary)),
        ),
        TextButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _gold),
                )
              : const Text('Create',
                  style: TextStyle(color: _gold)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sign In dialog — warns about guest progress loss.
// ---------------------------------------------------------------------------

class _SignInDialog extends ConsumerStatefulWidget {
  const _SignInDialog();

  @override
  ConsumerState<_SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends ConsumerState<_SignInDialog> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pw = _password.text;
    if (email.isEmpty || pw.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = firebaseRepo(ref);
    if (repo == null) {
      setState(() {
        _error = 'Auth unavailable.';
        _loading = false;
      });
      return;
    }
    final err = await repo.signInWithEmail(email, pw);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _error = err;
        _loading = false;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    final repo = firebaseRepo(ref);
    if (repo == null) return;
    final err = await repo.sendPasswordReset(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Password reset email sent.'),
        backgroundColor: _surface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _surface,
      title: const Text('Sign In',
          style: TextStyle(
              color: _textPrimary, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Field(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 10),
          _Field(
            controller: _password,
            label: 'Password',
            obscure: _obscure,
            suffix: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                  color: _textSecondary, size: 18),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loading ? null : _forgotPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Forgot password?',
                  style: TextStyle(color: _gold, fontSize: 12)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel',
              style: TextStyle(color: _textSecondary)),
        ),
        TextButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _gold),
                )
              : const Text('Sign In',
                  style: TextStyle(color: _gold)),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _Field({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: _textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: _textSecondary, fontSize: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _surfaceLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _gold),
        ),
        filled: true,
        fillColor: _bg,
        isDense: true,
        suffixIcon: suffix,
      ),
    );
  }
}
