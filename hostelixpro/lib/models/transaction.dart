class Transaction {
  final int id;
  final int feeId;
  final double amount;
  final DateTime transactionDate;
  final String paymentMethod;
  final String? transactionReference;
  final String? proofPath;
  final String status;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final String? approvedBy;

  Transaction({
    required this.id,
    required this.feeId,
    required this.amount,
    required this.transactionDate,
    required this.paymentMethod,
    this.transactionReference,
    this.proofPath,
    required this.status,
    this.rejectionReason,
    this.approvedAt,
    this.approvedBy,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      feeId: json['fee_id'],
      amount: double.parse(json['amount'].toString()),
      transactionDate: DateTime.fromMillisecondsSinceEpoch(json['transaction_date']),
      paymentMethod: json['payment_method'],
      transactionReference: json['transaction_reference'],
      proofPath: json['proof_path'],
      status: json['status'],
      rejectionReason: json['rejection_reason'],
      approvedAt: json['approved_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['approved_at']) 
          : null,
      approvedBy: json['approved_by'],
    );
  }
}
