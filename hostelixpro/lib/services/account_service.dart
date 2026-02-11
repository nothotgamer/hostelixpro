import 'package:hostelixpro/services/api_client.dart';

/// Account Service for self-service user operations
/// Profile update, password change, 2FA management
class AccountService {
  /// Get current user's profile
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await ApiClient.get('/account/profile');

    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to get profile');
    }

    return response.body;
  }

  /// Update profile (display_name, email)
  static Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? email,
    String? bio,
    String? skills,
    String? statusMessage,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (email != null) body['email'] = email;
    if (bio != null) body['bio'] = bio;
    if (skills != null) body['skills'] = skills;
    if (statusMessage != null) body['status_message'] = statusMessage;

    final response = await ApiClient.patch('/account/profile', body);

    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to update profile');
    }

    return response.body;
  }

  /// Change password
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await ApiClient.post('/account/password', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });

    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to change password');
    }
  }

  /// Setup 2FA - returns secret and QR code
  static Future<Map<String, String>> setup2FA() async {
    final response = await ApiClient.post('/account/2fa/setup', {});

    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to setup 2FA');
    }

    return {
      'secret': response.body['secret'],
      'qr_code': response.body['qr_code'],
    };
  }

  /// Verify 2FA code and enable 2FA
  static Future<void> verify2FA(String code) async {
    final response = await ApiClient.post('/account/2fa/verify', {'code': code});

    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Invalid verification code');
    }
  }

  /// Disable 2FA
  static Future<void> disable2FA(String password) async {
    final response = await ApiClient.post('/account/2fa/disable', {'password': password});

    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to disable 2FA');
    }
  }
}
