import 'package:hostelixpro/services/api_client.dart';

class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String? actionUrl;
  final String? entityType;
  final int? entityId;
  final int createdAt;
  
  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.actionUrl,
    this.entityType,
    this.entityId,
    required this.createdAt,
  });
  
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'] ?? 'info',
      isRead: json['is_read'] ?? false,
      actionUrl: json['action_url'],
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      createdAt: json['created_at'],
    );
  }
}

class NotificationService {
  /// Get notifications for current user
  static Future<List<NotificationModel>> getNotifications({bool unreadOnly = false}) async {
    final endpoint = unreadOnly ? '/notifications?unread=true' : '/notifications';
    final response = await ApiClient.get(endpoint);
    
    if (!response.success) {
      throw Exception(response.errorMessage ?? 'Failed to fetch notifications');
    }
    
    final List<dynamic> list = response.body['notifications'] ?? [];
    return list.map((e) => NotificationModel.fromJson(e)).toList();
  }
  
  /// Get unread count
  static Future<int> getUnreadCount() async {
    final response = await ApiClient.get('/notifications/unread-count');
    
    if (!response.success) {
      return 0;
    }
    
    return response.body['count'] ?? 0;
  }
  
  /// Mark notification as read
  static Future<void> markAsRead(int id) async {
    final response = await ApiClient.post('/notifications/$id/read', {});
    if (!response.success) throw Exception(response.errorMessage);
  }
  
  /// Mark all as read
  static Future<void> markAllAsRead() async {
    final response = await ApiClient.post('/notifications/read-all', {});
    if (!response.success) throw Exception(response.errorMessage);
  }
}
