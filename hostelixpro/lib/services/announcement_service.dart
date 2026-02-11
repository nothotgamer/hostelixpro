import 'package:hostelixpro/models/announcement.dart';
import 'package:hostelixpro/services/api_client.dart';

class AnnouncementService {
  static const String _endpoint = '/announcements';
  
  /// Get all visible announcements
  static Future<List<Announcement>> getAnnouncements() async {
    final response = await ApiClient.get(_endpoint);
    
    if (response.success) {
      try {
        final List<dynamic> data = response.body;
        return data.map((json) => Announcement.fromJson(json)).toList();
      } catch (e) {
        throw Exception('Failed to parse announcements: $e');
      }
    } else {
      throw Exception(response.errorMessage ?? 'Failed to load announcements');
    }
  }
  
  /// Create a new announcement (Admin/Teacher/Manager)
  static Future<Announcement> createAnnouncement({
    required String title,
    required String content,
    String priority = 'normal',
    String? targetRole,
    String announcementType = 'general', // general, holiday, event
    String? eventDate, // YYYY-MM-DD format for holiday/event
    String? endDate,   // YYYY-MM-DD for multi-day events
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'content': content,
      'priority': priority,
      'target_role': targetRole,
      'announcement_type': announcementType,
    };
    
    if (eventDate != null) {
      body['event_date'] = eventDate;
    }
    
    if (endDate != null) {
      body['end_date'] = endDate;
    }
    
    final response = await ApiClient.post(_endpoint, body);
    
    if (response.success) {
      return Announcement.fromJson(response.body);
    } else {
      throw Exception(response.errorMessage ?? 'Failed to create announcement');
    }
  }
  
  /// Delete announcement (Admin only)
  static Future<void> deleteAnnouncement(int id) async {
    final response = await ApiClient.delete('$_endpoint/$id');
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to delete announcement');
    }
  }
  
  /// Get holidays for a year
  static Future<List<dynamic>> getHolidays(int year) async {
    final response = await ApiClient.get('$_endpoint/holidays?year=$year');
    
    if (response.success) {
      final data = response.body;
      return data['holidays'] as List<dynamic>;
    } else {
      throw Exception(response.errorMessage ?? 'Failed to load holidays');
    }
  }
  
  /// Create a holiday announcement
  static Future<Announcement> createHoliday({
    required String title,
    required String content,
    required String eventDate, // YYYY-MM-DD
  }) async {
    final body = {
      'title': title,
      'content': content,
      'priority': 'high',
      'announcement_type': 'holiday',
      'event_date': eventDate,
      'target_role': 'all',
    };
    
    final response = await ApiClient.post(_endpoint, body);
    
    if (response.success) {
      return Announcement.fromJson(response.body);
    } else {
      throw Exception(response.errorMessage ?? 'Failed to create holiday');
    }
  }
}
