import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pim/data/repositories/healthtracker_repository.dart';

class HealthTrackerViewModel extends ChangeNotifier {
  final HealthTrackerRepository _repository = HealthTrackerRepository();

  bool isLoading = false;
  String errorMessage = '';
  List<dynamic> activities = [];
  List<dynamic> completedAppointments = [];
  List<dynamic> questions = [];
  Map<String, bool> answers = {};
  String? questionnaireError;
  bool isTestLocked = true;
  DateTime? nextAvailableDate;
  int upcomingAppointmentsCount = 0;

  // Medication stats
  int takenCount = 0;
  int pendingCount = 0;
  int totalMedicationCount = 0;
  double adherenceRate = 0;
  double pendingRate = 0;
  double skippedRate = 0;

  // Gemini-generated word game
  List<String> aiWords = [];
  bool isAiLoading = false;
  String aiError = '';

Future<void> fetchActivities(BuildContext context) async {
  _setLoading(true);
  try {
    final localeCode = Localizations.localeOf(context).languageCode;
    print('ðŸŒ Current locale detected: $localeCode');

    final fetchedActivities = await _repository.getActivities(lang: localeCode);
    activities = fetchedActivities;
    print('âœ… Activities fetched (${activities.length}): $activities');
  } catch (e) {
    _handleError(context, "Error fetching activities: $e");
  } finally {
    _setLoading(false);
  }
}

  Future<void> fetchUpcomingAppointmentsCount(BuildContext context) async {
    _setLoading(true);
    try {
      upcomingAppointmentsCount = await _repository.getUpcomingAppointmentsCount();
    } catch (e) {
      _handleError(context, "Error fetching appointment count: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchCompletedAppointments(BuildContext context) async {
    _setLoading(true);
    try {
      completedAppointments = await _repository.getCompletedAppointments();
    } catch (e) {
      _handleError(context, "Error fetching completed appointments: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchQuestions(BuildContext context) async {
    _setLoading(true);
    try {
      questions = await _repository.getQuestions();
      questionnaireError = null;
    } catch (e) {
      questionnaireError = "Failed to load questions: $e";
      _handleError(context, questionnaireError!);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkQuestionnaireAvailability() async {
    _setLoading(true);
    try {
      final result = await _repository.checkQuestionnaireAvailability();
      isTestLocked = !(result['canTake'] ?? false);
      nextAvailableDate = result['nextAvailable'] != null
          ? DateTime.parse(result['nextAvailable']).toLocal()
          : _calculateNextMonday();
    } catch (e) {
      _fallbackNextMonday();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitQuestionnaire(BuildContext context) async {
    _setLoading(true);
    try {
      await _repository.submitAnswers(answers);
      await checkQuestionnaireAvailability();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Questionnaire submitted!')),
        );
      }
    } catch (e) {
      _handleError(context, "Submission failed: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMedicationStats(BuildContext context) async {
    _setLoading(true);
    try {
      final stats = await _repository.getMedicationStats();
      takenCount = stats['takenCount'] ?? 0;
      pendingCount = stats['pendingCount'] ?? 0;
      totalMedicationCount = stats['total'] ?? 0;
      adherenceRate = stats['adherenceRate']?.toDouble() ?? 0;
      pendingRate = stats['pendingRate']?.toDouble() ?? 0;
      skippedRate = stats['skippedRate']?.toDouble() ?? 0;
    } catch (e) {
      errorMessage = "Failed to fetch medication stats: $e";
      _resetMedicationStats();
      _handleError(context, errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Helpers
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _handleError(BuildContext context, String message) {
    errorMessage = message;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
    notifyListeners();
  }

  void _fallbackNextMonday() {
    nextAvailableDate = _calculateNextMonday();
    isTestLocked = true;
  }

  DateTime _calculateNextMonday() {
    final now = DateTime.now();
    final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
    return now.add(Duration(days: daysUntilMonday));
  }

  void _resetMedicationStats() {
    takenCount = 0;
    pendingCount = 0;
    totalMedicationCount = 0;
    adherenceRate = 0;
    pendingRate = 0;
    skippedRate = 0;
  }

  Map<String, dynamic>? relapsePrediction;
bool isLoadingPrediction = false;
String predictionError = '';

final HealthTrackerRepository _repo = HealthTrackerRepository();

Future<void> fetchRelapsePrediction() async {
  isLoadingPrediction = true;
  predictionError = '';
  relapsePrediction = null;
  notifyListeners();

  print("🔄 Début de la prédiction...");

  try {
    final response = await _repo.predictNextRelapse();
    print("✅ Réponse reçue depuis le backend : $response");

    if (response is Map &&
        response.containsKey("predicted_days_to_next_relapse") &&
        response.containsKey("predicted_next_relapse_date")) {
      relapsePrediction = response;
      predictionError = '';
      print("🧠 Prédiction stockée : $relapsePrediction");
    } else {
      relapsePrediction = null;
      predictionError = "Réponse inattendue du serveur.";
      print("⚠️ Réponse inattendue : $response");
    }
  } catch (e) {
    print("❌ Exception attrapée : $e");

    try {
      final errorString = e.toString();
      final jsonStart = errorString.indexOf('{');
      final jsonPart = jsonStart != -1 ? errorString.substring(jsonStart) : '{}';
      final decoded = json.decode(jsonPart);
      print("🔍 Décodage JSON depuis l'erreur : $decoded");

      if (decoded is Map<String, dynamic> &&
          decoded.containsKey("predicted_days_to_next_relapse") &&
          decoded.containsKey("predicted_next_relapse_date")) {
        relapsePrediction = decoded;
        predictionError = '';
        print("⚠️ Correction automatique depuis l'erreur JSON : $decoded");
      } else {
        predictionError = e.toString();
        print("❌ Le JSON ne contient pas les champs attendus.");
      }
    } catch (_) {
      predictionError = e.toString();
      print("❌ Impossible de parser l'erreur comme JSON.");
    }
  }

  isLoadingPrediction = false;
  notifyListeners();
  print("✅ Fin de la prédiction. isLoadingPrediction: $isLoadingPrediction");
}
}