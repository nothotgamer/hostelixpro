// Routine model
class Routine {
  final int id;
  final String type;
  final int requestTime;
  final String status;
  final Map<String, dynamic>? payload;
  final int? studentId; // Added
  final String? studentName; // Added
  final String? rejectionReason;
  
  Routine({
    required this.id,
    required this.type,
    required this.requestTime,
    required this.status,
    this.payload,
    this.studentId,
    this.studentName,
    this.rejectionReason,
  });
  
  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'],
      type: json['type'],
      requestTime: json['request_time'],
      status: json['status'],
      payload: json['payload'],
      studentId: json['student_id'],
      studentName: json['student_name'],
      rejectionReason: json['rejection_reason'],
    );
  }
}
