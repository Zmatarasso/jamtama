import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cosmetics/providers/cosmetic_loadout_provider.dart';
import '../profile/display_name_validator.dart';
import '../profile/profile.dart';
import '../profile/profile_provider.dart';
import '../providers/audio_settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/tutorial_provider.dart';

const _bg = Color(0xFF1A1A2E);
const _surface = Color(0xFF16213E);
const _surfaceLight = Color(0xFF1F2D4A);
const _gold = Color(0xFFD4AF37);
const _textPrimary = Color(0xFFE8E0D0);
const _textSecondary = Color(0xFF8A7F7F);

class OptionsScreen extends ConsumerWidget {
  const OptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioSettingsProvider);
    final notifier = ref.read(audioSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        title: const Text(
          'Options',
          style: TextStyle(
            color: _gold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SectionHeader(label: 'Account'),
          const SizedBox(height: 12),
          const _AccountSection(),
          const SizedBox(height: 32),

          _SectionHeader(label: 'Audio'),
          const SizedBox(height: 16),
          _VolumeSlider(
            icon: Icons.volume_up,
            label: 'Master Volume',
            value: audio.masterVolume,
            onChanged: notifier.setMaster,
          ),
          const SizedBox(height: 12),
          _VolumeSlider(
            icon: Icons.spatial_audio,
            label: 'SFX Volume',
            value: audio.sfxVolume,
            onChanged: notifier.setSfx,
          ),
          const SizedBox(height: 12),
          _VolumeSlider(
            icon: Icons.music_note,
            label: 'Music Volume',
            value: audio.musicVolume,
            onChanged: notifier.setMusic,
          ),
          const SizedBox(height: 32),

          _SectionHeader(label: 'Tutorial'),
          const SizedBox(height: 16),
          _ResetTutorialButton(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: _gold,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: _surfaceLight, thickness: 1)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Account section — avatar + display name + auth controls.
// ---------------------------------------------------------------------------

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final isAnon = ref.watch(isAnonymousProvider);
    final email = ref.watch(userEmailProvider);

    return Column(
      children: [
        _ProfileRow(profile: profile),
        const SizedBox(height: 10),
        _AuthRow(isAnonymous: isAnon, email: email),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Profile row — avatar + display name + change/cooldown UI.
// ---------------------------------------------------------------------------

class _ProfileRow extends ConsumerWidget {
  final Profile profile;
  const _ProfileRow({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(
        cosmeticLoadoutProvider.select((l) => l.profilePicture));
    final canChange =
        ref.read(profileProvider.notifier).canChangeDisplayName;
    final remaining =
        ref.read(profileProvider.notifier).timeUntilNextChange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _surfaceLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _surfaceLight,
            child: Icon(
              avatar.fallbackIcon,
              color: avatar.fallbackColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName ?? 'No display name',
                  style: TextStyle(
                    color: profile.displayName != null
                        ? _textPrimary
                        : _textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                if (!canChange && remaining != null)
                  _CountdownText(remaining: remaining)
                else
                  const Text(
                    'Tap edit to change your name',
                    style: TextStyle(color: _textSecondary, fontSize: 11),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              canChange ? Icons.edit_outlined : Icons.lock_outline,
              color: canChange ? _textSecondary : _textSecondary.withAlpha(120),
              size: 18,
            ),
            onPressed: canChange
                ? () => _openEditDialog(context, ref, profile.displayName)
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _openEditDialog(
      BuildContext context, WidgetRef ref, String? current) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _DisplayNameDialog(initial: current ?? ''),
    );
  }
}

class _CountdownText extends StatefulWidget {
  final Duration remaining;
  const _CountdownText({required this.remaining});

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.remaining;
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        _remaining -= const Duration(seconds: 30);
        if (_remaining.isNegative) _remaining = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final label = h > 0 ? 'Next change in ${h}h ${m}m' : 'Next change in ${m}m';
    return Text(label,
        style: const TextStyle(color: _textSecondary, fontSize: 11));
  }
}

class _DisplayNameDialog extends ConsumerStatefulWidget {
  final String initial;
  const _DisplayNameDialog({required this.initial});

  @override
  ConsumerState<_DisplayNameDialog> createState() =>
      _DisplayNameDialogState();
}

class _DisplayNameDialogState extends ConsumerState<_DisplayNameDialog> {
  late final TextEditingController _controller;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await ref
        .read(profileProvider.notifier)
        .updateDisplayName(_controller.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _error = err;
        _loading = false;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _surface,
      title: const Text('Change Display Name',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You can only change this once per day.',
            style: TextStyle(color: _textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(color: _textPrimary),
            onChanged: (v) {
              final res = validateDisplayName(v);
              setState(() => _error = res.ok ? null : res.error);
            },
            decoration: InputDecoration(
              hintText: 'Display name',
              hintStyle: TextStyle(color: _textSecondary.withAlpha(150)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _surfaceLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _gold),
              ),
              filled: true,
              fillColor: _bg,
              isDense: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: _textSecondary)),
        ),
        TextButton(
          onPressed: _loading || _error != null ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _gold))
              : const Text('Save', style: TextStyle(color: _gold)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Auth row — shows email or anonymous state with login/upgrade buttons.
// ---------------------------------------------------------------------------

class _AuthRow extends ConsumerWidget {
  final bool isAnonymous;
  final String? email;
  const _AuthRow({required this.isAnonymous, required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _surfaceLight),
      ),
      child: Row(
        children: [
          Icon(
            isAnonymous ? Icons.person_outline : Icons.verified_user,
            color: isAnonymous ? _textSecondary : _gold,
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAnonymous ? 'Guest' : (email ?? 'Signed in'),
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAnonymous
                      ? 'Save your progress across devices'
                      : 'Progress synced to cloud',
                  style: TextStyle(
                    color: _textSecondary.withAlpha(180),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isAnonymous) ...[
            _AuthButton(
              label: 'Sign Up',
              onTap: () => _showAuthDialog(context, ref,
                  mode: _AuthMode.createAccount),
            ),
            const SizedBox(width: 8),
            _AuthButton(
              label: 'Sign In',
              onTap: () =>
                  _showAuthDialog(context, ref, mode: _AuthMode.signIn),
            ),
          ] else
            _AuthButton(
              label: 'Sign Out',
              onTap: () => _confirmSignOut(context, ref),
            ),
        ],
      ),
    );
  }

  void _showAuthDialog(BuildContext context, WidgetRef ref,
      {required _AuthMode mode}) {
    showDialog(
      context: context,
      builder: (_) => _AuthDialog(mode: mode),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Sign Out',
            style: TextStyle(color: _textPrimary)),
        content: const Text(
          'Your progress is saved to the cloud. You can sign back in on any device.',
          style: TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: _textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out',
                style: TextStyle(color: _gold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await firebaseRepo(ref)?.signOut();
      await ref.read(profileProvider.notifier).clearLocal();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out'),
            backgroundColor: _surface,
          ),
        );
      }
    }
  }
}

enum _AuthMode { createAccount, signIn }

class _AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AuthButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _gold,
        side: const BorderSide(color: _gold, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

// ---------------------------------------------------------------------------
// Auth dialog — create account or sign in.
// ---------------------------------------------------------------------------

class _AuthDialog extends ConsumerStatefulWidget {
  final _AuthMode mode;
  const _AuthDialog({required this.mode});

  @override
  ConsumerState<_AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends ConsumerState<_AuthDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool get _isCreate => widget.mode == _AuthMode.createAccount;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    if (_isCreate) {
      if (name.isEmpty) {
        setState(() => _error = 'Please enter a display name.');
        return;
      }
      final v = validateDisplayName(name);
      if (!v.ok) {
        setState(() => _error = v.error);
        return;
      }
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

    final error = _isCreate
        ? await repo.linkEmail(email, password)
        : await repo.signInWithEmail(email, password);

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _error = error;
        _loading = false;
      });
      return;
    }

    if (_isCreate) {
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
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isCreate
            ? 'Account created! Your progress is now saved.'
            : 'Signed in! Your progress has been restored.'),
        backgroundColor: _surface,
      ),
    );
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
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
      title: Text(
        _isCreate ? 'Create Account' : 'Sign In',
        style: const TextStyle(
            color: _textPrimary, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isCreate
                ? 'Link an email to save your progress across devices.'
                : 'Signing in will replace your current guest progress with your account\'s progress.',
            style: TextStyle(
                color: _textSecondary.withAlpha(200), fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (_isCreate) ...[
            _DialogField(controller: _nameController, label: 'Display Name'),
            const SizedBox(height: 10),
          ],
          _DialogField(
            controller: _emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),
          _DialogField(
            controller: _passwordController,
            label: 'Password',
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: _textSecondary,
                size: 18,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          if (!_isCreate)
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
            const SizedBox(height: 12),
            Text(
              _error!,
              style:
                  const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
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
              : Text(
                  _isCreate ? 'Create Account' : 'Sign In',
                  style: const TextStyle(color: _gold),
                ),
        ),
      ],
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _DialogField({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType,
    this.suffixIcon,
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
            TextStyle(color: _textSecondary.withAlpha(200), fontSize: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _surfaceLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _gold),
        ),
        filled: true,
        fillColor: _bg,
        isDense: true,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _VolumeSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _VolumeSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _surfaceLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: _textSecondary, size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: _textPrimary, fontSize: 13),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _gold,
                inactiveTrackColor: _surfaceLight,
                thumbColor: _gold,
                overlayColor: _gold.withAlpha(30),
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '${(value * 100).round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _textSecondary.withAlpha(180),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ResetTutorialButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.school_outlined),
      label: const Text('Reset Tutorial'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _textSecondary,
        side: BorderSide(color: _surfaceLight),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: () async {
        await ref.read(tutorialProvider.notifier).reset();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Tutorial reset — it will show next time you open the menu.'),
              backgroundColor: Color(0xFF16213E),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }
}
