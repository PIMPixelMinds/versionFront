import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:pim/data/repositories/ai_service.dart';
import 'package:pim/core/constants/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AuditifWordGame extends StatefulWidget {
  const AuditifWordGame({super.key});

  @override
  State<AuditifWordGame> createState() => _AuditifWordGameState();
}

class _AuditifWordGameState extends State<AuditifWordGame> {
  final FlutterTts _tts = FlutterTts();
  final AIService _geminiAPI = AIService();

  List<String> _gameWords = [];
  String _userInput = "";
  int _score = 0;
  bool _ttsSpeaking = false;
  bool _gameCompleted = false;

  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _configureTTS();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _configureTTS() {
    _tts.setCompletionHandler(() => setState(() => _ttsSpeaking = false));
    _tts.setStartHandler(() => setState(() => _ttsSpeaking = true));
    _tts.setLanguage("en-US");
  }

  Future<void> _fetchAndSpeakWords() async {
    try {
      _gameWords = await _geminiAPI.generateWords();
      setState(() {});

      for (String word in _gameWords) {
        await _tts.speak(word);
        await Future.delayed(const Duration(seconds: 4));
      }

      setState(() => _ttsSpeaking = false);
    } catch (e) {
      debugPrint("Error fetching words: $e");
    }
  }

  void _checkAnswer() {
    if (_userInput.isEmpty) return;

    final normalizedUserInput = _userInput.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    final userWords = normalizedUserInput.split(' ');
    final normalizedAIWords = _gameWords.map((word) => word.toLowerCase().trim()).toList();

    int correctCount = 0;
    for (final word in normalizedAIWords) {
      if (userWords.contains(word)) correctCount++;
    }

    setState(() {
      _score = correctCount;
      _gameCompleted = true;
    });

    _showResultDialog(_score);
  }

  void _showResultDialog(int score) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.dialogBackgroundColor,
        title: Text(
          locale.results,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              locale.youRemembere(_score, _gameWords.length),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _textController.clear();
                  _userInput = "";
                  _score = 0;
                  _gameCompleted = false;
                  _fetchAndSpeakWords();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(locale.playAgain, style: const TextStyle(fontSize: 18, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(locale.auditoryGameTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              locale.auditoryGameInstruction,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            IconButton(
              icon: Icon(
                _ttsSpeaking ? Icons.volume_up : Icons.volume_off,
                size: 50,
                color: AppColors.primaryBlue,
              ),
              onPressed: () {
                if (_ttsSpeaking) {
                  _tts.stop();
                } else {
                  _fetchAndSpeakWords();
                }
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                labelText: locale.typeWordsHint,
                labelStyle: TextStyle(color: AppColors.primaryBlue),
              ),
              onChanged: (value) => setState(() => _userInput = value),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(locale.submit, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
