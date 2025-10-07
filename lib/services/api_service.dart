import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer';

// The main service class for all API interactions
class ApiService {
  // 💡 IMPORTANT: Base URL of your Django backend. Change this if using a physical device!
  // 'http://10.0.2.2:8000' is correct for an Android Emulator to reach the host machine.
  static const String _baseUrl = 'http://192.168.1.4:8000';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // --- API UTILITIES ---
  Map<String, String> get _publicHeaders => {
        'Content-Type': 'application/json',
      };

// Secure Storage instance

  Future<Map<String, String>> get _authHeaders async {
    // 💡 This is where the token is READ from the secure storage.
    final token = await _storage.read(key: 'jwt_access_token');

    return {
      'Content-Type': 'application/json',
      // The token is included in the 'Authorization' header if it exists.
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 1. Helper function to ensure the phone number is in E.164 format (+91...)
  // This is centralized here, so all screens use the same logic.
  String standardizePhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.startsWith('+')) {
      return cleanPhone; // Already standardized, e.g., "+91..."
    }
    // Assuming 10 digits means an Indian number without a country code
    if (cleanPhone.length == 10 && RegExp(r'^\d{10}$').hasMatch(cleanPhone)) {
      return '+91$cleanPhone';
    }
    // If it doesn't match a standard format, return empty string for validation failure
    return '';
  }

  // ----------------------------------------------------------------
  // 2. REGISTER (Request OTP)
  // ----------------------------------------------------------------
  Future<String?> requestRegistrationOtp({required String phoneNumber}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/send-otp/'),
        headers: _publicHeaders,
        body: jsonEncode({'phone_number': phoneNumber}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // Success
      } else {
        final errorData = json.decode(response.body);
        return errorData['error'] ?? 'Failed to request OTP.';
      }
    } catch (e) {
      log('Request OTP Network Error: $e');
      return 'Network Error: Could not reach server.';
    }
  }

  // ----------------------------------------------------------------
  // 3. VERIFY OTP & COMPLETE REGISTRATION
  // ----------------------------------------------------------------
  Future<String?> completeRegistration({
    required String phoneNumber,
    required String password,
    required String name,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/register/'),
        headers: _publicHeaders,
        body: jsonEncode({
          'phone_number': phoneNumber,
          'password': password,
          'name': name,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        // Store the JWT token for future authenticated calls
        await _storage.write(key: 'jwt_access_token', value: data['token']);
        return null; // Success
      } else {
        final errorData = json.decode(response.body);
        return errorData['error'] ?? 'Registration failed.';
      }
    } catch (e) {
      log('Registration Network Error: $e');
      return 'Network Error: Could not reach server.';
    }
  }

  // ----------------------------------------------------------------
  // 4. LOGIN (Authenticate User)
  // ----------------------------------------------------------------
  Future<String?> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/token/'),
        headers: _publicHeaders,
        body: jsonEncode({
          'phone_number': phoneNumber,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Store the JWT token
        await _storage.write(
            key: 'jwt_access_token', value: data['access'] ?? data['token']);

        return null; // Success
      } else {
        final errorData = json.decode(response.body);
        return errorData['error'] ?? 'Login failed.';
      }
    } catch (e) {
      log('Login Network Error: $e');
      return 'Network Error: Could not reach server.';
    }
  }

  // ----------------------------------------------------------------
  // 5. ADD EMERGENCY CONTACT
  // ----------------------------------------------------------------
  // Inside ApiService in api_service.dart (You need to verify/implement this)
  Future<String?> addEmergencyContact({
    required String name,
    required String phone,
  }) async {
    final token = await _storage.read(key: 'jwt_access_token');
    print('🔑 Stored token: $token');

    final headers = await _authHeaders;

    if (!headers.containsKey('Authorization')) {
      return 'Authentication token missing. Please log in again.'; // <-- Critical check
    }

    try {
      await http.post(
        Uri.parse('$_baseUrl/api/contacts/'), // Assuming this endpoint
        headers: headers,
        body: jsonEncode({
          'name': name,
          'phone_number': phone,
        }),
      );
      // ... rest of success/failure logic
    } catch (e) {
      // ...
      return 'Network Error: Could not reach server.';
    }
    return null;
  }

// ----------------------------------------------------------------
// 5. FORGOT PASSWORD: Request OTP (Add this function)
// ----------------------------------------------------------------
  Future<String?> requestPasswordResetOtp(
    String phoneNumber,
    Type string,
  ) async {
    try {
      final response = await http.post(
        // NOTE: Ensure this URL matches your Django endpoint (e.g., /api/password-reset/request/ or /api/forgot-password/request-otp/)
        Uri.parse('$_baseUrl/api/forgot-password/request-otp/'),
        headers: _publicHeaders,
        body: jsonEncode({
          'phone_number': phoneNumber,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success. Backend initiated OTP (or printed it to console if DEBUG=True)
        return null;
      } else {
        String errorMessage = 'Request failed: Status ${response.statusCode}.';
        try {
          final errorData = json.decode(response.body);
          // Extract a meaningful error message from the JSON response
          if (errorData.containsKey('phone_number')) {
            errorMessage =
                errorData['phone_number'][0]; // Common Django error format
          } else if (errorData.containsKey('detail')) {
            errorMessage = errorData['detail']; // General API error detail
          } else {
            errorMessage = 'Server error: ${errorData.toString()}';
          }
        } catch (e) {
          log('OTP Request Response Error: ${response.body}');
        }
        return errorMessage;
      }
    } catch (e) {
      log('OTP Request Network Error: $e');
      return 'Network error: Could not connect to the server.';
    }
  }

// ... (other functions like verifyPasswordResetOtp, sendSosAlert, etc.)
  // ----------------------------------------------------------------
  // 7. PASSWORD RESET (Verify OTP and Reset Password)
  // ----------------------------------------------------------------
  Future<String?> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/password_reset/'),
        headers: _publicHeaders,
        body: jsonEncode({
          'phone_number': phoneNumber,
          'otp': otp,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        final errorData = json.decode(response.body);
        return errorData['error'] ?? 'Password reset failed.';
      }
    } catch (e) {
      log('Password Reset Network Error: $e');
      return 'Network Error: Could not reach server.';
    }
  }

  // ----------------------------------------------------------------
  // 8. SEND SOS ALERT
  // ----------------------------------------------------------------
  Future<String?> sendSosAlert({
    required double latitude,
    required double longitude,
  }) async {
    final headers = await _authHeaders;

    if (!headers.containsKey('Authorization')) {
      return 'Authentication token missing. Please log in again.';
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/alert/'),
        headers: headers,
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // Success
      } else {
        String errorMessage = 'SOS failed: Status ${response.statusCode}.';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData.toString();
        } catch (e) {
          log('SOS Response Error: ${response.body}');
        }
        return errorMessage;
      }
    } catch (e) {
      log('SOS Network Error: $e');
      return 'SOS Network Error: Could not reach server. $e';
    }
  }

  // ----------------------------------------------------------------
  // 9. LOGOUT (Clear Token)
  // ----------------------------------------------------------------
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_access_token');
    log('User logged out. JWT token cleared.');
  }

  Future loginUser(String phoneNumber, String password) async {}
}
