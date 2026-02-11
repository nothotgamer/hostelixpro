import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hostelixpro/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class FileService {
  /// Download file from API and open it
  static Future<void> downloadAndOpen(
    BuildContext context,
    String endpoint,
    String filename,
  ) async {
    try {
      // 1. Get tokens and headers
      final token = await ApiClient.getToken();
      if (token == null) throw Exception("Not authenticated");
      
      final headers = await ApiClient.getHeaders(token);
      
      // 2. Request file
      final baseUrl = await ApiClient.getBaseUrl();
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode != 200) {
        throw Exception("Download failed: ${response.statusCode}");
      }
      
      // 3. Get Storage Path
      // Android 11+ scoped storage makes external storage hard.
      // We use application documents or temporary directory.
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory(); // App specific external
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();
      
      final filePath = '${dir.path}/$filename';
      
      // 4. Write to file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      // 5. Open file
      final result = await OpenFile.open(filePath);
      
      if (result.type != ResultType.done) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open file: ${result.message}')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File saved to $filePath')),
          );
        }
      }
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
