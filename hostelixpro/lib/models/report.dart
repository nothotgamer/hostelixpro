// Report model


class Report {
  final int id;
  final int studentId;
  final int wakeTime;
  final bool walk;
  final bool exercise;
  final int lateMinutes;
  final String status;
  final int createdAt;
  
  final String? studentName;
  final String? studentRoom;
  final String? studentAdmissionNo;
  
  Report({
    required this.id,
    required this.studentId,
    this.studentName,
    this.studentRoom,
    this.studentAdmissionNo,
    required this.wakeTime,
    required this.walk,
    required this.exercise,
    required this.lateMinutes,
    required this.status,
    required this.createdAt,
  });
  
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      studentId: json['student_id'],
      studentName: json['student_name'],
      studentRoom: json['student_room'],
      studentAdmissionNo: json['student_admission_no'],
      wakeTime: json['wake_time'],
      walk: json['walk'] ?? false,
      exercise: json['exercise'] ?? false,
      lateMinutes: json['late_minutes'] ?? 0,
      status: json['status'],
      createdAt: json['created_at'],
    );
  }
}
