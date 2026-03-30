import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// Callback fired whenever new recognized words arrive.
/// [text] is the full recognized string so far for this listening session.
typedef SpeechResultCallback = void Function(String text);

/// Callback fired when an error occurs (permission denied, no match, etc.).
typedef SpeechErrorCallback = void Function(String errorMessage);

/// Singleton service wrapping the `speech_to_text` package.
///
/// Usage:
/// ```dart
/// final service = SpeechService.instance;
/// final available = await service.initialize();
/// if (available) {
///   service.startListening(
///     onResult: (text) => print('Heard: $text'),
///     onError: (err) => print('Error: $err'),
///   );
/// }
/// ```
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final SpeechToText _speech = SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;

  SpeechResultCallback? _onResult;
  SpeechErrorCallback? _onError;

  /// Whether the service is currently listening.
  bool get isListening => _isListening;

  /// Whether speech recognition is available on this device.
  bool get isAvailable => _isInitialized;

  /// Initialize the speech recognizer and check permissions.
  ///
  /// Returns `true` if speech recognition is available and permissions
  /// were granted, `false` otherwise.
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
      );
    } catch (e) {
      debugPrint('SpeechService: init failed — $e');
      _isInitialized = false;
    }

    return _isInitialized;
  }

  /// Start listening for speech input.
  ///
  /// [onResult] is called with the full recognized text whenever new words
  /// are detected (both partial and final results).
  ///
  /// [onError] is called if something goes wrong (permission issues, etc.).
  ///
  /// Does nothing if already listening or if the service isn't initialized.
  Future<void> startListening({
    required SpeechResultCallback onResult,
    SpeechErrorCallback? onError,
  }) async {
    if (_isListening) return;

    if (!_isInitialized) {
      final available = await initialize();
      if (!available) {
        onError?.call(
          'Speech recognition is not available on this device. '
          'Please check microphone permissions in Settings.',
        );
        return;
      }
    }

    _onResult = onResult;
    _onError = onError;
    _isListening = true;

    await _speech.listen(
      onResult: _handleResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        cancelOnError: false,
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  /// Stop listening.
  Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;
    await _speech.stop();
  }

  /// Cancel the current listening session without processing results.
  Future<void> cancel() async {
    _isListening = false;
    _onResult = null;
    _onError = null;
    await _speech.cancel();
  }

  // ── Internal handlers ─────────────────────────────────────────

  void _handleResult(SpeechRecognitionResult result) {
    _onResult?.call(result.recognizedWords);
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint('SpeechService error: ${error.errorMsg} (${error.permanent})');
    _isListening = false;

    if (error.permanent) {
      _onError?.call(
        'Microphone permission denied. Please enable it in Settings.',
      );
    } else {
      _onError?.call('Speech recognition error: ${error.errorMsg}');
    }
  }

  void _handleStatus(String status) {
    debugPrint('SpeechService status: $status');
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }
}
