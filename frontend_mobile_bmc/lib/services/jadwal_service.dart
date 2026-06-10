import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend_mobile_bmc/config/api_config.dart';

class JadwalMobileService {
  // Get jadwal by hari (public endpoint)
  static Future<List<Map<String, dynamic>>> getJadwalByHari(String hari) async {
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/api/jadwal-by-hari",
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
      final url = Uri.parse("${ApiConfig.baseUrl}/api/jadwal");
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
