import 'dart:convert';
import 'package:hostelixpro/models/backup_meta.dart';
import 'package:hostelixpro/services/api_client.dart';
import 'package:http/http.dart' as http;
// import 'dart:html' as html; // Only for web download, conditional import needed for mobile

class BackupService {
  static const String _endpoint = '/backups';

  /// List all backups
  static Future<List<BackupMeta>> getBackups() async {
    final token = await ApiClient.getToken();
    if (token == null) return [];

    final baseUrl = await ApiClient.getBaseUrl();
    final response = await http.get(
      Uri.parse('$baseUrl$_endpoint/'),
      headers: await ApiClient.getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => BackupMeta.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load backups');
    }
  }

  /// Create new backup
  /// Returns {backup: BackupMeta, key: String}
  static Future<Map<String, dynamic>> createBackup() async {
    final token = await ApiClient.getToken();
    if (token == null) throw Exception('Not authenticated');

    final baseUrl = await ApiClient.getBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl$_endpoint/'),
      headers: await ApiClient.getHeaders(token),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        'backup': BackupMeta.fromJson(data['backup']),
        'key': data['encryption_key'],
      };
    } else {
      throw Exception('Failed to create backup: ${response.body}');
    }
  }

  /// Download backup file
  /// Returns download URL
  static Future<String> getDownloadUrl(int id) async {
    final baseUrl = await ApiClient.getBaseUrl();
    return '$baseUrl$_endpoint/$id/download';
  }
  
  /// Restore backup (Verification)
  static Future<String> restoreBackup(int id, String key) async {
    final token = await ApiClient.getToken();
    if (token == null) throw Exception('Not authenticated');
    
    final baseUrl = await ApiClient.getBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl$_endpoint/restore'),
      headers: await ApiClient.getHeaders(token),
      body: jsonEncode({
        'backup_id': id,
        'key': key,
      }),
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['message'];
    } else {
      throw Exception(data['error'] ?? 'Restore failed');
    }
  }
}
