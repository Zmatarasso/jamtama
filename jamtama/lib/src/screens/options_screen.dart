import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/audio_settings_provider.dart';
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
          // ── Account ───────────────────────────────────────────────────────
          _SectionHeader(label: 'Account'),
          const SizedBox(height: 12),
          _AccountRow(),
          const SizedBox(height: 32),

          // ── Audio ─────────────────────────────────────────────────────────
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

          // ── Tutorial ──────────────────────────────────────────────────────
          _SectionHeader(label: 'Tutorial'),
          const SizedBox(height: 16),
          _ResetTutorialButton(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
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
// Account row — display name + logout button
// ---------------------------------------------------------------------------

class _AccountRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _surfaceLight),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: _surfaceLight,
            child: Icon(Icons.person, color: _textSecondary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Guest',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Not logged in',
                  style: TextStyle(
                    color: _textSecondary.withAlpha(180),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Login coming soon')),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _gold,
              side: const BorderSide(color: _gold, width: 1),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Log In', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Volume slider row
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
// Reset tutorial button
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
              content: Text('Tutorial reset — it will show next time you open the menu.'),
              backgroundColor: Color(0xFF16213E),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }
}
