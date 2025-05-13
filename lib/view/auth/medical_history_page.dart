import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodel/auth_viewmodel.dart';

class MedicalHistoryPage extends StatefulWidget {
  const MedicalHistoryPage({super.key});

  @override
  _MedicalHistoryPageState createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends State<MedicalHistoryPage> {
  String? selectedStage;
  final TextEditingController diagnosisController = TextEditingController();
  List<String> selectedFiles = [];

  @override
  void initState() {
    super.initState();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userProfile = authViewModel.userProfile;

    if (userProfile != null) {
      diagnosisController.text = userProfile['diagnosis'] ?? '';
      selectedStage = userProfile['type'];
      if (userProfile['medicalReport'] != null) {
        selectedFiles.add(userProfile['medicalReport'].toString().split('/').last);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    final authViewModel = Provider.of<AuthViewModel>(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
  resizeToAvoidBottomInset: true,
  backgroundColor: isDarkMode ? AppColors.primaryBlue : Colors.white,
  appBar: AppBar(
    title: Text(
      localizations.medicalHistory,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    centerTitle: true,
    backgroundColor: AppColors.primaryBlue,
    iconTheme: const IconThemeData(color: Colors.white),
    elevation: 0,
  ),
  body: GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(),
    child: Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100), // pour éviter l'écrasement du bouton
          child: Column(
            children: [
              _buildProfileHeader(localizations),
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                  vertical: MediaQuery.of(context).size.height * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(localizations.diagnosis, localizations.enterDiagnosis, diagnosisController, isDarkMode),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    _buildStageSelector(isDarkMode, localizations),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    _buildFilePicker(isDarkMode, localizations),
                    const SizedBox(height: 30),
                    _buildBottomButton(isDarkMode, localizations, authViewModel),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (authViewModel.isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    ),
  ),
),
    );
  }

  Widget _buildProfileHeader(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      color: AppColors.primaryBlue,
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            localizations.editMedicalHistory,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStageSelector(bool isDarkMode, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.type, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ["SEP-RR", "SEP-PS", "SEP-PP", "SEP-PR"]
              .map((stage) => _buildStageButton(stage, isDarkMode))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildStageButton(String stage, bool isDarkMode) {
    bool isSelected = selectedStage == stage;

    return GestureDetector(
      onTap: () => setState(() => selectedStage = stage),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : (isDarkMode ? Colors.grey[800] : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primaryBlue : Colors.grey),
        ),
        child: Text(
          stage,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildFilePicker(bool isDarkMode, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.reports, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles();
            if (result != null) {
              setState(() {
                selectedFiles.clear();
                selectedFiles.add(result.files.single.path!);
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.upload_file, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    selectedFiles.isEmpty
                        ? localizations.selectFile
                        : selectedFiles.map((f) => f.split('/').last).join(", "),
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(bool isDarkMode, AppLocalizations localizations, AuthViewModel authViewModel) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await authViewModel.updateProfile(
            context: context,
            newDiagnosis: diagnosisController.text.isNotEmpty ? diagnosisController.text : null,
            newType: selectedStage,
newMedicalReportPath: selectedFiles.isNotEmpty && selectedFiles.first.contains('/')
    ? selectedFiles.first
    : null,          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.02),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          localizations.edit,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}