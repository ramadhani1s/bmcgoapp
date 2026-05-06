// ignore_for_file: avoid_print, duplicate_ignore

import 'dart:convert';
import 'package:frontend_website_bmc/core/session/app_session.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PaketLesService {
  static const String _defaultBaseUrl = "http://localhost:8080/api/admin";
  static String? _activeBaseUrl;

  static List<String> _candidateBaseUrls() {
    final urls = <String>[
      "http://localhost:8080/api/admin",
      "http://127.0.0.1:8080/api/admin",
      "http://172.27.66.99:8080/api/admin",
    ];

    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != "localhost" && host != "127.0.0.1") {
        final scheme = Uri.base.scheme.isEmpty ? "http" : Uri.base.scheme;
        urls.insert(0, "$scheme://$host:8080/api/admin");
      }
      if (host == "localhost" || host == "127.0.0.1") {
        final scheme = Uri.base.scheme.isEmpty ? "http" : Uri.base.scheme;
        urls.insert(0, "$scheme://$host:8080/api/admin");
      }
    }

    urls.insert(0, _defaultBaseUrl);

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
        print("🌐 Trying API base: $baseUrl");
        final response = await request(
          baseUrl,
        ).timeout(const Duration(seconds: 15));
        _activeBaseUrl = baseUrl;
        return response;
      } catch (e) {
        lastError = e;
        print("❌ Failed with base $baseUrl: $e");
      }
    }

    throw Exception("All API base URLs failed. Last error: $lastError");
  }

  // Get token from SharedPreferences
  static Future<String> _getToken() async {
    return AppSession.getToken();
  }

  // Get request headers with auth
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // Create new paket les
  static Future<Map<String, dynamic>> createPaket(
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _getHeaders();
      print("🔥 REQUEST BODY: ${jsonEncode(data)}");

      final response = await _requestWithFallback(
        (baseUrl) => http.post(
          Uri.parse("$baseUrl/paket-les"),
          headers: headers,
          body: jsonEncode(data),
        ),
      );

      print("🔥 STATUS CODE: ${response.statusCode}");
      print("🔥 RESPONSE BODY: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "error",
          "message": "Failed to create paket: ${response.statusCode}",
          "detail": response.body,
        };
      }
    } catch (e) {
      print("❌ ERROR API: $e");
      return {
        "status": "error",
        "message": "API Error",
        "detail": e.toString(),
      };
    }
  }

  // Get all paket les with optional filters
  static Future<List<Map<String, dynamic>>> getPaketLesList({
    String? status,
    String? search,
  }) async {
    try {
      Map<String, String> queryParams = {};

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final headers = await _getHeaders();

      final response = await _requestWithFallback(
        (baseUrl) => http.get(
          Uri.parse("$baseUrl/paket-les").replace(queryParameters: queryParams),
          headers: headers,
        ),
      );

      print("🔥 GET LIST STATUS CODE: ${response.statusCode}");
      print("🔥 GET LIST RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['data'] is List) {
          return List<Map<String, dynamic>>.from(
            jsonResponse['data'].map((x) => Map<String, dynamic>.from(x)),
          );
        }
        return [];
      } else {
        print("❌ ERROR: Got status code ${response.statusCode}");
        print("❌ ERROR BODY: ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ ERROR API: ClientException: $e");
      print("❌ ERROR TYPE: ${e.runtimeType}");
      return [];
    }
  }

  // Get single paket detail
  static Future<Map<String, dynamic>?> getPaketDetail(int id) async {
    try {
      final headers = await _getHeaders();

      final response = await _requestWithFallback(
        (baseUrl) =>
            http.get(Uri.parse("$baseUrl/paket-les/$id"), headers: headers),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return Map<String, dynamic>.from(jsonResponse['data'] ?? {});
      } else {
        return null;
      }
    } catch (e) {
      print("❌ ERROR API: $e");
      return null;
    }
  }

  // Update paket les
  static Future<Map<String, dynamic>> updatePaket(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _getHeaders();
      print("🔥 REQUEST BODY: ${jsonEncode(data)}");

      final response = await _requestWithFallback(
        (baseUrl) => http.put(
          Uri.parse("$baseUrl/paket-les/$id"),
          headers: headers,
          body: jsonEncode(data),
        ),
      );

      // ignore: avoid_print
      print("🔥 UPDATE STATUS CODE: ${response.statusCode}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "error",
          "message": "Failed to update paket: ${response.statusCode}",
          "detail": response.body,
        };
      }
    } catch (e) {
      // ignore: avoid_print
      print("❌ ERROR API: $e");
      return {
        "status": "error",
        "message": "API Error",
        "detail": e.toString(),
      };
    }
  }

  // Delete paket les
  static Future<Map<String, dynamic>> deletePaket(int id) async {
    try {
      final headers = await _getHeaders();

      final response = await _requestWithFallback(
        (baseUrl) =>
            http.delete(Uri.parse("$baseUrl/paket-les/$id"), headers: headers),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "error",
          "message": "Failed to delete paket: ${response.statusCode}",
          "detail": response.body,
        };
      }
    } catch (e) {
      print("❌ ERROR API: $e");
      return {
        "status": "error",
        "message": "API Error",
        "detail": e.toString(),
      };
    }
  }

  // Get paket statistics
  static Future<Map<String, dynamic>> getPaketStats() async {
    try {
      final headers = await _getHeaders();

      final response = await _requestWithFallback(
        (baseUrl) =>
            http.get(Uri.parse("$baseUrl/paket-les-stats"), headers: headers),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return Map<String, dynamic>.from(jsonResponse['data'] ?? {});
      } else {
        return {"total_paket": 0, "paket_aktif": 0};
      }
    } catch (e) {
      // ignore: duplicate_ignore
      // ignore: avoid_print
      print("❌ ERROR API: $e");
      return {"total_paket": 0, "paket_aktif": 0};
    }
  }

  // Format harga to Rupiah
  static String formatRupiah(int harga) {
    // ignore: prefer_interpolation_to_compose_strings
    return "Rp" +
        harga.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  // Calculate harga promo
  static int calculateHargaPromo(int hargaAwal, int diskon) {
    if (diskon == 0) return hargaAwal;
    return (hargaAwal * (100 - diskon) / 100).toInt();
  }
}
