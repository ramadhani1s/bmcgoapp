// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:frontend_website_bmc/core/session/app_session.dart';
import 'package:http/http.dart' as http;

class JadwalService {
  static const String _defaultAdminBaseUrl = "http://localhost:8080/api/admin";
  static const String _defaultPublicBaseUrl = "http://localhost:8080/api";
  static String? _activeAdminBaseUrl;
  static String? _activePublicBaseUrl;

  // ==================== AUTH & HEADERS ====================

  static Future<String> _getToken() async {
    return AppSession.getToken();
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Map<String, String> _getPublicHeaders() {
    return {"Content-Type": "application/json"};
  }

  // ==================== BASE URL CANDIDATES ====================

  static List<String> _candidateAdminBaseUrls() {
    final urls = <String>[
      'http://127.0.0.1:8080/api/admin',
      'http://localhost:8080/api/admin',
      'http://10.0.2.2:8080/api/admin',
      'http://172.27.66.99:8080/api/admin',
    ];

    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        final scheme = Uri.base.scheme.isEmpty ? 'http' : Uri.base.scheme;
        urls.insert(0, '$scheme://$host:8080/api/admin');
      }
      if (host == 'localhost' || host == '127.0.0.1') {
        final scheme = Uri.base.scheme.isEmpty ? 'http' : Uri.base.scheme;
        urls.insert(0, '$scheme://$host:8080/api/admin');
      }
    }

    urls.insert(0, _defaultAdminBaseUrl);

    if (_activeAdminBaseUrl != null && _activeAdminBaseUrl!.isNotEmpty) {
      urls.insert(0, _activeAdminBaseUrl!);
    }

