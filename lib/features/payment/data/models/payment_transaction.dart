class PaymentTransaction {
  final int id;
  final String? referenceId;
  final String type; // 'earnings', 'commission', 'payment'
  final double amount;
  final String flow; // 'inflow', 'outflow'
  final String status;
  final String description;
  final DateTime createdAt;

  PaymentTransaction({
    required this.id,
    this.referenceId,
    required this.type,
    required this.amount,
    required this.flow,
    required this.status,
    required this.description,
    required this.createdAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'],
      referenceId: json['reference_id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      flow: json['flow'],
      status: json['status'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
