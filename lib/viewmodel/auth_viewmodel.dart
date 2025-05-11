import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/shared_prefs_service.dart';
import '../view/auth/otp_verification_page.dart';
import '../view/auth/reset_password_bottom_sheet.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final SharedPrefsService _prefsService = SharedPrefsService();

  bool isLoading = false;
  Map<String, dynamic>? userProfile;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: Platform.isIOS
        ? '815846323450-55fto74973fqkcfsaq9ajhfgkqkr8402.apps.googleusercontent.com'
        : Platform.isAndroid
        ? null
        : '815846323450-npr8cbi7b8n7c1op9pq5m1i570k21hh7.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
    forceCodeForRefreshToken: true,
    signInOption: SignInOption.standard,
  );

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await _googleSignIn.disconnect();
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Connexion annulée');

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      if (idToken == null) throw Exception('Google authentication failed: Missing ID token');

      final data = await _authRepository.googleLogin(idToken);
      if (data == null || !data.containsKey('token')) throw Exception('Token invalide reçu du backend');

      await _prefsService.saveTokens(data['token'], data['refreshToken'] ?? '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connexion Google réussie!')),
      );

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur d'authentification Google: $e")),
      );
    }
  }

  Future<void> login(BuildContext context, String email, String password) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      isLoading = true;
      notifyListeners();

      final data = await _authRepository.loginUser(email, password);
      if (data == null || !data.containsKey("token")) throw Exception("Invalid token received");

      await _prefsService.saveTokens(data["token"], data["refreshToken"] ?? '');
      await _prefsService.saveTokens(data['token'], data['refreshToken'] ?? '');
      await _prefsService.saveTokens(data['token'], data['refreshToken'] ?? '');

      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> isLoggedIn() async => await _prefsService.isLoggedIn();

  Future<bool> isTokenExpired() async {
    final tokenCreationTime = await _prefsService.getTokenCreationTime();
    final token = await _prefsService.getAccessToken();
    if (tokenCreationTime == null || token == null) return true;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    return (currentTime - tokenCreationTime) > 300000;
  }

  Future<void> refreshToken(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      isLoading = true;
      notifyListeners();

      final response = await _authRepository.refreshToken();
      await _prefsService.saveTokens(response["token"], response["refreshToken"]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.tokenRefreshedSuccessfully)),
      );
    } catch (e) {
      Navigator.pushReplacementNamed(context, "/login");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerUser(
      BuildContext context,
      String fullName,
      String email,
      String password,
      ) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      isLoading = true;
      notifyListeners();

      await _authRepository.registerUser(
        fullName: fullName,
        email: email,
        password: password,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.registrationSuccessful)),
      );

      Navigator.pushReplacementNamed(context, "/login");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendForgotPasswordRequest(BuildContext context, String email) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.pleaseEnterAnEmail)),
        );
        return;
      }

      isLoading = true;
      notifyListeners();

      await _authRepository.sendForgotPasswordRequest(email);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.registrationSuccessful)),
      );

      Navigator.pop(context);
      _showOTPBottomSheet(context, email);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(BuildContext context, String email, String otp) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      isLoading = true;
      notifyListeners();

      final response = await _authRepository.verifyOtp(email, otp);

      if (response.containsKey("message") &&
          response["message"] == "Code verified successfully") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.otpVerifiedSuccessfully)),
        );

        return true;
      }

      return false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur : $e")),
      );
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _showResetPasswordBottomSheet(BuildContext context, String email) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ResetPasswordBottomSheet(email: email),
    );
  }

  Future<void> resendOtp(BuildContext context, String email) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      await _authRepository.resendOtp(email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.resetCodeSentToYourEmail)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showOTPBottomSheet(BuildContext context, String email) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => OTPVerificationBottomSheet(email: email),
    );
  }

  Future<void> resetPassword(
      BuildContext context, String email, String newPassword) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      isLoading = true;
      notifyListeners();

      await _authRepository.resetPassword(email, newPassword);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.passwordResetSuccess)),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getProfile(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();
      userProfile = await _authRepository.getProfile();
      notifyListeners();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required BuildContext context,
    String? newName,
    String? newEmail,
    String? newBirthday,
    String? newGender,
    int? newPhone,
    String? newCareGiverEmail,
    int? newCareGiverPhone,
    String? newCareGiverName,
    String? newDiagnosis,
    String? newType,
    String? newMedicalReportPath,
  }) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      isLoading = true;
      notifyListeners();

      await _authRepository.updateProfile(
        newName: newName,
        newEmail: newEmail,
        newBirthday: newBirthday,
        newGender: newGender,
        newPhone: newPhone,
        newCareGiverEmail: newCareGiverEmail,
        newCareGiverPhone: newCareGiverPhone,
        newCareGiverName: newCareGiverName,
        newDiagnosis: newDiagnosis,
        newType: newType,
        newMedicalReportPath: newMedicalReportPath,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.profileUpdatedSuccessfully)),
      );
      Navigator.pushReplacementNamed(context, '/profile');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword({
    required BuildContext context,
    required String oldPassword,
    required String newPassword,
  }) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      isLoading = true;
      notifyListeners();

      await _authRepository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.registrationSuccessful)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateEmail({
    required BuildContext context,
    required String newEmail,
  }) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      isLoading = true;
      notifyListeners();

      await _authRepository.updateEmail(newEmail: newEmail);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.emailUpdatedSuccessfully)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool isProfileIncomplete() {
    final profile = userProfile;

    if (profile == null) return true;

    return (profile['fullName'] == null || profile['fullName'].toString().isEmpty) ||
        (profile['email'] == null || profile['email'].toString().isEmpty) ||
        (profile['birthday'] == null) ||
        (profile['gender'] == null || profile['gender'].toString().isEmpty) ||
        (profile['phone'] == null) ||
        (profile['careGiverEmail'] == null || profile['careGiverEmail'].toString().isEmpty) ||
        (profile['careGiverPhone'] == null) ||
        (profile['careGiverName'] == null || profile['careGiverName'].toString().isEmpty) ||
        (profile['diagnosis'] == null || profile['diagnosis'].toString().isEmpty) ||
        (profile['type'] == null || profile['type'].toString().isEmpty) ||
        (profile['medicalReport'] == null || profile['medicalReport'].toString().isEmpty);
  }

  Future<void> deleteProfile(BuildContext context) async {
    try {
      isLoading = true;
      notifyListeners();
      await _authRepository.deleteProfile();
      await _prefsService.clearAll();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}