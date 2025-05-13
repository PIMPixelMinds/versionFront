import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String apiKey = "AIzaSyB82Gg5oyIIQaPQ27Anf9ctOPumksPKtPc";
  static const String apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey";

  // List of common English stop words to filter out
  static const List<String> _englishStopWords = [
    'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'for', 'from', 'has',
    'he', 'in', 'is', 'it', 'its', 'of', 'on', 'that', 'the', 'to', 'was',
    'were', 'will', 'with'
  ];

  // List of common French stop words to filter out
  static const List<String> _frenchStopWords = [
    'un', 'une', 'et', 'sont', 'comme', 'à', 'être', 'par', 'pour', 'de',
    'il', 'elle', 'dans', 'est', 'ce', 'cette', 'le', 'la', 'l', 'les',
    'que', 'qui', 'au', 'du', 'sur', 'avec'
  ];

  Future<List<String>> generateWords({String lang = 'en'}) async {
    try {
      final prompt = lang == 'fr'
          ? "Génère 6 mots français significatifs (noms, verbes, adjectifs, ou adverbes) qui ne sont pas des mots de liaison (comme 'et', 'le', 'à'). Retourne seulement une liste séparée par des espaces."
          : "Generate 6 meaningful English words (nouns, verbs, adjectives, or adverbs) that are not stop words (like 'and', 'the', 'in'). Return only a space-separated list.";

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawText = data["candidates"][0]["content"]["parts"][0]["text"] as String;
        final cleaned = rawText
            .replaceAll(RegExp(r'[^\w\sÀ-ÿ\-]'), '')
            .replaceAll('\n', ' ')
            .trim();
        final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

        // Filter out stop words based on language
        final stopWords = lang == 'fr' ? _frenchStopWords : _englishStopWords;
        final filteredWords = words
            .where((word) => !stopWords.contains(word.toLowerCase()))
            .toList();

        // Ensure we return exactly 6 words, retry if needed
        if (filteredWords.length < 6) {
          print("Not enough valid words, retrying...");
          return await generateWords(lang: lang);
        }

        return filteredWords.take(6).toList();
      } else {
        throw Exception("API Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Gemini API Error: $e");
      throw Exception("Failed to fetch words");
    }
  }
}