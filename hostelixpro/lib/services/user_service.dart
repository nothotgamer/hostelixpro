import 'package:hostelixpro/models/user.dart';
import 'package:hostelixpro/services/api_client.dart';

/// Service for user management (Admin only)
class UserService {
  
  /// Get all users
  /// Optional filters: role, isLocked
  static Future<List<User>> getUsers({String? role, bool? isLocked, bool? isApproved}) async {
    Map<String, String>? queryParams;
    
    if (role != null || isLocked != null || isApproved != null) {
      queryParams = {};
      if (role != null) queryParams['role'] = role;
      if (isLocked != null) queryParams['is_locked'] = isLocked.toString();
      if (isApproved != null) queryParams['is_approved'] = isApproved.toString();
    }
    
    final response = await ApiClient.get('/users', queryParams: queryParams);
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to load users');
    }
    
    final List<dynamic> usersJson = response.body['users'] ?? [];
    return usersJson.map((json) => User.fromJson(json)).toList();
  }

  /// Get students assigned to current teacher
  static Future<List<User>> getMyStudents() async {
    final response = await ApiClient.get('/users/my-students');
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to load students');
    }
    
    final List<dynamic> studentsJson = response.body['students'] ?? [];
    return studentsJson.map((json) => User.fromJson(json)).toList();
  }
  
  /// Get user by ID
  static Future<User> getUser(int id) async {
    final response = await ApiClient.get('/users/$id');
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to load user');
    }
    
    return User.fromJson(response.body);
  }
  
  /// Create new user
  static Future<User> createUser({
    required String email,
    required String password,
    required String role,
    String? displayName,
    String? admissionNo,
    String? room,
    int? assignedTeacherId,
    double? monthlyFeeAmount,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'role': role,
    };
    if (displayName != null) body['display_name'] = displayName;
    if (admissionNo != null) body['admission_no'] = admissionNo;
    if (room != null) body['room'] = room;
    if (assignedTeacherId != null) body['assigned_teacher_id'] = assignedTeacherId;
    if (monthlyFeeAmount != null) body['monthly_fee_amount'] = monthlyFeeAmount;
    
    final response = await ApiClient.post('/users', body);
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to create user');
    }
    
    return User.fromJson(response.body);
  }
  
  /// Update existing user
  static Future<User> updateUser(
    int userId, {
    String? email,
    String? displayName,
    String? role,
    bool? isLocked,
    String? admissionNo,
    String? room,
    int? assignedTeacherId,
    double? monthlyFeeAmount,
  }) async {
    final body = <String, dynamic>{};
    
    if (email != null) body['email'] = email;
    if (displayName != null) body['display_name'] = displayName;
    if (role != null) body['role'] = role;
    if (role != null) body['role'] = role;
    if (isLocked != null) body['is_locked'] = isLocked;
    
    // Student fields
    if (admissionNo != null) body['admission_no'] = admissionNo;
    if (room != null) body['room'] = room;
    if (assignedTeacherId != null) body['assigned_teacher_id'] = assignedTeacherId;
    if (monthlyFeeAmount != null) body['monthly_fee_amount'] = monthlyFeeAmount;
    
    final response = await ApiClient.patch('/users/$userId', body);
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to update user');
    }
    
    return User.fromJson(response.body);
  }
  
  /// Delete user
  static Future<void> deleteUser(int userId) async {
    final response = await ApiClient.delete('/users/$userId');
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to delete user');
    }
  }
  
  /// Lock/unlock user account
  static Future<bool> toggleLock(int userId, {bool? isLocked}) async {
    final body = isLocked != null ? {'is_locked': isLocked} : <String, dynamic>{};
    
    final response = await ApiClient.post('/users/$userId/lock', body);
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to toggle lock');
    }
    
    return response.body['is_locked'] ?? false;
  }

  /// Approve user and assign details
  static Future<void> approveUser({
    required int userId,
    required String admissionNo,
    required String room,
    required int assignedTeacherId,
    double? monthlyFeeAmount,
  }) async {
    final body = <String, dynamic>{
      'admission_no': admissionNo,
      'room': room,
      'assigned_teacher_id': assignedTeacherId,
    };
    if (monthlyFeeAmount != null) body['monthly_fee_amount'] = monthlyFeeAmount;
    
    final response = await ApiClient.post('/users/$userId/approve', body);
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to approve user');
    }
  }
  
  /// Get student profiles with role-based access
  static Future<Map<String, dynamic>> getStudentProfiles({int? year, int? month}) async {
    String endpoint = '/users/student-profiles';
    if (year != null && month != null) {
      endpoint += '?year=$year&month=$month';
    }
    
    final response = await ApiClient.get(endpoint);
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to load student profiles');
    }
    
    return {
      'students': response.body['students'] as List<dynamic>,
      'year': response.body['year'],
      'month': response.body['month'],
      'total': response.body['total'],
    };
  }
  
  /// Get detailed activities for a specific student
  static Future<Map<String, dynamic>> getStudentActivities(int studentId, {int? year, int? month}) async {
    String endpoint = '/users/student-profiles/$studentId/activities';
    if (year != null && month != null) {
      endpoint += '?year=$year&month=$month';
    }
    
    final response = await ApiClient.get(endpoint);
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to load activities');
    }
    
    return {
      'student_id': response.body['student_id'],
      'student_name': response.body['student_name'],
      'year': response.body['year'],
      'month': response.body['month'],
      'activities': response.body['activities'] as Map<String, dynamic>,
      'summary': response.body['summary'] as Map<String, dynamic>,
    };
  }
}
