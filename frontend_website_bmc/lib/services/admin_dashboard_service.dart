import 'dart:convert';

import 'package:frontend_website_bmc/core/network/api_client.dart';
import 'package:frontend_website_bmc/models/payment_verification_item.dart';
import 'package:frontend_website_bmc/services/auth_service.dart';
import '../models/admin_dashboard_data.dart';

class AdminDashboardService {
  static ApiClient get _client => ApiClient(baseUrl: AuthService.baseUrl);

  static Future<AdminDashboardData> getSummary() async {
    final response = await _client.get(
      '/api/admin/dashboard-summary',
      auth: true,
    );

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
  static Future<List<PaymentVerificationItem>>
  getPendingPaymentVerifications() async {
    final response = await _client.get(
      '/admin/payment/pending-verifications',
      auth: true,
    );

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
    final response = await _client.post(
      '/admin/payment/$transactionId/approve',
      auth: true,
      body: '{}',
    );

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
    final response = await _client.post(
      '/admin/payment/$transactionId/reject',
      auth: true,
      body: '{}',
    );

    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Sesi admin tidak valid. Silakan login ulang.');
    }

    throw Exception('Gagal menolak pembayaran: ${response.body}');
  }
}
