class PaymentPackage {
  final int id;
  final String title;
  final String price;
  final String description;

  PaymentPackage({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
  });
}

class TransactionRequest {
  final String packageId;
  final String packageTitle;
  final String amount;
  final String customerEmail;
  final String customerName;
  final String customerPhone;

  TransactionRequest({
    required this.packageId,
    required this.packageTitle,
    required this.amount,
    required this.customerEmail,
    required this.customerName,
    required this.customerPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      'package_id': packageId,
      'package_title': packageTitle,
      'amount': amount,
      'customer_email': customerEmail,
      'customer_name': customerName,
      'customer_phone': customerPhone,
    };
  }
}

class TransactionResponse {
  final String token;
  final String redirectUrl;
  final String transactionId;
  final String status;

  TransactionResponse({
    required this.token,
    required this.redirectUrl,
    required this.transactionId,
    required this.status,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    return TransactionResponse(
      token: json['token'] ?? '',
      redirectUrl: json['redirect_url'] ?? '',
      transactionId: json['transaction_id'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class PaymentStatus {
  final String transactionId;
  final String status;
  final String statusMessage;
  final String paymentType;

  PaymentStatus({
    required this.transactionId,
    required this.status,
    required this.statusMessage,
    required this.paymentType,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      transactionId: json['transaction_id'] ?? '',
      status: json['transaction_status'] ?? '',
      statusMessage: json['status_message'] ?? '',
      paymentType: json['payment_type'] ?? '',
    );
  }
}

class PaymentHistoryItem {
  final String transactionId;
  final String packageId;
  final String packageTitle;
  final int amount;
  final String status;
  final String paymentType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaymentHistoryItem({
    required this.transactionId,
    required this.packageId,
    required this.packageTitle,
    required this.amount,
    required this.status,
    required this.paymentType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final text = value.toString();
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    int parseAmount(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return PaymentHistoryItem(
      transactionId: json['transaction_id']?.toString() ?? '',
      packageId: json['package_id']?.toString() ?? '',
      packageTitle: json['package_title']?.toString() ?? '-',
      amount: parseAmount(json['amount']),
      status: json['status']?.toString() ?? 'unknown',
      paymentType: json['payment_type']?.toString() ?? '-',
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}
