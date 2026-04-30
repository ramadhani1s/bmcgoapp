import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin_dashboard_data.dart';

class AdminDashboardService {
  static const String baseUrl = 'http://localhost:8080';

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

  static Future<AdminDashboardData> getSummary() async {
    final token = await _getToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl/api/admin/dashboard-summary'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return AdminDashboardData.fromJson(data);
      }
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Sesi admin tidak valid. Silakan login ulang.');
    }

    throw Exception('Gagal memuat ringkasan dashboard admin');
  }
}
