import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pim/core/constants/app_colors.dart';
import 'package:pim/viewmodel/healthTracker_viewmodel.dart';

class MSNQTestPage extends StatefulWidget {
  const MSNQTestPage({super.key});

  @override
  _MSNQTestPageState createState() => _MSNQTestPageState();
}

class _MSNQTestPageState extends State<MSNQTestPage> {
  final Map<String, bool> _answers = {};
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;
  bool _isLoading = true;
  VoidCallback? onComplete;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializePage());
  }

  Future<void> _initializePage() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && args['onComplete'] != null) {
      onComplete = args['onComplete'];
    }

    final viewModel = Provider.of<HealthTrackerViewModel>(context, listen: false);

    try {
      if (viewModel.questions.isEmpty) {
        await viewModel.fetchQuestions(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
  content: Text(AppLocalizations.of(context)!.loadingError(e.toString())),
)
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitAnswers() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    final viewModel = Provider.of<HealthTrackerViewModel>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    try {
      if (_answers.length != viewModel.questions.length) {
        throw Exception(localizations.completeAllQuestions);
      }

      final formattedAnswers = _answers.entries.map((entry) => {
            'questionId': entry.key,
            'answer': entry.value ? 'Yes' : 'No',
          }).toList();

      viewModel.answers = Map.fromEntries(
        formattedAnswers.map((e) => MapEntry(e['questionId']!, e['answer'] == 'Yes')),
      );

      await viewModel.submitQuestionnaire(context);
      await viewModel.checkQuestionnaireAvailability();

      if (onComplete != null) {
        onComplete!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.submitSuccess)),
        );

        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.submitFailed}: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HealthTrackerViewModel>(context);
    final localizations = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.msnqTestTitle),
        backgroundColor: AppColors.primaryBlue,
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
      body: _buildBody(viewModel, localizations, isDarkMode),
    );
  }

  Widget _buildBody(HealthTrackerViewModel viewModel, AppLocalizations localizations, bool isDarkMode) {
    if (_isLoading || viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.questionnaireError != null) {
      return Center(child: Text(viewModel.questionnaireError!));
    }

    if (viewModel.questions.isEmpty) {
      return Center(child: Text(localizations.noQuestionsAvailable));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: viewModel.questions.length,
            itemBuilder: (context, index) => _buildQuestionItem(viewModel, index, isDarkMode),
          ),
        ),
        _buildSubmitButton(viewModel, localizations),
      ],
    );
  }

  Widget _buildQuestionItem(HealthTrackerViewModel viewModel, int index, bool isDarkMode) {
  final question = viewModel.questions[index];
  final questionId = question['_id'];

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
    ),
    elevation: 0,
    color: Theme.of(context).cardColor,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Q${index + 1}: ${question['text']}",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: Text(AppLocalizations.of(context)!.yes),
                  value: true,
                  groupValue: _answers[questionId],
                  activeColor: AppColors.primaryBlue, // ✅ Couleur sélectionnée
                  onChanged: (value) {
                    setState(() => _answers[questionId] = value!);
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: Text(AppLocalizations.of(context)!.no),
                  value: false,
                  groupValue: _answers[questionId],
                  activeColor: AppColors.primaryBlue, // ✅ Couleur sélectionnée
                  onChanged: (value) {
                    setState(() => _answers[questionId] = value!);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSubmitButton(HealthTrackerViewModel viewModel, AppLocalizations localizations) {
  final isReadyToSubmit = _answers.length == viewModel.questions.length && !_isSubmitting;

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: ElevatedButton(
      onPressed: isReadyToSubmit ? _submitAnswers : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white, // ✅ texte en blanc
        minimumSize: const Size.fromHeight(50),
        textStyle: const TextStyle(fontSize: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(localizations.submit),
    ),
  );
}

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
