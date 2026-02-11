class Announcement {
  final int id;
  final String title;
  final String content;
  final String priority; // normal, high, critical
  final String? targetRole; // null = all
  final int authorId;
  final String authorName;
  final int createdAt;
  final String announcementType; // general, holiday, event
  final String? eventDate; // YYYY-MM-DD
  final String? endDate; // YYYY-MM-DD
  
  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.priority,
    this.targetRole,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.announcementType = 'general',
    this.eventDate,
    this.endDate,
  });
  
  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      priority: json['priority'] ?? 'normal',
      targetRole: json['target_role'],
      authorId: json['author_id'],
      authorName: json['author_name'] ?? 'Unknown',
      createdAt: json['created_at'],
      announcementType: json['announcement_type'] ?? 'general',
      eventDate: json['event_date'],
      endDate: json['end_date'],
    );
  }
}
