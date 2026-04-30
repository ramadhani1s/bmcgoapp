import 'dart:convert';
import 'package:http/http.dart' as http;

class JadwalMobileService {
  static const String baseUrl = "http://172.27.66.99:8080/api";

  // Get jadwal by hari (public endpoint)
  static Future<List<Map<String, dynamic>>> getJadwalByHari(String hari) async {
    try {
      final url = Uri.parse(
        "$baseUrl/jadwal-by-hari",
      ).replace(queryParameters: {'hari': hari});

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = List<Map<String, dynamic>>.from(data['data'] ?? []);
        return list;
      }
      return [];
    } catch (e) {
      print("❌ ERROR: $e");
      return [];
    }
  }

  // Get semua jadwal (public endpoint)
  static Future<List<Map<String, dynamic>>> getAllJadwal() async {
    try {
      final url = Uri.parse("$baseUrl/jadwal");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = List<Map<String, dynamic>>.from(data['data'] ?? []);
        return list;
      }
      return [];
    } catch (e) {
      print("❌ ERROR: $e");
      return [];
    }
  }
}
