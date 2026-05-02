import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin_dashboard_data.dart';

// Model untuk payment verification
class PaymentVerificationItem {
  final String transactionId;
  final int userId;
  final String studentName;
  final String studentEmail;
  final String studentPhone;
  final String schoolName;
  final String className;
  final String packageTitle;
  final int amount;
  final String paymentType;
  final DateTime createdAt;
  final String status;
  final bool isVerified;

  PaymentVerificationItem({
    required this.transactionId,
    required this.userId,
    required this.studentName,
    required this.studentEmail,
    required this.studentPhone,
    required this.schoolName,
    required this.className,
    required this.packageTitle,
    required this.amount,
    required this.paymentType,
    required this.createdAt,
    required this.status,
    required this.isVerified,
  });

  factory PaymentVerificationItem.fromJson(Map<String, dynamic> json) {
    return PaymentVerificationItem(
      transactionId: json['transaction_id']?.toString() ?? '',
      userId: json['user_id'] is int ? json['user_id'] as int : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      studentName: json['student_name']?.toString() ?? '-',
      studentEmail: json['student_email']?.toString() ?? '-',
      studentPhone: json['student_phone']?.toString() ?? '-',
      schoolName: json['school_name']?.toString() ?? '-',
      className: json['class_name']?.toString() ?? '-',
      packageTitle: json['package_title']?.toString() ?? '-',
      amount: json['amount'] is int ? json['amount'] as int : int.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      paymentType: json['payment_type']?.toString() ?? '-',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'pending',
      isVerified: json['is_verified'] is bool ? json['is_verified'] as bool : (json['is_verified']?.toString() ?? 'false').toLowerCase() == 'true',
    );
  }
}

class AdminDashboardService {
  // Updated base URL to port 8081
  static const String baseUrl = 'http://localhost:8081';

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        (prefs.getString('token') ?? prefs.getString('auth_token') ?? '')
            .trim();
    if (token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }
    return token;
  }

  static Future<AdminDashboardData> getSummary() async {
    final token = await _getToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl/api/admin/dashboard-summary'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return AdminDashboardData.fromJson(data);
      }
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Sesi admin tidak valid. Silakan login ulang.');
    }

    throw Exception('Gagal memuat ringkasan dashboard admin');
  }

  // Get pending payment verifications
  static Future<List<PaymentVerificationItem>> getPendingPaymentVerifications() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/admin/payment/pending-verifications'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as List<dynamic>? ?? [];
      
      return data
          .whereType<Map<String, dynamic>>()
          .map(PaymentVerificationItem.fromJson)
          .toList();
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Sesi admin tidak valid. Silakan login ulang.');
    }

    throw Exception('Gagal memuat daftar verifikasi pembayaran');
  }

  // Approve payment verification
  static Future<void> approvePaymentVerification(String transactionId) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/admin/payment/$transactionId/approve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Sesi admin tidak valid. Silakan login ulang.');
    }

    throw Exception('Gagal menyetujui pembayaran: ${response.body}');
  }

  // Reject payment verification
  static Future<void> rejectPaymentVerification(String transactionId) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/admin/payment/$transactionId/reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Sesi admin tidak valid. Silakan login ulang.');
    }

    throw Exception('Gagal menolak pembayaran: ${response.body}');
  }
}
