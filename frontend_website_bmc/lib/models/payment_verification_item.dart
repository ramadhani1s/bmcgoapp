class PaymentVerificationItem {
  final String transactionId;
  final int userId;
  final String packageId;
  final String packageTitle;
  final int amount;
  final String status;
  final String paymentType;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentVerificationItem({
    required this.transactionId,
    required this.userId,
    required this.packageId,
    required this.packageTitle,
    required this.amount,
    required this.status,
    required this.paymentType,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentVerificationItem.fromJson(Map<String, dynamic> json) {
    return PaymentVerificationItem(
      transactionId: json['transaction_id']?.toString() ?? '',
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      packageId: json['package_id']?.toString() ?? '',
      packageTitle: json['package_title']?.toString() ?? '',
      amount: json['amount'] is int
          ? json['amount'] as int
          : int.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '',
      paymentType: json['payment_type']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      customerEmail: json['customer_email']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
