import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_verification_item.dart';

class PaymentVerificationService {
  static const String baseUrl = 'http://localhost:8080';

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }
    return token;
  }

  static Future<List<PaymentVerificationItem>> getPendingVerifications() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/payment/pending-verifications'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (decoded['data'] as List<dynamic>? ?? const []);
      return data
          .whereType<Map<String, dynamic>>()
          .map(PaymentVerificationItem.fromJson)
          .toList();
    }

    throw Exception('Gagal memuat daftar verifikasi pembayaran');
  }

  static Future<void> verifyPayment(String transactionId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/payment/verify/$transactionId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal memverifikasi pembayaran');
    }
  }

  static Future<void> rejectPayment(String transactionId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/payment/reject/$transactionId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menolak pembayaran');
    }
  }
}
