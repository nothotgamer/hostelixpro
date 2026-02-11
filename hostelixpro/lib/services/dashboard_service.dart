import 'package:hostelixpro/services/api_client.dart';

class DashboardService {
  static Future<Map<String, dynamic>> getStats() async {
    final response = await ApiClient.get('/dashboard/stats');
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to load stats');
    }
    
    return response.body;
  }
  
  /// Get daily student data for teacher dashboard
  static Future<Map<String, dynamic>> getTeacherStudentsDaily() async {
    final response = await ApiClient.get('/dashboard/teacher/students-daily');
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to load daily students');
    }
    
    return response.body;
  }
  
  /// Get daily overview for routine manager dashboard
  static Future<Map<String, dynamic>> getRoutineManagerOverview() async {
    final response = await ApiClient.get('/dashboard/routine-manager/daily-overview');
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to load overview');
    }
    
    return response.body;
  }
}

