import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Sound effect types available in the app.
enum SoundEffect {
  correct('audio/correct.wav'),
  incorrect('audio/incorrect.wav'),
  complete('audio/complete.wav'),
  levelup('audio/levelup.wav');

  const SoundEffect(this.assetPath);
  final String assetPath;
}

/// Audio service state — just tracks the mute setting.
class AudioState {
  final bool isMuted;

  const AudioState({this.isMuted = false});

  AudioState copyWith({bool? isMuted}) {
    return AudioState(isMuted: isMuted ?? this.isMuted);
  }
}

/// Manages sound effects with preloaded players for zero-latency playback.
///
/// Uses a pool of AudioPlayer instances to allow overlapping sounds.
/// Persists mute preference via Hive.
class AudioNotifier extends StateNotifier<AudioState> {
  AudioNotifier() : super(const AudioState());

  static const _hiveBoxName = 'audio_settings';
  static const _muteKey = 'is_muted';

  Box? _settingsBox;

  /// Pool of reusable players per sound effect.
  final Map<SoundEffect, List<AudioPlayer>> _playerPool = {};

  /// Number of players per sound effect (allows overlapping).
  static const _poolSize = 3;

  /// Round-robin index for each sound effect.
  final Map<SoundEffect, int> _poolIndex = {};

  /// Initialize: open Hive box and preload all sounds.
  Future<void> init() async {
    _settingsBox = await Hive.openBox(_hiveBoxName);
    final muted = _settingsBox?.get(_muteKey, defaultValue: false) as bool;
    state = AudioState(isMuted: muted);

    // Preload player pools for each sound effect
    for (final effect in SoundEffect.values) {
      _playerPool[effect] = [];
      _poolIndex[effect] = 0;

      for (int i = 0; i < _poolSize; i++) {
        final player = AudioPlayer();
        // Set source so it's ready to play instantly
        await player.setSource(AssetSource(effect.assetPath));
        await player.setReleaseMode(ReleaseMode.stop);
        _playerPool[effect]!.add(player);
      }
    }
  }

  /// Play a sound effect. No-op if muted.
  Future<void> play(SoundEffect effect) async {
    if (state.isMuted) return;

    final players = _playerPool[effect];
    if (players == null || players.isEmpty) return;

    // Round-robin through the pool
    final index = _poolIndex[effect] ?? 0;
    final player = players[index];
    _poolIndex[effect] = (index + 1) % players.length;

    // Stop if currently playing, then play from start
    await player.stop();
    await player.setSource(AssetSource(effect.assetPath));
    await player.resume();
  }

  /// Toggle mute on/off.
  void toggleMute() {
    final newMuted = !state.isMuted;
    state = state.copyWith(isMuted: newMuted);
    _settingsBox?.put(_muteKey, newMuted);
  }

  /// Explicitly set mute state.
  void setMuted(bool muted) {
    state = state.copyWith(isMuted: muted);
    _settingsBox?.put(_muteKey, muted);
  }

  @override
  void dispose() {
    for (final players in _playerPool.values) {
      for (final player in players) {
        player.dispose();
      }
    }
    super.dispose();
  }
}

/// Global provider for the audio service.
final audioProvider = StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  return AudioNotifier();
});
