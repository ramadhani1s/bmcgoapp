import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend_mobile_bmc/models/payment_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  // GANTI DENGAN BASE URL BACKEND KAMU
  // Jika kamu menjalankan Flutter di Android emulator, gunakan 10.0.2.2
  static const String baseUrl =
      'http://10.0.2.2:8080'; // Android emulator -> PC localhost
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

  static Future<List<PaymentHistoryItem>> getPaymentHistory({
    String? status,
  }) async {
    try {
      final token = await _getAuthToken();

      final uri = Uri.parse('$baseUrl/payment/history').replace(
        queryParameters: status != null && status.isNotEmpty
            ? {'status': status}
            : null,
      );

      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] as List<dynamic>? ?? const []);
        return list
            .whereType<Map<String, dynamic>>()
            .map(PaymentHistoryItem.fromJson)
            .toList();
      }

      final errorMessage = _extractMessageFromBody(response.body);
      throw Exception(
        errorMessage?.isNotEmpty == true
            ? errorMessage!
            : 'Gagal memuat riwayat pembayaran (${response.statusCode})',
      );
    } catch (e) {
      throw Exception('Error loading payment history: $e');
    }
  }

  static Future<bool> getVerificationStatus() async {
    try {
      final token = await _getAuthToken();

      final response = await http
          .get(
            Uri.parse('$baseUrl/payment/verification-status'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['can_access'] == true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Finish transaction di backend (backend query Midtrans langsung)
  static Future<String> finishTransaction(String transactionId) async {
    try {
      final token = await _getAuthToken();

      final response = await http
          .post(
            Uri.parse('$baseUrl/payment/finish-transaction'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'transaction_id': transactionId}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['status'] ?? 'unknown';
      }

      throw Exception('Gagal menyelesaikan transaction');
    } catch (e) {
      throw Exception('Error finishing transaction: $e');
    }
  }

  static Future<String> submitManualTransfer({
    required int packageId,
    required String packageTitle,
    required int amount,
  }) async {
    try {
      final token = await _getAuthToken();

      final response = await http
          .post(
            Uri.parse('$baseUrl/payment/submit-transfer'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'package_id': packageId.toString(),
              'package_title': packageTitle,
              'amount': amount.toString(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final payload = data['data'] as Map<String, dynamic>?;
        return payload?['transaction_id']?.toString() ?? '';
      }

      // Fallback untuk backend lama yang belum punya route submit-transfer.
      if (response.statusCode == 404) {
        final prefs = await SharedPreferences.getInstance();
        final customerName = prefs.getString('user_name') ?? 'Siswa BMC';
        final customerEmail =
            prefs.getString('user_email') ?? 'siswa@bmc.local';
        final customerPhone = prefs.getString('user_phone') ?? '081234567890';

        final legacyTransaction = await createTransaction(
          TransactionRequest(
            packageId: packageId.toString(),
            packageTitle: packageTitle,
            amount: amount.toString(),
            customerEmail: customerEmail,
            customerName: customerName,
            customerPhone: customerPhone,
          ),
        );

        try {
          await finishTransaction(legacyTransaction.transactionId);
        } catch (_) {
          // Abaikan error refresh status Midtrans, admin masih bisa verifikasi dari status pending.
        }

        return legacyTransaction.transactionId;
      }

      final errorMessage = _extractMessageFromBody(response.body);
      throw Exception(
        errorMessage?.isNotEmpty == true
            ? errorMessage!
            : 'Gagal mengirim konfirmasi transfer (${response.statusCode})',
      );
    } catch (e) {
      throw Exception('Error submit transfer: $e');
    }
  }
}
