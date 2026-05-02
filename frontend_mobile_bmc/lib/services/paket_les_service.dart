import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaketLesService {
  static const String baseUrl = "http://172.27.66.99:8080/api";

  // Get token from SharedPreferences
  static Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token') ?? prefs.getString('auth_token');
    } catch (e) {
      debugPrint("Error getting token: $e");
      return null;
    }
  }

  // Get all active paket les (public endpoint - no auth needed)
  static Future<List<Map<String, dynamic>>> getPaketLesList({required String status}) async {
    try {
      final url = Uri.parse("$baseUrl/paket-les");

      debugPrint("GET PAKET LIST FROM: $url");

      final response = await http
          .get(url, headers: {"Content-Type": "application/json"})
          .timeout(const Duration(seconds: 10));

        debugPrint("STATUS CODE: ${response.statusCode}");
        debugPrint("RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // Check if response has data field
        if (jsonResponse['data'] is List) {
          List<Map<String, dynamic>> pakets = [];
          for (var item in jsonResponse['data']) {
            pakets.add(Map<String, dynamic>.from(item));
          }
          debugPrint("Found ${pakets.length} pakets");
          return pakets;
        }
        return [];
      } else {
        debugPrint("API Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("ERROR API: $e");
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

      final url = Uri.parse("$baseUrl/admin/paket-les");
      final headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      };

      debugPrint("CREATE PAKET FROM MOBILE: $data");

      final response = await http
          .post(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 10));

        debugPrint("CREATE STATUS: ${response.statusCode}");
        debugPrint("CREATE RESPONSE: ${response.body}");

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
      debugPrint("ERROR CREATE: $e");
      return {"status": "error", "message": "Error: $e"};
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
