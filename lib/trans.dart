import 'package:google_ml_kit/google_ml_kit.dart';

class TranslationService {
  static Future<String> translate(String text, String targetLanguageCode) async {
    try {
      final targetLanguage = _getTranslateLanguage(targetLanguageCode);
      if (targetLanguage == null) {
        return 'Error: Unsupported language code $targetLanguageCode';
      }

      final translator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: targetLanguage,
      );
      final translatedText = await translator.translateText(text);
      translator.close();
      return translatedText;
    } catch (e) {
      return 'Error translating: $e';
    }
  }

  static TranslateLanguage? _getTranslateLanguage(String code) {
    switch (code.toLowerCase()) {
      case 'en':
        return TranslateLanguage.english;
      case 'es':
        return TranslateLanguage.spanish;
      case 'fr':
        return TranslateLanguage.french;
      case 'de':
        return TranslateLanguage.german;
      case 'hi':
        return TranslateLanguage.hindi;
      case 'ta':
        return TranslateLanguage.tamil;
      default:
        return null;
    }
  }

  static const Map<String, String> supportedLanguages = {
    'English': 'en',
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Hindi': 'hi',
    'Tamil': 'ta',
  };
}