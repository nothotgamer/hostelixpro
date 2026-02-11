import 'package:hostelixpro/services/api_client.dart';
import 'package:hostelixpro/models/routine.dart';

class RoutineService {
  /// Get list of routines
  static Future<List<Routine>> getRoutines({String? status}) async {
    String endpoint = '/routines';
    if (status != null) {
      endpoint += '?status=$status';
    }
    
    final response = await ApiClient.get(endpoint);
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to fetch routines');
    }
    
    final List<dynamic> list = response.body['routines'];
    return list.map((e) => Routine.fromJson(e)).toList();
  }
  
  static Future<void> approveRoutine(int id) async {
    final response = await ApiClient.post('/routines/$id/approve', {});
    if (!response.success) throw Exception(response.errorMessage);
  }
  
  static Future<void> confirmReturn(int id) async {
    final response = await ApiClient.post('/routines/$id/confirm-return', {});
    if (!response.success) throw Exception(response.errorMessage);
  }

  /// Create a walk or exit request
  static Future<Routine> createRequest(String type, {Map<String, dynamic>? payload}) async {
    final response = await ApiClient.post('/routines', {
      'type': type,
      'payload': payload,
    });
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to create request');
    }
    
    return Routine.fromJson(response.body);
  }
  
  /// Student requests return
  static Future<Routine> requestReturn(int routineId) async {
    final response = await ApiClient.post('/routines/$routineId/return', {});
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to request return');
    }
    
    return Routine.fromJson(response.body);
  }
  
  /// Manager rejects request
  static Future<void> rejectRoutine(int id, String reason) async {
    final response = await ApiClient.post('/routines/$id/reject', {'reason': reason});
    if (!response.success) throw Exception(response.errorMessage ?? 'Failed to reject');
  }
  
  /// Get routine stats for manager dashboard
  static Future<Map<String, int>> getStats() async {
    final response = await ApiClient.get('/routines/stats');
    if (!response.success) throw Exception(response.errorMessage ?? 'Failed to fetch stats');
    
    return {
      'pending': response.body['pending_count'] ?? 0,
      'currentlyOut': response.body['currently_out'] ?? 0,
      'lateReturns': response.body['late_returns'] ?? 0,
    };
  }
  
  /// Get currently out students
  static Future<List<Routine>> getCurrentlyOut() async {
    final response = await ApiClient.get('/routines/currently-out');
    if (!response.success) throw Exception(response.errorMessage ?? 'Failed to fetch');
    
    final List<dynamic> list = response.body['routines'];
    return list.map((e) => Routine.fromJson(e)).toList();
  }
  
  /// Get activities calendar for admin
  static Future<Map<String, dynamic>> getCalendar(int year, int month) async {
    final response = await ApiClient.get('/routines/calendar?year=$year&month=$month');
    if (!response.success) throw Exception(response.errorMessage ?? 'Failed to fetch calendar');
    
    return {
      'year': response.body['year'],
      'month': response.body['month'],
      'activities': response.body['activities'] as Map<String, dynamic>,
      'summary': response.body['summary'] as Map<String, dynamic>,
    };
  }
}
