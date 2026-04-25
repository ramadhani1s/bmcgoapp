import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_verification_item.dart';

class PaymentVerificationOverview {
  final int waiting;
  final int approved;
  final int rejected;
  final List<PaymentVerificationItem> items;

  PaymentVerificationOverview({
    required this.waiting,
    required this.approved,
    required this.rejected,
    required this.items,
  });

  factory PaymentVerificationOverview.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PaymentVerificationItem.fromJson)
        .toList();

    return PaymentVerificationOverview(
      waiting: json['waiting'] is int
          ? json['waiting'] as int
          : int.tryParse(json['waiting']?.toString() ?? '0') ?? 0,
      approved: json['approved'] is int
          ? json['approved'] as int
          : int.tryParse(json['approved']?.toString() ?? '0') ?? 0,
      rejected: json['rejected'] is int
          ? json['rejected'] as int
          : int.tryParse(json['rejected']?.toString() ?? '0') ?? 0,
      items: items,
    );
  }
}

class PaymentVerificationService {
  static const String baseUrl = 'http://127.0.0.1:8080';

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

  static Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  static String _extractErrorMessage(http.Response response) {
    try {
      final decoded = _decodeObject(response.body);
      final message = decoded['message']?.toString().trim() ?? '';
      final error = decoded['error']?.toString().trim() ?? '';
      if (message.isNotEmpty) return message;
      if (error.isNotEmpty) return error;
    } catch (_) {}
    return 'HTTP ${response.statusCode}';
  }

  static Future<PaymentVerificationOverview> getOverview() async {
    final token = await _getToken();
    String firstError = '';

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/admin/payment/overview'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = _decodeObject(response.body);
        final data = decoded['data'];
        if (data is Map<String, dynamic>) {
          return PaymentVerificationOverview.fromJson(data);
        }
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Sesi admin tidak valid. Silakan login ulang.');
      }

      firstError = _extractErrorMessage(response);
    } catch (_) {
      // Fall through to legacy endpoint.
    }

    final fallbackResponse = await http
        .get(
          Uri.parse('$baseUrl/admin/payment/pending-verifications'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));

    if (fallbackResponse.statusCode == 200) {
      final decoded = _decodeObject(fallbackResponse.body);
      final items = (decoded['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PaymentVerificationItem.fromJson)
          .toList();

      final waiting = items
          .where((item) => item.status == 'success' && !item.isVerified)
          .length;
      final approved = items.where((item) => item.isVerified).length;
      final rejected = items
          .where(
            (item) =>
                item.status == 'failed' ||
                item.status == 'cancel' ||
                item.status == 'deny' ||
                item.status == 'expire',
          )
          .length;

      return PaymentVerificationOverview(
        waiting: waiting,
        approved: approved,
        rejected: rejected,
        items: items,
      );
    }

    if (fallbackResponse.statusCode == 401 ||
        fallbackResponse.statusCode == 403) {
      throw Exception('Sesi admin tidak valid. Silakan login ulang.');
    }

    final fallbackError = _extractErrorMessage(fallbackResponse);
    if (firstError.isNotEmpty || fallbackError.isNotEmpty) {
      throw Exception(
        'Gagal memuat overview verifikasi pembayaran. $firstError; $fallbackError',
      );
    }

    return PaymentVerificationOverview(
      waiting: 0,
      approved: 0,
      rejected: 0,
      items: const [],
    );
  }

  static Future<List<PaymentVerificationItem>> getPendingVerifications() async {
    final overview = await getOverview();
    return overview.items
        .where((item) => item.status == 'success' && item.isVerified == false)
        .toList();
  }

  static Future<Map<String, dynamic>> verifyPayment(
    String transactionId,
  ) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/payment/verify/$transactionId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(
      decoded['message']?.toString() ?? 'Gagal memverifikasi pembayaran',
    );
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
