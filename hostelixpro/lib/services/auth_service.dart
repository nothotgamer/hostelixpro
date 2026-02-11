// Authentication service for login and OTP verification
import 'package:hostelixpro/services/api_client.dart';
import 'package:hostelixpro/models/user.dart';
import 'package:hostelixpro/models/auth_response.dart';

class AuthService {
  /// Step 1: Login with email and password
  /// Returns login response with token and user
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiClient.post(
      '/auth/login',
      {
        'email': email,
        'password': password,
      },
      includeAuth: false,
    );
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Login failed');
    }
    
    final data = response.body; // Expects {token: ..., user: ...}
    
    // Store token
    if (data['token'] != null) {
      await ApiClient.storeToken(data['token'], data['expires_at'] ?? 0);
    }
    
    return data;
  }

  /// Step 0: Register new account
  static Future<Map<String, dynamic>> register(String email, String password, String displayName) async {
    final response = await ApiClient.post(
      '/auth/register',
      {
        'email': email,
        'password': password,
        'display_name': displayName,
      },
      includeAuth: false,
    );
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Registration failed');
    }
    
    return response.body;
  }
  
  /// Step 2: Verify OTP
  /// Returns JWT token and user data
  static Future<OtpVerifyResponse> verifyOtp(String txId, String otp) async {
    final response = await ApiClient.post(
      '/auth/verify-otp',
      {
        'tx_id': txId,
        'otp': otp,
      },
      includeAuth: false,
    );
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'OTP verification failed');
    }
    
    final data = OtpVerifyResponse.fromJson(response.body);
    
    // Store token
    await ApiClient.storeToken(data.token, data.expiresAt);
    
    return data;
  }
  
  /// Logout and clear token
  static Future<void> logout() async {
    // Call logout endpoint (optional, for audit logging)
    try {
      await ApiClient.post('/auth/logout', {});
    } catch (e) {
      // Ignore errors, clear token anyway
    }
    
    // Clear stored token
    await ApiClient.clearToken();
  }
  
  /// Get current authenticated user
  static Future<User> getCurrentUser() async {
    final response = await ApiClient.get('/auth/me');
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to get user info');
    }
    
    return User.fromJson(response.body);
  }
  
  /// Check if user is authenticated (has valid token)
  static Future<bool> isAuthenticated() async {
    final token = await ApiClient.getToken();
    return token != null;
  }

  /// Request password reset OTP
  /// Returns transaction ID
  static Future<String> forgotPassword(String email) async {
    final response = await ApiClient.post(
      '/auth/forgot-password',
      {'email': email},
      includeAuth: false,
    );
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to request password reset');
    }
    
    return response.body['tx_id'];
  }
  
  /// Reset password with OTP
  static Future<void> resetPassword(String txId, String otp, String newPassword) async {
    final response = await ApiClient.post(
      '/auth/reset-password',
      {
        'tx_id': txId,
        'otp': otp,
        'new_password': newPassword,
      },
      includeAuth: false,
    );
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to reset password');
    }
  }
}
