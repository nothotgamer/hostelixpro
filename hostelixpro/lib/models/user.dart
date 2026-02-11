// User model
class User {
  final int id;
  final String email;
  final String role;
  final String? displayName;
  final bool isLocked;
  final bool mfaEnabled;
  final int? lastLoginAt;
  final int createdAt;
  final int? updatedAt;
  final Map<String, dynamic>? studentProfile;
  final String? bio;
  final String? skills;
  final String? statusMessage;
  
  User({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
    required this.isLocked,
    required this.mfaEnabled,
    this.lastLoginAt,
    required this.createdAt,
    this.updatedAt,
    this.studentProfile,
    this.bio,
    this.skills,
    this.statusMessage,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      displayName: json['display_name'],
      isLocked: json['is_locked'] ?? false,
      mfaEnabled: json['mfa_enabled'] ?? true,
      lastLoginAt: json['last_login_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      studentProfile: json['student_profile'],
      bio: json['bio'],
      skills: json['skills'],
      statusMessage: json['status_message'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'display_name': displayName,
      'is_locked': isLocked,
      'mfa_enabled': mfaEnabled,
      'last_login_at': lastLoginAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'student_profile': studentProfile,
      'bio': bio,
      'skills': skills,
      'status_message': statusMessage,
    };
  }
  
  /// Check if user has specific role
  bool hasRole(String roleToCheck) {
    return role == roleToCheck;
  }
  
  /// Check if user is admin
  bool get isAdmin => role == 'admin';
  
  /// Check if user is teacher
  bool get isTeacher => role == 'teacher';
  
  /// Check if user is routine manager
  bool get isRoutineManager => role == 'routine_manager';
  
  /// Check if user is student
  bool get isStudent => role == 'student';
}
