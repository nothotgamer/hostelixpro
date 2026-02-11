class AuditLog {
  final int id;
  final int? userId;
  final String? userName;
  final String? userEmail;
  final String action;
  final String? entity;
  final int? entityId;
  final int timestamp;
  final String? ip;
  final String? device;
  final Map<String, dynamic>? details;
  final String? reason;

  AuditLog({
    required this.id,
    this.userId,
    this.userName,
    this.userEmail,
    required this.action,
    this.entity,
    this.entityId,
    required this.timestamp,
    this.ip,
    this.device,
    this.details,
    this.reason,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userEmail: json['user_email'],
      action: json['action'],
      entity: json['entity'],
      entityId: json['entity_id'],
      timestamp: json['timestamp'],
      ip: json['ip'],
      device: json['device'],
      details: json['details_json'],
      reason: json['reason'],
    );
  }
}
