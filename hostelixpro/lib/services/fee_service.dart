import 'dart:io';
import 'package:hostelixpro/models/transaction.dart';
import 'package:hostelixpro/services/api_client.dart';
import 'package:hostelixpro/models/fee.dart';

class FeeService {
  /// Get list of fees
  static Future<List<Fee>> getFees({String? status}) async {
    String endpoint = '/fees';
    if (status != null) {
      endpoint += '?status=$status';
    }
    
    final response = await ApiClient.get(endpoint);
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to fetch fees');
    }
    
    final List<dynamic> list = response.body['fees'];
    return list.map((e) => Fee.fromJson(e)).toList();
  }
  
  static Future<Transaction> addTransaction({
    required int month,
    required int year,
    required String amount,
    String? proofPath,
    File? proofFile,
    String paymentMethod = 'manual',
    String? reference,
  }) async {
    String? finalProofPath = proofPath;

    // Upload proof if file provided
    if (proofFile != null) {
      final uploadResponse = await ApiClient.postMultipart(
        '/fees/upload-proof',
        fields: {},
        fileField: 'proof_file',
        file: proofFile,
      );
      
      if (!uploadResponse.success) {
        throw Exception(uploadResponse.errorMessage ?? 'Failed to upload proof');
      }
      
      finalProofPath = uploadResponse.body['path'];
    }

    final response = await ApiClient.post('/fees', {
      'month': month,
      'year': year,
      'amount': amount,
      'proof_path': finalProofPath,
      'payment_method': paymentMethod,
      'reference': reference,
    });
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to submit transaction');
    }
    
    return Transaction.fromJson(response.body);
  }
  
  static Future<void> approveTransaction(int id) async {
    final response = await ApiClient.post('/fees/transactions/$id/approve', {});
    if (!response.success) throw Exception(response.errorMessage);
  }

  static Future<void> rejectTransaction(int id, String reason) async {
    final response = await ApiClient.post('/fees/transactions/$id/reject', {'reason': reason});
    if (!response.success) throw Exception(response.errorMessage);
  }

  static Future<List<Transaction>> getTransactions(int feeId) async {
    final response = await ApiClient.get('/fees/$feeId/transactions');
    if (!response.success) throw Exception(response.errorMessage);
    
    final List<dynamic> list = response.body;
    return list.map((e) => Transaction.fromJson(e)).toList();
  }

  /// Get fee calendar
  static Future<List<dynamic>> getFeeCalendar({required int year, String? search}) async {
    String url = '/fees/calendar?year=$year';
    if (search != null && search.isNotEmpty) {
      url += '&search=$search';
    }
    final response = await ApiClient.get(url);
    if (!response.success) throw Exception(response.errorMessage);
    return response.body as List<dynamic>;
  }
}
