import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WordGamePage extends StatefulWidget {
  const WordGamePage({super.key});

  @override
  _WordGamePageState createState() => _WordGamePageState();
}

class _WordGamePageState extends State<WordGamePage> {
  List<String> _allWords = []; // Dynamic word pool from JSON

  // Fallback static list in case JSON loading fails
  final List<String> _fallbackWords = [
    'apple', 'banana', 'orange', 'grapes', 'watermelon',
    'strawberry', 'pineapple', 'mango', 'peach', 'blueberry',
    'carrot', 'tomato', 'potato', 'cucumber', 'lemon',
    'lettuce', 'onion', 'pumpkin', 'cabbage', 'radish',
  ];

  List<String> shownWords = [];
  List<String> choices = [];
  Set<String> selectedWords = {};
  bool showSelectionScreen = false;
  Timer? timer;
  int secondsLeft = 10;
  int score = 0;
  bool _isRevealing = true;
  int _memorizationTime = 5;
  Timer? _memorizationTimer;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _memorizationTimer?.cancel();
    timer?.cancel();
    super.dispose();
  }

  Future<void> _startGame() async {
    setState(() {
      showSelectionScreen = false;
      secondsLeft = 10;
      selectedWords.clear();
      score = 0;
      _isRevealing = true;
      _memorizationTime = 5;
    });

    try {
      // Load words from assets/words.json
      String jsonString = await DefaultAssetBundle.of(context).loadString('assets/words.json');
      _allWords = List<String>.from(jsonDecode(jsonString));
      print("Loaded ${_allWords.length} words from JSON");
    } catch (e) {
      print("Error loading words.json: $e");
      _allWords = List.from(_fallbackWords); // Use fallback if JSON fails
    }

    setState(() {
      // Ensure we have enough words
      if (_allWords.length < 20) {
        _allWords.addAll(_fallbackWords);
        _allWords = _allWords.toSet().toList(); // Remove duplicates
      }

      // Select 10 words for memorization
      shownWords = (_allWords..shuffle()).sublist(0, 10);

      // Select 20 choices, including shownWords and others
      choices = (_allWords..shuffle()).sublist(0, 20);
      if (!shownWords.every((word) => choices.contains(word))) {
        choices.removeRange(0, shownWords.length);
        choices.addAll(shownWords);
        choices.shuffle();
      }
    });

    _startMemorizationTimer();
  }

  void _startMemorizationTimer() {
    _memorizationTimer?.cancel();
    _memorizationTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        if (_memorizationTime > 1) {
          _memorizationTime--;
        } else {
          timer.cancel();
          _isRevealing = false;
          _startTimer();
        }
      });
    });
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        if (secondsLeft > 1) {
          secondsLeft--;
        } else {
          t.cancel();
          showSelectionScreen = true;
        }
      });
    });
  }

  void _checkAnswers() {
    score = selectedWords.where((word) => shownWords.contains(word)).length;
    _showResultDialog(score);
  }

  void _showResultDialog(int score) {
    final locale = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          locale.results,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              locale.youRemembered(score),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                locale.playAgain,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
  backgroundColor: Colors.transparent,
  elevation: 0,
  centerTitle: true,
  title: Text(
    locale.wordGameTitle, // use appropriate key
    style: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
  iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[700]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoBox(locale.score, '$score'),
                    _buildInfoBox(locale.time, '${secondsLeft}s'),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isRevealing)
                  _buildRevealingOverlay(locale)
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: showSelectionScreen
                        ? _buildSelectionScreen(locale)
                        : _buildWordDisplayScreen(locale),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevealingOverlay(AppLocalizations locale) {
  return Positioned.fill(
    child: Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              locale.getReady,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$_memorizationTime',
              style: const TextStyle(
                fontSize: 100,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildWordDisplayScreen(AppLocalizations locale) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedOpacity(
          opacity: secondsLeft > 0 ? 1.0 : 0.0,
          duration: const Duration(seconds: 1),
          child: Text(
            "$secondsLeft",
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
              shadows: [
                Shadow(
                  blurRadius: 15.0,
                  color: Colors.blue[800]!.withOpacity(0.6),
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          locale.memorize,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: shownWords
              .map((word) => Chip(
            label: Text(
              word,
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            backgroundColor: Colors.blue[200],
          ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSelectionScreen(AppLocalizations locale) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          locale.selectRemembered,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black45),
        ),
        const SizedBox(height: 10),
       // Text(
         // locale.selectionLimit(selectedWords.length),
         // textAlign: TextAlign.center,
         // style: const TextStyle(fontSize: 16, color: Colors.redAccent),
       // ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: choices.map((word) {
            bool isSelected = selectedWords.contains(word);
            return ChoiceChip(
              label: Text(
                word,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              selected: isSelected,
              selectedColor: Colors.greenAccent,
              backgroundColor: isSelected || selectedWords.length < 10 ? Colors.grey[400] : Colors.grey[200],
              onSelected: (selected) {
                if (selected && selectedWords.length >= 10 && !isSelected) {
                  // Prevent selecting more than 10 words
                  return;
                }
                setState(() {
                  if (selected) {
                    selectedWords.add(word);
                  } else {
                    selectedWords.remove(word);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _checkAnswers,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            locale.submit,
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String title, String value) {
  return Card(
    color: Colors.black,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFF3c84fb), width: 2),
    ),
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}
}
