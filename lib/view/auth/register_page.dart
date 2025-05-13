import 'package:flutter/material.dart';
import 'package:pim/view/notifications/notification_firebase_api.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodel/auth_viewmodel.dart';
import 'login_page.dart';
import 'terms_and_privacy_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authViewModel = Provider.of<AuthViewModel>(context);
    final localizations = AppLocalizations.of(context)!;
    final height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height - 100),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(),
                    Expanded(
  child: Center(
    child: Text(
      localizations.signUpToGetStarted,
      style: const TextStyle(fontSize: 16),
      textAlign: TextAlign.center,
    ),
  ),
),
                    const SizedBox(height: 20),
                    _buildTextField(localizations.fullName, localizations.enterFullName, fullnameController, false, isDarkMode),
                    const SizedBox(height: 15),
                    _buildTextField(localizations.emailLabel, localizations.enterYourEmail, emailController, false, isDarkMode),
                    const SizedBox(height: 15),
                    _buildTextField(localizations.passwordLabel, localizations.enterYourPassword, passwordController, true, isDarkMode),
                    const SizedBox(height: 10),
                    _buildTermsRow(context, isDarkMode, localizations),
                    const SizedBox(height: 10),
                    authViewModel.isLoading
                        ? const CircularProgressIndicator()
                        : _buildRegisterButton(authViewModel, localizations),
                    const Spacer(),
                    _buildLoginRow(context, localizations),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, bool isPassword, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            suffixIcon: isPassword ? const Icon(Icons.visibility_off, color: Colors.grey) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsRow(BuildContext context, bool isDarkMode, AppLocalizations localizations) {
    return Row(
      children: [
        Checkbox(
          value: isChecked,
          onChanged: (value) => setState(() => isChecked = value!),
        ),
        Expanded(
          child: Wrap(
            children: [
              Text(localizations.agreeTo),
              GestureDetector(
                onTap: () => _showTermsDialog(context, isDarkMode, localizations),
                child: Text(
                  localizations.termsAndPrivacy,
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showTermsDialog(BuildContext context, bool isDarkMode, AppLocalizations localizations) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        localizations.termsAndPrivacy,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              setState(() => isChecked = true); // ⬅️ coche le checkbox
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TermsAndPrivacyPage(titleKey: 'termsAndConditions'),
                ),
              );
            },
            splashColor: Colors.blue.withOpacity(0.3),
            child: ListTile(
              title: Text(
                localizations.termsAndConditions,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() => isChecked = true); // ⬅️ coche aussi ici
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TermsAndPrivacyPage(titleKey: 'privacyPolicy'),
                ),
              );
            },
            splashColor: Colors.blue.withOpacity(0.3),
            child: ListTile(
              title: Text(
                localizations.privacyPolicy,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            localizations.cancel,
            style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildRegisterButton(AuthViewModel authViewModel, AppLocalizations localizations) {
    return ElevatedButton(
      onPressed: isChecked
          ? () async {
              final fullName = fullnameController.text.trim();
              final email = emailController.text.trim();
              final password = passwordController.text.trim();
              await authViewModel.registerUser(context, fullName, email, password);
            }
          : null,
      style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                    if (states.contains(WidgetState.disabled)) {
                      return AppColors.primaryBlue.withOpacity(0.7);
                    }
                    if (states.contains(WidgetState.pressed)) {
                      return AppColors.primaryBlue.withOpacity(0.9);
                    }
                    return AppColors.primaryBlue;
                  },
                ),
                minimumSize: WidgetStateProperty.all<Size>(
                    const Size(double.infinity, 50)),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                overlayColor: WidgetStateProperty.all<Color>(
                  AppColors.primaryBlue.withOpacity(0.2),
                ),
                shadowColor:
                WidgetStateProperty.all<Color>(Colors.transparent),
              ),
      child: Text(localizations.register, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildLoginRow(BuildContext context, AppLocalizations localizations) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(localizations.alreadyHaveAccount, style: const TextStyle(color: Colors.grey)),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
          child: Text(localizations.login, style: const TextStyle(color: AppColors.primaryBlue)),
        ),
      ],
    );
  }
}
