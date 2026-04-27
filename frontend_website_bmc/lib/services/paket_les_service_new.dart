import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PaketLesService {
  static const String baseUrl = "http://localhost:8080/api/admin";

  // Get token from SharedPreferences
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        (prefs.getString('token') ?? prefs.getString('auth_token') ?? '')
            .trim();
    if (token.isEmpty) throw Exception('Token login tidak ditemukan');
    return token;
  }

  // Get request headers with auth token
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
      final url = Uri.parse("$baseUrl/paket-les");
      final headers = await _getHeaders();

      print("🔥 CREATE REQUEST URL: $url");
      print("🔥 REQUEST BODY: ${jsonEncode(data)}");

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
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
      String url = "$baseUrl/paket-les";
      Map<String, String> queryParams = {};

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (queryParams.isNotEmpty) {
        url +=
            '?' +
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final headers = await _getHeaders();

      print("🔥 GET LIST URL: $url");

      final response = await http.get(Uri.parse(url), headers: headers);

      print("🔥 GET LIST STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print("❌ ERROR GET LIST: $e");
      return [];
    }
  }

  // Get single paket detail
  static Future<Map<String, dynamic>?> getPaketDetail(int id) async {
    try {
      final url = Uri.parse("$baseUrl/paket-les/$id");
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print("❌ ERROR GET DETAIL: $e");
      return null;
    }
  }

  // Update paket les
  static Future<Map<String, dynamic>> updatePaket(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/paket-les/$id");
      final headers = await _getHeaders();

      print("🔥 UPDATE REQUEST URL: $url");
      print("🔥 UPDATE BODY: ${jsonEncode(data)}");

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(data),
      );

      print("🔥 UPDATE STATUS: ${response.statusCode}");
      print("🔥 UPDATE RESPONSE: ${response.body}");

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
      print("❌ ERROR UPDATE: $e");
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
      final url = Uri.parse("$baseUrl/paket-les/$id");
      final headers = await _getHeaders();

      final response = await http.delete(url, headers: headers);

      print("🔥 DELETE STATUS: ${response.statusCode}");

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
      print("❌ ERROR DELETE: $e");
      return {
        "status": "error",
        "message": "API Error",
        "detail": e.toString(),
      };
    }
  }

  // Get paket les stats
  static Future<Map<String, dynamic>> getPaketStats() async {
    try {
      final url = Uri.parse("$baseUrl/paket-les/stats/summary");
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return {"total_paket": 0, "paket_aktif": 0};
    } catch (e) {
      print("❌ ERROR GET STATS: $e");
      return {"total_paket": 0, "paket_aktif": 0};
    }
  }

  // Format harga to Rupiah
  static String formatRupiah(int harga) {
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
