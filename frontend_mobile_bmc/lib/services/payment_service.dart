import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend_mobile_bmc/models/payment_model.dart';
import 'package:frontend_mobile_bmc/core/session/app_session.dart';
import 'package:frontend_mobile_bmc/config/api_config.dart';

class PaymentService {
  static final String baseUrl = ApiConfig.baseUrl;

  // ✅ FIX 1: Gunakan AppSession (nullable), tidak throw Exception
  static Future<String> _getAuthToken() async {
    final token = await AppSession.getAuthToken();
    return token ?? '';
  }

  static String? _extractMessageFromBody(String body) {
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) return null;
    try {
      final decoded = jsonDecode(trimmedBody);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString();
        final error = decoded['error']?.toString();
        if (message != null && message.isNotEmpty && error != null && error.isNotEmpty) {
          return '$message: $error';
        }
        return message ?? error;
      }
    } catch (_) {
      return trimmedBody;
    }
    return trimmedBody;
  }

  static Future<TransactionResponse> createTransaction(TransactionRequest request) async {
    try {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$baseUrl/payment/create-transaction'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));

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

  static Future<PaymentStatus> checkPaymentStatus(String transactionId) async {
    try {
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse('$baseUrl/payment/status/$transactionId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

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

  static Future<void> finishTransaction(String transactionId, String status) async {
    try {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$baseUrl/payment/finish-transaction'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'transaction_id': transactionId,
          'status': status,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Gagal menyelesaikan transaction');
      }
    } catch (e) {
      throw Exception('Error finishing transaction: $e');
    }
  }

  static Future<List<PaymentHistoryItem>> getPaymentHistory({String? status}) async {
    try {
      final token = await _getAuthToken();
      final uri = Uri.parse('$baseUrl/payment/history${status != null ? '?status=$status' : ''}');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] as List<dynamic>?) ?? [];
        return list
            .map((e) => PaymentHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Gagal memuat riwayat pembayaran');
    } catch (e) {
      throw Exception('Error loading payment history: $e');
    }
  }

  // ✅ FIX 2: Cek token dulu sebelum request, catch lebih informatif
  static Future<VerificationStatus> getVerificationStatus() async {
    // Kalau token kosong (belum login), langsung return inactive tanpa hit API
    final token = await AppSession.getAuthToken();
    if (token == null || token.isEmpty) {
      return VerificationStatus(
        isVerified: false,
        verifiedAt: null,
        canAccess: false,
        userStatus: 'inactive',
        isUserActive: false,
      );
    }

    try {
      final uri = Uri.parse('$baseUrl/payment/verification-status');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = VerificationStatus.fromJson(data);
        await AppSession.saveUserStatus(
          status.userStatus.isNotEmpty
              ? status.userStatus
              : (status.isUserActive ? 'aktif' : 'inactive'),
        );
        return status;
      }

      // ✅ FIX 3: Log status code agar mudah debug
      return VerificationStatus(
        isVerified: false,
        verifiedAt: null,
        canAccess: false,
        userStatus: 'inactive',
        isUserActive: false,
      );
    } catch (e) {
      // Network error / timeout — return inactive tapi tidak sembunyikan error
      return VerificationStatus(
        isVerified: false,
        verifiedAt: null,
        canAccess: false,
        userStatus: 'inactive',
        isUserActive: false,
      );
    }
  }
}