    return urls.toSet().toList();
  }

  static List<String> _candidatePublicBaseUrls() {
    final urls = <String>[
      'http://127.0.0.1:8080/api',
      'http://localhost:8080/api',
      'http://10.0.2.2:8080/api',
      'http://172.27.66.99:8080/api',
    ];

    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        final scheme = Uri.base.scheme.isEmpty ? 'http' : Uri.base.scheme;
        urls.insert(0, '$scheme://$host:8080/api');
      }
      if (host == 'localhost' || host == '127.0.0.1') {
        final scheme = Uri.base.scheme.isEmpty ? 'http' : Uri.base.scheme;
        urls.insert(0, '$scheme://$host:8080/api');
      }
    }

    urls.insert(0, _defaultPublicBaseUrl);

    if (_activePublicBaseUrl != null && _activePublicBaseUrl!.isNotEmpty) {
      urls.insert(0, _activePublicBaseUrl!);
    }

    return urls.toSet().toList();
  }

  // ==================== REQUEST WITH FALLBACK ====================

  static Future<http.Response> _requestAdminWithFallback(
    Future<http.Response> Function(String baseUrl) request,
  ) async {
    Object? lastError;

    for (final baseUrl in _candidateAdminBaseUrls()) {
      try {
        final response = await request(baseUrl).timeout(const Duration(seconds: 15));
        _activeAdminBaseUrl = baseUrl;
        return response;
      } catch (e) {
        lastError = e;
        print('❌ ADMIN API failed on $baseUrl: $e');
      }
    }

    throw Exception('All admin API base URLs failed. Last error: $lastError');
  }

  static Future<http.Response> _requestPublicWithFallback(
    Future<http.Response> Function(String baseUrl) request,
  ) async {
    Object? lastError;

    for (final baseUrl in _candidatePublicBaseUrls()) {
      try {
        final response = await request(baseUrl).timeout(const Duration(seconds: 15));
        _activePublicBaseUrl = baseUrl;
        return response;
      } catch (e) {
        lastError = e;
        print('❌ PUBLIC API failed on $baseUrl: $e');
      }
    }

    throw Exception('All public API base URLs failed. Last error: $lastError');
  }

  // ==================== HELPER ====================

  static List<Map<String, dynamic>> _parseListResponse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item.cast<String, dynamic>()))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item.cast<String, dynamic>()))
            .toList();
      }
    }

    return [];
  }

  // ==================== CREATE JADWAL (ADMIN) ====================
  static Future<Map<String, dynamic>> createJadwal(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();

      print("🔥 CREATE JADWAL: ${jsonEncode(data)}");

      final response = await _requestAdminWithFallback(
        (baseUrl) => http.post(
          Uri.parse('$baseUrl/jadwal'),
          headers: headers,
          body: jsonEncode(data),
        ),
      );

      print("🔥 STATUS: ${response.statusCode}");
      print("🔥 RESPONSE: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          "success": true,
          "status": "success",
          "message": result['message'] ?? "Jadwal berhasil dibuat",
          "data": result['data'],
        };
      } else {
        return {
          "success": false,
          "status": "error",
          "message": "Failed to create jadwal: ${response.statusCode}",
          "detail": response.body,
        };
      }
    } catch (e) {
      print("❌ ERROR createJadwal: $e");
      return {
        "success": false,
        "status": "error",
        "message": "API Error: ${e.toString()}",
        "detail": e.toString(),
      };
    }
  }

  // ==================== GET ALL JADWAL (ADMIN) ====================
  static Future<List<Map<String, dynamic>>> getJadwalList({
    int? paketId,
    int? mentorId,
    String? hari,
  }) async {
    try {
      Map<String, String> queryParams = {};

      if (paketId != null) queryParams['paket_id'] = paketId.toString();
      if (mentorId != null) queryParams['mentor_id'] = mentorId.toString();
      if (hari != null && hari.isNotEmpty) queryParams['hari'] = hari;

      final headers = await _getHeaders();

      final response = await _requestAdminWithFallback(
        (baseUrl) => http.get(
          Uri.parse('$baseUrl/jadwal').replace(
            queryParameters: queryParams.isNotEmpty ? queryParams : null,
          ),
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        return _parseListResponse(response.body);
      }
      return [];
    } catch (e) {
      print("❌ ERROR getJadwalList: $e");
      return [];
    }
  }

  // ==================== GET JADWAL BY ID (ADMIN) ====================
  static Future<Map<String, dynamic>> getJadwalDetail(int id) async {
    try {
      final headers = await _getHeaders();

      final response = await _requestAdminWithFallback(
        (baseUrl) => http.get(Uri.parse('$baseUrl/jadwal/$id'), headers: headers),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      return {};
    } catch (e) {
      print("❌ ERROR getJadwalDetail: $e");
      return {};
    }
  }

  // ==================== UPDATE JADWAL (ADMIN) ====================
  static Future<Map<String, dynamic>> updateJadwal(int id, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();

      final response = await _requestAdminWithFallback(
        (baseUrl) => http.put(
          Uri.parse('$baseUrl/jadwal/$id'),
          headers: headers,
          body: jsonEncode(data),
        ),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          "success": true,
          "status": "success",
          "message": result['message'] ?? "Jadwal berhasil diupdate",
          "data": result['data'],
        };
      } else {
        return {
          "success": false,
          "status": "error",
          "message": "Failed to update jadwal: ${response.statusCode}",
          "detail": response.body,
        };
      }
    } catch (e) {
      print("❌ ERROR updateJadwal: $e");
      return {
        "success": false,
        "status": "error",
        "message": "API Error: ${e.toString()}",
        "detail": e.toString(),
      };
    }
  }

  // ==================== DELETE JADWAL (ADMIN) ====================
  static Future<Map<String, dynamic>> deleteJadwal(int id) async {
    try {
      final headers = await _getHeaders();

      final response = await _requestAdminWithFallback(
        (baseUrl) => http.delete(Uri.parse('$baseUrl/jadwal/$id'), headers: headers),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          "success": true,
          "status": "success",
          "message": result['message'] ?? "Jadwal berhasil dihapus",
        };
      } else {
        return {
          "success": false,
          "status": "error",
          "message": "Failed to delete jadwal: ${response.statusCode}",
          "detail": response.body,
        };
      }
    } catch (e) {
      print("❌ ERROR deleteJadwal: $e");
      return {
        "success": false,
        "status": "error",
        "message": "API Error: ${e.toString()}",
        "detail": e.toString(),
      };
    }
  }

  // ==================== GET PAKET LIST (ADMIN) ====================
  static Future<List<Map<String, dynamic>>> getPaketList() async {
    try {
      final headers = await _getHeaders();

      final response = await _requestAdminWithFallback(
        (baseUrl) => http.get(Uri.parse('$baseUrl/paket-les'), headers: headers),
      );

      if (response.statusCode == 200) {
        return _parseListResponse(response.body);
      }
      return [];
    } catch (e) {
      print("❌ ERROR getPaketList: $e");
      return [];
    }
  }

  // ==================== GET MENTOR LIST (ADMIN) ====================
  static Future<List<Map<String, dynamic>>> getMentorList() async {
    try {
      final headers = await _getHeaders();

      final response = await _requestAdminWithFallback(
        (baseUrl) => http.get(
          Uri.parse('${baseUrl.replaceAll('/admin', '/auth')}/mentors'),
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        return _parseListResponse(response.body);
      }
      return [];
    } catch (e) {
      print("❌ ERROR getMentorList: $e");
      return [];
    }
  }

  // ==================== GET JADWAL BY HARI (PUBLIC - FOR STUDENTS) ====================
  static Future<List<Map<String, dynamic>>> getJadwalByHari(String hari) async {
    try {
      final headers = _getPublicHeaders();

      final response = await _requestPublicWithFallback(
        (baseUrl) => http.get(
          Uri.parse('$baseUrl/jadwal-by-hari').replace(queryParameters: {'hari': hari}),
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        return _parseListResponse(response.body);
      }
      return [];
    } catch (e) {
      print("❌ ERROR getJadwalByHari: $e");
      return [];
    }
  }

  // ==================== GET MENTOR JADWAL (MENTOR VIEW) ====================
  static Future<List<Map<String, dynamic>>> getMentorJadwalList() async {
    try {
      final headers = await _getHeaders();

      final response = await _requestPublicWithFallback(
        (baseUrl) => http.get(Uri.parse('$baseUrl/mentor/jadwal'), headers: headers),
      );

      if (response.statusCode == 200) {
        return _parseListResponse(response.body);
      }
      return [];
    } catch (e) {
      print("❌ ERROR getMentorJadwalList: $e");
      return [];
    }
  }
}