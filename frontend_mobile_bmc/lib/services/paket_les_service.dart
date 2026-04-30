import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaketLesService {
  static const String _defaultBaseUrl = "http://172.27.66.99:8080/api";
  static String? _activeBaseUrl;

  static List<String> _candidateBaseUrls() {
    final urls = <String>[
      _defaultBaseUrl,
      'http://127.0.0.1:8080/api',
      'http://localhost:8080/api',
      'http://10.0.2.2:8080/api',
    ];

    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        final scheme = Uri.base.scheme.isEmpty ? 'http' : Uri.base.scheme;
        urls.insert(0, '$scheme://$host:8080/api');
      }
    }

    if (_activeBaseUrl != null && _activeBaseUrl!.isNotEmpty) {
      urls.insert(0, _activeBaseUrl!);
    }

    return urls.toSet().toList();
  }

  static Future<http.Response> _requestWithFallback(
    Future<http.Response> Function(String baseUrl) request,
  ) async {
    Object? lastError;

    for (final baseUrl in _candidateBaseUrls()) {
      try {
        print('🌐 Trying API base: $baseUrl');
        final response = await request(
          baseUrl,
        ).timeout(const Duration(seconds: 10));
        _activeBaseUrl = baseUrl;
        return response;
      } catch (e) {
        lastError = e;
        print('❌ Failed with base $baseUrl: $e');
      }
    }

    throw Exception('All API base URLs failed. Last error: $lastError');
  }

  // Get token from SharedPreferences
  static Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token') ?? prefs.getString('auth_token');
    } catch (e) {
      print("❌ Error getting token: $e");
      return null;
    }
  }

  // Get all active paket les (public endpoint - no auth needed)
  static Future<List<Map<String, dynamic>>> getPaketLesList({
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _requestWithFallback(
        (baseUrl) => http.get(
          Uri.parse(
            '$baseUrl/paket-les',
          ).replace(queryParameters: queryParams.isEmpty ? null : queryParams),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      print('🔥 STATUS CODE: ${response.statusCode}');
      print('🔥 RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // Check if response has data field
        if (jsonResponse['data'] is List) {
          List<Map<String, dynamic>> pakets = [];
          for (var item in jsonResponse['data']) {
            pakets.add(Map<String, dynamic>.from(item));
          }
          print("✅ Found ${pakets.length} pakets");
          return pakets;
        }
        return [];
      } else {
        print('❌ API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ ERROR API: $e');
      return [];
    }
  }

  // Create new paket (requires admin token)
  static Future<Map<String, dynamic>> createPaket(
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          "status": "error",
          "message": "Token tidak ditemukan. Silakan login terlebih dahulu.",
        };
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      print('🔥 CREATE PAKET FROM MOBILE: $data');

      final response = await _requestWithFallback(
        (baseUrl) => http.post(
          Uri.parse('$baseUrl/admin/paket-les'),
          headers: headers,
          body: jsonEncode(data),
        ),
      );

      print('🔥 CREATE STATUS: ${response.statusCode}');
      print('🔥 CREATE RESPONSE: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "error",
          "message": "Gagal membuat paket",
          "detail": response.body,
        };
      }
    } catch (e) {
      print('❌ ERROR CREATE: $e');
      return {'status': 'error', 'message': 'Error: $e'};
    }
  }

  // Format rupiah
  static String formatRupiah(int amount) {
    final formatter = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
    return 'Rp ${amount.toString().replaceAllMapped(formatter, (match) => '${match.group(1)}.')}';
  }

  // Calculate promo price
  static int calculateHargaPromo(int hargaAwal, int diskon) {
    return (hargaAwal * (100 - diskon) / 100).toInt();
  }
}
