import 'dart:convert';

import 'package:frontend_website_bmc/core/network/api_client.dart';
import 'package:http/http.dart' as http;

import '../models/payment_verification_item.dart';

class PaymentVerificationOverview {
  final int waiting;
  final int approved;
  final int rejected;
  final List<PaymentVerificationItem> items;

  const PaymentVerificationOverview({
    required this.waiting,
    required this.approved,
    required this.rejected,
    required this.items,
  });

  factory PaymentVerificationOverview.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(PaymentVerificationItem.fromJson)
        .toList();

    return PaymentVerificationOverview(
      waiting: _toInt(json['waiting']),
      approved: _toInt(json['approved']),
      rejected: _toInt(json['rejected']),
      items: items,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

class PaymentVerificationService {
  static const String baseUrl = 'http://localhost:8080';
  static final ApiClient _client = ApiClient(baseUrl: baseUrl);

  static Map<String, dynamic> _decodeObject(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // ignore
    }
    return {};
  }

  static String _extractErrorMessage(http.Response response) {
    final decoded = _decodeObject(response.body);
    final message = decoded['message']?.toString().trim() ?? '';
    final error = decoded['error']?.toString().trim() ?? '';
    if (message.isNotEmpty) return message;
    if (error.isNotEmpty) return error;
    return 'HTTP ${response.statusCode}';
  }

  static Future<PaymentVerificationOverview> getOverview() async {
    try {
      final response = await _client.get(
        '/admin/payment/pending-verifications',
        auth: true,
      );

      if (response.statusCode == 200) {
        final decoded = _decodeObject(response.body);
        final rawItems = decoded['data'] as List<dynamic>? ?? const [];
        final items = rawItems
            .whereType<Map<String, dynamic>>()
            .map(PaymentVerificationItem.fromJson)
            .toList();

        final waiting = items
            .where((item) => item.status == 'success' && !item.isVerified)
            .length;
        final approved = items.where((item) => item.isVerified).length;
        final rejected = items.where((item) {
          final status = item.status;
          return status == 'failed' ||
              status == 'cancel' ||
              status == 'deny' ||
              status == 'expire';
        }).length;

        return PaymentVerificationOverview(
          waiting: waiting,
          approved: approved,
          rejected: rejected,
          items: items,
        );
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Sesi admin tidak valid. Silakan login ulang.');
      }

      throw Exception(
        'Gagal memuat data verifikasi: ${response.statusCode} - ${_extractErrorMessage(response)}',
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<PaymentVerificationItem>> getPendingVerifications() async {
    final overview = await getOverview();
    return overview.items
        .where((item) => item.status == 'success' && !item.isVerified)
        .toList();
  }

  static Future<List<PaymentVerificationItem>> getVerifications({
    required String filter,
  }) async {
    if (filter == 'pending') {
      return getPendingVerifications();
    }

    final overview = await getOverview();
    if (filter == 'approved') {
      return overview.items.where((item) => item.isVerified).toList();
    }

    return overview.items;
  }

  static Future<Map<String, dynamic>> verifyPayment(
    String transactionId,
  ) async {
    final response = await _client.post(
      '/admin/payment/$transactionId/approve',
      auth: true,
      body: {},
    );

    if (response.statusCode == 200) {
      final decoded = _decodeObject(response.body);
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {};
    }

    throw Exception(_extractErrorMessage(response));
  }

  static Future<void> rejectPayment(String transactionId) async {
    final response = await _client.post(
      '/admin/payment/$transactionId/reject',
      auth: true,
      body: {},
    );

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  static Future<void> deletePayment(String transactionId) async {
    final response = await _client.delete(
      '/admin/payment/$transactionId',
      auth: true,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }
  }
}
