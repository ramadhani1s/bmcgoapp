import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/admin_dashboard_data.dart';

class AdminDashboardService {
  static const String baseUrl = 'http://localhost:8080';

  static Future<AdminDashboardData> getDashboardData() async {
    final token = await _getToken();
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/admin/dashboard'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat data dashboard admin');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>? ?? const {};
    return AdminDashboardData.fromJson(data);
  }

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }
    return token;
  }
}
