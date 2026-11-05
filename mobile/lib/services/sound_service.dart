import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// SoundService manages emergency alerts, continuous loop sirens, and mobile vibration.
/// Loops continuously until the user explicitly accepts, verifies, or acknowledges the alert/request.
class SoundService {
  static final SoundService instance = SoundService._internal();

  factory SoundService() => instance;

  SoundService._internal();

  AudioPlayer? _player;
  Timer? _vibrationTimer;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  AudioPlayer get _audioPlayer {
    _player ??= AudioPlayer();
    return _player!;
  }

  /// Triggers continuous loop siren audio and device vibration.
  /// Does NOT stop until [stopSound] or [stopAlert] is called (e.g., when accepted/acknowledged).
  Future<void> playAlertSound() async {
    try {
      final player = _audioPlayer;

      // Stop previous instance if any
      await player.stop();
      _stopVibration();

      // Configure player for continuous looping alert
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(1.0);

      // Start looping alert sound asset (assets/sounds/alert.mp3)
      await player.play(AssetSource('sounds/alert.mp3'));
      _isPlaying = true;
      debugPrint('[SoundService] 🚨 Continuous alert sound & vibration started (looping until accepted)');

      // Start continuous mobile vibration
      _startVibration();
    } catch (e) {
      debugPrint('[SoundService] Error playing alert sound: $e');
    }
  }

  /// Starts continuous vibration for mobile devices (Tourist & Ranger)
  Future<void> _startVibration() async {
    try {
      final hasVib = await Vibration.hasVibrator();
      if (hasVib) {
        final hasCustom = await Vibration.hasCustomVibrationsSupport();
        if (hasCustom) {
          // Continuous pattern: 500ms vibrate, 300ms pause, repeat starting at index 0 indefinitely
          Vibration.vibrate(pattern: [0, 500, 300, 500, 300], repeat: 1);
        } else {
          // Device with simple vibrator: trigger periodic vibration
          _vibrationTimer?.cancel();
          _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
            Vibration.vibrate(duration: 700);
            HapticFeedback.heavyImpact();
          });
          Vibration.vibrate(duration: 700);
        }
      } else {
        // Fallback for devices relying on system haptic feedback
        _vibrationTimer?.cancel();
        _vibrationTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
          HapticFeedback.heavyImpact();
        });
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      debugPrint('[SoundService] Vibration error: $e');
      // Graceful fallback to HapticFeedback
      _vibrationTimer?.cancel();
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
        HapticFeedback.heavyImpact();
      });
      HapticFeedback.heavyImpact();
    }
  }

  /// Stops continuous vibration
  void _stopVibration() {
    try {
      _vibrationTimer?.cancel();
      _vibrationTimer = null;
      Vibration.cancel();
    } catch (e) {
      debugPrint('[SoundService] Vibration cancel error: $e');
    }
  }

  /// Turn off alert audio and stop mobile vibration when request is accepted/acknowledged
  Future<void> stopSound() async {
    try {
      _stopVibration();
      if (_player != null) {
        await _player!.stop();
      }
      _isPlaying = false;
      debugPrint('[SoundService] 🔇 Alert sound & vibration stopped (request accepted/resolved)');
    } catch (e) {
      debugPrint('[SoundService] Error stopping alert sound: $e');
    }
  }

  /// Alias for stopSound
  Future<void> stopAlert() => stopSound();

  /// Dispose player resources
  void dispose() {
    _stopVibration();
    _player?.dispose();
    _player = null;
  }
}
