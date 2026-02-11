import 'dart:convert';
import 'package:hostelixpro/models/audit_log.dart';
import 'package:hostelixpro/services/api_client.dart';
import 'package:http/http.dart' as http;

class AuditService {
  static const String _endpoint = '/audit';

  /// Get audit logs with filtering
  /// Returns `{logs: List<AuditLog>, total: int, pages: int}`
  static Future<Map<String, dynamic>> getAuditLogs({
    int page = 1,
    int perPage = 50,
    String? action,
    String? entity,
  }) async {
    final token = await ApiClient.getToken();
    if (token == null) throw Exception('Not authenticated');

    final queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (action != null && action.isNotEmpty) 'action': action,
      if (entity != null && entity.isNotEmpty) 'entity': entity,
    };

    final baseUrl = await ApiClient.getBaseUrl();
    final uri = Uri.parse('$baseUrl$_endpoint/')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: await ApiClient.getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> logsJson = data['logs'];
      
      return {
        'logs': logsJson.map((json) => AuditLog.fromJson(json)).toList(),
        'total': data['total'],
        'pages': data['pages'],
        'current_page': data['current_page'],
      };
    } else {
      throw Exception('Failed to load audit logs: ${response.body}');
    }
  }
}
