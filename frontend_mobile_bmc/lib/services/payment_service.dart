import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend_mobile_bmc/models/payment_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  // GANTI DENGAN BASE URL BACKEND KAMU
  // Jika kamu menjalankan Flutter di Android emulator, gunakan 10.0.2.2
  static const String baseUrl =
      'http://10.0.2.2:8081'; // Android emulator -> PC localhost (payment server)
  // Untuk production: 'https://api.yourdomain.com'

  static Future<String> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    if (token.isEmpty) {
      throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
    }
    return token;
  }

  static String? _extractMessageFromBody(String body) {
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(trimmedBody);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString();
        final error = decoded['error']?.toString();
        if (message != null &&
            message.isNotEmpty &&
            error != null &&
            error.isNotEmpty) {
          return '$message: $error';
        }
        return message ?? error;
      }
    } catch (_) {
      return trimmedBody;
    }

    return trimmedBody;
  }

  // Membuat transaction token untuk Midtrans
  static Future<TransactionResponse> createTransaction(
    TransactionRequest request,
  ) async {
    try {
      final token = await _getAuthToken();

      final response = await http
          .post(
            Uri.parse('$baseUrl/payment/create-transaction'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TransactionResponse.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired atau tidak valid');
      } else {
        final errorMessage = _extractMessageFromBody(response.body);
        throw Exception(
          errorMessage?.isNotEmpty == true
              ? errorMessage!
              : 'Gagal membuat transaction (${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Error creating transaction: $e');
    }
  }

  // Cek status payment
  static Future<PaymentStatus> checkPaymentStatus(String transactionId) async {
    try {
      final token = await _getAuthToken();

      final response = await http
          .get(
            Uri.parse('$baseUrl/payment/status/$transactionId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentStatus.fromJson(data['data']);
      } else {
        throw Exception('Gagal mengecek status payment');
      }
    } catch (e) {
      throw Exception('Error checking payment status: $e');
    }
  }

  // Finish transaction di backend
  static Future<void> finishTransaction(
    String transactionId,
    String status,
  ) async {
    try {
      final token = await _getAuthToken();

      final response = await http
          .post(
            Uri.parse('$baseUrl/payment/finish-transaction'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'transaction_id': transactionId,
              'status': status,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Gagal menyelesaikan transaction');
      }
    } catch (e) {
      throw Exception('Error finishing transaction: $e');
    }
  }

  // Ambil riwayat pembayaran (opsional status filter)
  static Future<List<PaymentHistoryItem>> getPaymentHistory({String? status}) async {
    try {
      final token = await _getAuthToken();
      final uri = Uri.parse('$baseUrl/payment/history${status != null ? '?status=$status' : ''}');
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] as List<dynamic>?) ?? [];
        return list.map((e) => PaymentHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Gagal memuat riwayat pembayaran');
    } catch (e) {
      throw Exception('Error loading payment history: $e');
    }
  }

  // Cek apakah user bisa mengakses fitur berbayar (verifikasi)
  static Future<bool> getVerificationStatus() async {
    try {
      final token = await _getAuthToken();
      final uri = Uri.parse('$baseUrl/payment/verification-status');
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ok = data['is_verified'] as bool?;
        return ok == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}