class BackupMeta {
  final int id;
  final String filename;
  final int fileSizeBytes;
  final int createdById;
  final String createdBy;
  final int createdAt;

  BackupMeta({
    required this.id,
    required this.filename,
    required this.fileSizeBytes,
    required this.createdById,
    required this.createdBy,
    required this.createdAt,
  });

  factory BackupMeta.fromJson(Map<String, dynamic> json) {
    return BackupMeta(
      id: json['id'],
      filename: json['filename'],
      fileSizeBytes: json['file_size_bytes'],
      createdById: json['created_by_id'] ?? 0,
      createdBy: json['created_by'] ?? 'System',
      createdAt: json['created_at'],
    );
  }
}
