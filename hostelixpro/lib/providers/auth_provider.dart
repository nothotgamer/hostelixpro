// Authentication state provider
import 'package:flutter/material.dart';
import 'package:hostelixpro/services/auth_service.dart';
import 'package:hostelixpro/models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  
  /// Initialize - check if user is already authenticated
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final authenticated = await AuthService.isAuthenticated();
      
      if (authenticated) {
        // Get current user info
        _currentUser = await AuthService.getCurrentUser();
        _isAuthenticated = true;
      } else {
        _currentUser = null;
        _isAuthenticated = false;
      }
    } catch (e) {
      _currentUser = null;
      _isAuthenticated = false;
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  /// Login - Direct authentication
  Future<void> login(String email, String password) async {
    try {
      final data = await AuthService.login(email, password);
      
      // Parse user from response
      _currentUser = User.fromJson(data['user']);
      _isAuthenticated = true;
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Logout
  Future<void> logout() async {
    await AuthService.logout();
    
    _currentUser = null;
    _isAuthenticated = false;
    
    notifyListeners();
  }
  
  /// Refresh current user data
  Future<void> refreshUser() async {
    try {
      _currentUser = await AuthService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      // Ignore errors, keep current user
    }
  }
  
  /// Request password reset
  Future<String> forgotPassword(String email) async {
    try {
      return await AuthService.forgotPassword(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String txId, String otp, String newPassword) async {
    try {
      await AuthService.resetPassword(txId, otp, newPassword);
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user has specific role
  bool hasRole(String role) {
    return _currentUser?.hasRole(role) ?? false;
  }
}
