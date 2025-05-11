import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pim/core/constants/app_colors.dart';

class WordGamePage extends StatefulWidget {
  const WordGamePage({super.key});

  @override
  _WordGamePageState createState() => _WordGamePageState();
}

class _WordGamePageState extends State<WordGamePage> {
  
  
  
@override
void didChangeDependencies() {
  super.didChangeDependencies();

  final locale = AppLocalizations.of(context)!;
  allWords = [
    locale.wordApple,
    locale.wordBanana,
    locale.wordOrange,
    locale.wordGrapes,
    locale.wordWatermelon,
    locale.wordStrawberry,
    locale.wordPineapple,
    locale.wordMango,
    locale.wordPeach,
    locale.wordBlueberry,
    locale.wordCarrot,
    locale.wordTomato,
    locale.wordPotato,
    locale.wordCucumber,
    locale.wordLemon,
    locale.wordLettuce,
    locale.wordOnion,
    locale.wordPumpkin,
    locale.wordCabbage,
    locale.wordRadish,
  ];

  // Démarre le jeu uniquement une fois que les mots sont disponibles
  if (shownWords.isEmpty) {
    _startGame();
  }
}
late List<String> allWords;
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
    
  }

  void _startGame() {
    shownWords = List.from(allWords)..shuffle();
shownWords = shownWords.sublist(0, 10);
choices = List.from(allWords)..shuffle();
    _isRevealing = true;
    _memorizationTime = 5;
    _startMemorizationTimer();
    score = 0;
    selectedWords.clear();
    secondsLeft = 10;
    showSelectionScreen = false;
  }

  void _startMemorizationTimer() {
    _memorizationTimer?.cancel();
    _memorizationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).dialogBackgroundColor, // ✅ Thème auto
      title: Text(
        locale.results,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            locale.youRemembered(score),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _startGame();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue, // ✅ Bouton bleu
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              locale.playAgain,
              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    ),
  );
}

  Widget _buildInfoBox(String title, String value) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildGameTimerWidget(AppLocalizations locale) {
    return Center(
      child: Text(
        locale.gameTimeLeft('$secondsLeft'),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildWordDisplayScreen(AppLocalizations locale) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            locale.memorize,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: shownWords
                .map((word) => Chip(
                      label: Text(word, style: const TextStyle(fontSize: 18, color: Colors.white)),
                      backgroundColor: AppColors.primaryBlue,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionScreen(AppLocalizations locale) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            locale.selectRemembered,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: choices.map((word) {
              final isSelected = selectedWords.contains(word);
              return ChoiceChip(
                label: Text(word, style: const TextStyle(fontSize: 16, color: Colors.white)),
                selected: isSelected,
                selectedColor: AppColors.primaryBlue,
                backgroundColor: Colors.grey[400],
                onSelected: (selected) {
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
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(locale.submit, style: const TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ],
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
        title: Text(locale.wordGameTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16.0),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBox(locale.score, '$score'),
                _buildInfoBox(locale.time, '${secondsLeft}s'),
              ],
            ),
            const SizedBox(height: 20),
            if (!_isRevealing && !showSelectionScreen)
              _buildGameTimerWidget(locale),
            const SizedBox(height: 20),
            Expanded(
              child: Stack(
                children: [
                  if (showSelectionScreen)
                    _buildSelectionScreen(locale)
                  else
                    _buildWordDisplayScreen(locale),
                  if (_isRevealing)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.1),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                locale.getReady,
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                '$_memorizationTime',
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 100,
                                      color: Colors.white,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}