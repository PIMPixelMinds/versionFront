import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import 'shared_prefs_service.dart';
import 'package:http_parser/http_parser.dart';

class AuthRepository {
  final SharedPrefsService _prefsService = SharedPrefsService();
  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
  void _ensureAuthenticated(String? token) {
    if (token == null || token.isEmpty) {
      throw Exception('User not authenticated');
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final url = Uri.parse(ApiConstants.loginEndpoint);

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email.trim(),
        "password": password.trim(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"] ?? "Login failed");
    }
  }

  Future<Map<String, dynamic>?> googleLogin(String googleToken) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/auth/google/login');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": googleToken}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        final accessToken = responseData['token'];
        final refreshToken = responseData['refreshToken'] ?? '';

        if (accessToken != null && accessToken.isNotEmpty) {
          await _prefsService.saveTokens(accessToken, refreshToken);
          print("✅ Tokens saved after Google login");
        }

        return responseData;
      } else {
        throw Exception(
          jsonDecode(response.body)["message"] ?? "Google login failed",
        );
      }
    } catch (e) {
      throw Exception("Google login error: $e");
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    final refreshToken = await _prefsService.getRefreshToken();
    if (refreshToken == null) throw Exception('No refresh token found');

    final url = Uri.parse('${ApiConstants.baseUrl}/auth/refresh-token');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $refreshToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          jsonDecode(response.body)['message'] ?? 'Failed to refresh token');
    }
  }

  Future<Map<String, dynamic>?> registerUser(
      {required String fullName,
      required String email,
      required String password,
      required String? fcmToken}) async {
    final url = Uri.parse(ApiConstants.signupEndpoint);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": fullName.trim(),
          "email": email.trim(),
          "password": password.trim(),
          "fcmToken": fcmToken ?? "",
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            jsonDecode(response.body)["message"] ?? "Registration failed");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  Future<Map<String, dynamic>> sendForgotPasswordRequest(String email) async {
    final url = Uri.parse(ApiConstants.forgotPasswordEndpoint);

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          jsonDecode(response.body)["message"] ?? "Something went wrong");
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final url = Uri.parse(ApiConstants.verifyOtpEndpoint);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "resetCode": otp}),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseBody;
      } else {
        throw Exception(responseBody["message"] ?? "Invalid OTP");
      }
    } catch (e) {
      throw Exception("API error: $e");
    }
  }

  Future<void> resendOtp(String email) async {
    final url = Uri.parse("${ApiConstants.resendOtpEndpoint}/$email");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to resend OTP");
    }
  }

  Future<void> resetPassword(String email, String newPassword) async {
    final url = Uri.parse("${ApiConstants.resetPasswordEndpoint}/$email");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "newPassword": newPassword.trim(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          jsonDecode(response.body)["message"] ?? "Failed to reset password");
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final token = await _getToken();
    final url = Uri.parse(ApiConstants.getProfileEndpoint);

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          jsonDecode(response.body)["message"] ?? "Failed to fetch profile");
    }
  }

  Future<Map<String, dynamic>> updateProfile({
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
    final token = await _getToken();
    final url = Uri.parse(ApiConstants.updateProfileEndpoint);

    var request = http.MultipartRequest('PUT', url)
      ..headers['Authorization'] = 'Bearer $token';

    if (newName != null) request.fields['newName'] = newName;
    if (newEmail != null) request.fields['newEmail'] = newEmail;
    if (newBirthday != null) request.fields['newBirthday'] = newBirthday;
    if (newGender != null) request.fields['newGender'] = newGender;
    if (newPhone != null) request.fields['newPhone'] = newPhone.toString();
    if (newCareGiverEmail != null)
      request.fields['newCareGiverEmail'] = newCareGiverEmail;
    if (newCareGiverPhone != null)
      request.fields['newCareGiverPhone'] = newCareGiverPhone.toString();
    if (newCareGiverName != null)
      request.fields['newCareGiverName'] = newCareGiverName;
    if (newDiagnosis != null) request.fields['newDiagnosis'] = newDiagnosis;
    if (newType != null) request.fields['newType'] = newType;

    if (newMedicalReportPath != null) {
      final fileName = newMedicalReportPath.split('/').last.toLowerCase();
      MediaType contentType;

      if (fileName.endsWith('.png')) {
        contentType = MediaType('image', 'png');
      } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
        contentType = MediaType('image', 'jpeg');
      } else if (fileName.endsWith('.gif')) {
        contentType = MediaType('image', 'gif');
      } else if (fileName.endsWith('.pdf')) {
        contentType = MediaType('application', 'pdf');
      } else if (fileName.endsWith('.txt')) {
        contentType = MediaType('text', 'plain');
      } else if (fileName.endsWith('.docx')) {
        contentType = MediaType('application',
            'vnd.openxmlformats-officedocument.wordprocessingml.document');
      } else {
        contentType = MediaType('application', 'octet-stream');
      }

      request.files.add(await http.MultipartFile.fromPath(
        'newMedicalReport',
        newMedicalReportPath,
        contentType: contentType,
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          jsonDecode(response.body)["message"] ?? "Failed to update profile");
    }
  }

  Future<Map<String, dynamic>> completeProfile(
      Map<String, dynamic> profileData) async {
    final token = await _getToken();
    final url = Uri.parse(ApiConstants.completeProfileEndpoint);

    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(profileData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to complete profile: ${response.body}");
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await _getToken();
    final url = Uri.parse(ApiConstants.changePasswordEndpoint);

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "oldPassword": oldPassword,
        "newPassword": newPassword,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          jsonDecode(response.body)["message"] ?? "Failed to change password");
    }
  }

  Future<void> updateEmail({
    required String newEmail,
  }) async {
    final token = await _getToken();
    final url = Uri.parse(ApiConstants.updateProfileEndpoint);

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "newEmail": newEmail,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          jsonDecode(response.body)["message"] ?? "Failed to update email");
    }
  }

  Future<void> deleteProfile() async {
    final token = await _getToken();
    final url = Uri.parse(ApiConstants.deleteProfileUrl);

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final responseBody = jsonDecode(response.body);
      throw Exception(responseBody['message'] ?? 'Failed to delete profile');
    }
  }

  Future<String> _getToken() async {
    final token = await _prefsService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No token found');
    }
    return token;
  }

  Future<Map<String, dynamic>?> appleLogin(String identityToken) async {
    final url = Uri.parse(ApiConstants.appleLoginEndpoint);
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"identityToken": identityToken}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        await SharedPrefsService().saveTokens(
          responseData['token'],
          responseData['refreshToken'] ?? '',
        );
        return responseData;
      } else {
        throw Exception(
            'Apple login failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception("Apple login error: $e");
    }
  }

  //Verify Email
  Future<Map<String, dynamic>> sendVerifyEmail(
      {required String token, required String email}) async {
    final url = Uri.parse(ApiConstants.verifyEmailEndpoint);

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          jsonDecode(response.body)["message"] ?? "Something went wrong");
    }
  }

  /********************************/

  Future<Map<String, dynamic>> verifyEmailOtp(String email, String otp) async {
    final url = Uri.parse(ApiConstants.verifyEmailOtpEndpoint);
    print("🔵 Appel API : $url avec email=$email et otp=$otp");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "resetCode": otp}),
      );

      print("🔵 Réponse HTTP Status : ${response.statusCode}");
      print("🔵 Réponse HTTP Body : ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ OTP validé avec succès !");
        return responseBody; // ✅ Retourner directement la réponse en cas de succès
      } else {
        throw Exception(responseBody["message"] ?? "Invalid OTP");
      }
    } catch (e) {
      print("❌ Erreur API : $e");
      throw Exception("Erreur de connexion à l'API : $e");
    }
  }

  Future<String> getMyUserId() async {
    final token = await _getToken();
    _ensureAuthenticated(token);
    final url = Uri.parse(ApiConstants.getMyUserId);

    final response = await http.get(
      url,
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['user'];
    } else {
      throw Exception('Failed to fetch userId');
    }
  }

  Future<void> clearFcmToken(String fullName) async {
    final response = await http.put(
      Uri.parse(ApiConstants.updateAuthFcmTokenEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': await _getToken(),
      },
      body: jsonEncode({
        'fullName': fullName,
        'fcmToken': "",
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to clear FCM token');
    }
  }

  Future<void> generateFcmToken(String email, String? fcmToken) async {
    final response = await http.put(
      Uri.parse(ApiConstants.updateAuthFcmTokenByEmailEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': await _getToken(),
      },
      body: jsonEncode({
        'email': email,
        'fcmToken': fcmToken ?? "",
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update FCM token');
    }
  }
}
