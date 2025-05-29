import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;
  static bool _speechEnabled = true;

  static Future<void> init() async {
    if (!_isInitialized) {
      try {
        await _flutterTts.setLanguage("en-US");
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
        _isInitialized = true;
        print('SpeechService initialized successfully');
      } catch (e) {
        print('Error initializing SpeechService: $e');
      }
    }
  }

  static void setSpeechEnabled(bool enabled) {
    _speechEnabled = enabled;
    print('SpeechService: Speech enabled set to $_speechEnabled');
    if (!enabled) {
      _flutterTts.stop();
    }
  }

  static Future<void> speak(String text) async {
    if (!_speechEnabled || text.isEmpty) {
      print('SpeechService: Speech skipped (enabled: $_speechEnabled, text: $text)');
      return;
    }

    if (!_isInitialized) {
      await init();
    }

    try {
      print('SpeechService: Speaking: $text');
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      print('SpeechService: Error speaking: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _flutterTts.stop();
      print('SpeechService: Speech stopped');
    } catch (e) {
      print('SpeechService: Error stopping speech: $e');
    }
  }
}