// Generic HTTP client with authentication support
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  // Default Host for API (using ngrok for remote access)
  static const String defaultHost = 'http://127.0.0.1:3000';
  static const String apiPrefix = '/api/v1';
  
  // Storage keys
  static const String _hostKey = 'api_host_url';
  static const String _tokenKey = 'jwt_token';
  static const String _tokenExpiryKey = 'jwt_expiry';
  
  /// Get configured API host URL
  static Future<String> getHost() async {
    // Force default host for desktop usage, ignoring old preferences
    return defaultHost;
    /*
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_hostKey) ?? defaultHost;
    } catch (e) {
      debugPrint('Error getting host: $e');
      return defaultHost;
    }
    */
  }
  
  /// Update API host URL
  static Future<void> setHost(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Remove trailing slash and any trailing /api/v1
      var cleanUrl = url.trim();
      if (cleanUrl.endsWith('/')) {
        cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
      }
      if (cleanUrl.endsWith(apiPrefix)) {
        cleanUrl = cleanUrl.substring(0, cleanUrl.length - apiPrefix.length);
      }
      await prefs.setString(_hostKey, cleanUrl);
      debugPrint('API Host updated to: $cleanUrl');
    } catch (e) {
      debugPrint('Error setting host: $e');
    }
  }

  /// Get the full base URL (Host + Prefix)
  static Future<String> getBaseUrl() async {
    final host = await getHost();
    return '$host$apiPrefix';
  }
  
  /// Reset to default host
  static Future<void> resetHost() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hostKey);
      debugPrint('API Host reset to default');
    } catch (e) {
      debugPrint('Error resetting host: $e');
    }
  }

  /// Get stored JWT token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if token is expired
      final expiryStr = prefs.getString(_tokenExpiryKey);
      if (expiryStr != null) {
        final expiry = int.tryParse(expiryStr);
        if (expiry != null && DateTime.now().millisecondsSinceEpoch > expiry) {
          // Token expired, clear it
          await clearToken();
          return null;
        }
      }
      
      return prefs.getString(_tokenKey);
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }
  
  /// Store JWT token and expiry
  static Future<void> storeToken(String token, int expiryMs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_tokenExpiryKey, expiryMs.toString());
    } catch (e) {
      debugPrint('Error storing token: $e');
    }
  }
  
  /// Clear stored token
  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_tokenExpiryKey);
    } catch (e) {
      debugPrint('Error clearing token: $e');
    }
  }
  
  /// Public helper to get headers for external services
  static Future<Map<String, String>> getHeaders(String? token) async {
    final headers = {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true', // Skip ngrok landing page
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
  
  /// Build headers with authentication
  static Future<Map<String, String>> _buildHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true', // Skip ngrok landing page
    };
    
    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  /// POST request
  static Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _buildHeaders(includeAuth: includeAuth);
      final baseUrl = await getBaseUrl();
      final uri = Uri.parse('$baseUrl$endpoint');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      debugPrint('POST $uri: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      
      return ApiResponse(
        statusCode: response.statusCode,
        body: response.body.isNotEmpty ? jsonDecode(response.body) : null,
        success: response.statusCode >= 200 && response.statusCode < 300,
      );
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        body: {'error': 'Network error: ${e.toString()}'},
        success: false,
      );
    }
  }
  
  /// GET request
  static Future<ApiResponse> get(
    String endpoint, {
    bool includeAuth = true,
    Map<String, String>? queryParams,
  }) async {
    try {
      final headers = await _buildHeaders(includeAuth: includeAuth);
      final baseUrl = await getBaseUrl();
      var uri = Uri.parse('$baseUrl$endpoint');
      
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      
      final response = await http.get(uri, headers: headers);
      
      debugPrint('GET $uri: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      
      return ApiResponse(
        statusCode: response.statusCode,
        body: response.body.isNotEmpty ? jsonDecode(response.body) : null,
        success: response.statusCode >= 200 && response.statusCode < 300,
      );
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        body: {'error': 'Network error: ${e.toString()}'},
        success: false,
      );
    }
  }
  
  /// PATCH request
  static Future<ApiResponse> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _buildHeaders(includeAuth: includeAuth);
      final baseUrl = await getBaseUrl();
      final uri = Uri.parse('$baseUrl$endpoint');
      
      final response = await http.patch(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      debugPrint('PATCH $uri: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      
      return ApiResponse(
        statusCode: response.statusCode,
        body: response.body.isNotEmpty ? jsonDecode(response.body) : null,
        success: response.statusCode >= 200 && response.statusCode < 300,
      );
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        body: {'error': 'Network error: ${e.toString()}'},
        success: false,
      );
    }
  }
  
  /// DELETE request
  static Future<ApiResponse> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _buildHeaders(includeAuth: includeAuth);
      final baseUrl = await getBaseUrl();
      final uri = Uri.parse('$baseUrl$endpoint');
      
      final response = await http.delete(uri, headers: headers);
      
      debugPrint('DELETE $uri: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      
      return ApiResponse(
        statusCode: response.statusCode,
        body: response.body.isNotEmpty ? jsonDecode(response.body) : null,
        success: response.statusCode >= 200 && response.statusCode < 300,
      );
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        body: {'error': 'Network error: ${e.toString()}'},
        success: false,
      );
    }
  }

  /// POST Multipart request (File Upload)
  static Future<ApiResponse> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    required String fileField,
    required File file,
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _buildHeaders(includeAuth: includeAuth);
      headers.remove('Content-Type'); // Let MultipartRequest set the boundary
      
      final baseUrl = await getBaseUrl();
      final uri = Uri.parse('$baseUrl$endpoint');
      
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);
      
      // Add text fields
      fields.forEach((k, v) => request.fields[k] = v);
      
      // Add file
      if (file.existsSync()) {
        request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return ApiResponse(
        statusCode: response.statusCode,
        body: response.body.isNotEmpty ? jsonDecode(response.body) : null,
        success: response.statusCode >= 200 && response.statusCode < 300,
      );
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        body: {'error': 'Network error: ${e.toString()}'},
        success: false,
      );
    }
  }
}

/// API Response wrapper
class ApiResponse {
  final int statusCode;
  final dynamic body;
  final bool success;
  
  ApiResponse({
    required this.statusCode,
    required this.body,
    required this.success,
  });
  
  /// Get error message from response
  String? get errorMessage {
    if (success) return null;
    
    if (body is Map && body['error'] != null) {
      return body['error'].toString();
    }
    
    return 'Request failed with status $statusCode';
  }
}
