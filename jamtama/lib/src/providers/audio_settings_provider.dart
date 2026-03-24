import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioSettings {
  final double masterVolume;
  final double sfxVolume;
  final double musicVolume;

  const AudioSettings({
    this.masterVolume = 1.0,
    this.sfxVolume = 1.0,
    this.musicVolume = 0.7,
  });

  AudioSettings copyWith({
    double? masterVolume,
    double? sfxVolume,
    double? musicVolume,
  }) =>
      AudioSettings(
        masterVolume: masterVolume ?? this.masterVolume,
        sfxVolume: sfxVolume ?? this.sfxVolume,
        musicVolume: musicVolume ?? this.musicVolume,
      );
}

class AudioSettingsNotifier extends Notifier<AudioSettings> {
  @override
  AudioSettings build() => const AudioSettings();

  void setMaster(double v) => state = state.copyWith(masterVolume: v);
  void setSfx(double v) => state = state.copyWith(sfxVolume: v);
  void setMusic(double v) => state = state.copyWith(musicVolume: v);
}

final audioSettingsProvider =
    NotifierProvider<AudioSettingsNotifier, AudioSettings>(
  AudioSettingsNotifier.new,
);
