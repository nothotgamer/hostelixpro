// Fee model
class Fee {
  final int id;
  final int studentId;
  final String? studentName;
  final String? structureName;
  final int month;
  final int year;
  
  final double? expectedAmount;
  final double? paidAmount;
  final double lateFee;
  final String? proofPath;
  final String status;
  
  final DateTime? dueDate;
  final DateTime? paidAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? rejectionReason;
  
  final String? studentAdmissionNo;
  final String? studentRoom;
  final String? studentImage;
  final double? pendingAmount;
  final List<String>? pendingProofs;
  
  // Computed
  double get totalPaid => (paidAmount ?? 0);
  
  Fee({
    required this.id,
    required this.studentId,
    this.studentName,
    this.studentAdmissionNo,
    this.studentRoom,
    this.studentImage,
    this.structureName,
    required this.month,
    required this.year,
    this.expectedAmount,
    this.paidAmount,
    this.pendingAmount,
    this.pendingProofs,
    this.lateFee = 0,
    this.proofPath,
    required this.status,
    this.dueDate,
    this.paidAt,
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
  });

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      id: json['id'],
      studentId: json['student_id'],
      studentName: json['student_name'],
      studentAdmissionNo: json['student_admission_no'],
      studentRoom: json['student_room'],
      studentImage: json['student_image'],
      structureName: json['structure_name'],
      month: json['month'],
      year: json['year'],
      expectedAmount: json['expected_amount'] != null ? double.parse(json['expected_amount'].toString()) : null,
      paidAmount: json['paid_amount'] != null ? double.parse(json['paid_amount'].toString()) : null,
      pendingAmount: json['pending_amount'] != null ? double.parse(json['pending_amount'].toString()) : null,
      pendingProofs: json['pending_proofs'] != null ? List<String>.from(json['pending_proofs']) : null,
      lateFee: json['late_fee'] != null ? double.parse(json['late_fee'].toString()) : 0.0,
      proofPath: json['proof_path'],
      status: json['status'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      paidAt: json['paid_at'] != null ? DateTime.fromMillisecondsSinceEpoch(json['paid_at']) : null,
      approvedAt: json['approved_at'] != null ? DateTime.fromMillisecondsSinceEpoch(json['approved_at']) : null,
      approvedBy: json['approved_by'],
      rejectionReason: json['rejection_reason'],
    );
  }
}
