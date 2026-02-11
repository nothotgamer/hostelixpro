// Report service
import 'package:hostelixpro/services/api_client.dart';
import 'package:hostelixpro/models/report.dart';

class ReportService {
  static Future<Report> createDailyReport() async {
    final response = await ApiClient.post('/reports', {});
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to submit report');
    }
    
    return Report.fromJson(response.body);
  }
  
  static Future<List<Report>> getReports({String? status}) async {
    String endpoint = '/reports';
    if (status != null) {
      endpoint += '?status=$status';
    }
    
    final response = await ApiClient.get(endpoint);
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to fetch reports');
    }
    
    final List<dynamic> list = response.body['reports'];
    return list.map((e) => Report.fromJson(e)).toList();
  }
  
  static Future<void> approveReport(int id) async {
    final response = await ApiClient.post('/reports/$id/approve', {});
    if (!response.success) throw Exception(response.errorMessage);
  }
  
  static Future<void> rejectReport(int id, String reason) async {
    final response = await ApiClient.post('/reports/$id/reject', {'notes': reason});
    if (!response.success) throw Exception(response.errorMessage);
  }
}
