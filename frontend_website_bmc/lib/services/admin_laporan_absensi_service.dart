import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/admin_laporan_absensi.dart';

class AbsensiService {
  static String get baseUrl => AuthService.baseUrl;

  static Future<Map<String, dynamic>> getAbsensi() async {
    final headers = await AuthService.getAuthHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/api/admin/absensi'),
      headers: headers,
    );

    if (kDebugMode) {
      debugPrint(res.statusCode.toString());
      debugPrint(res.body);
    }

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      final list = data.map((e) => Absensi.fromJson(e)).toList();
      return {
        'list': list,
        'totalSesi': res.headers['x-total-sesi'] ?? '0',
        'totalHadir': res.headers['x-total-hadir'] ?? '0',
        'totalTidakHadir': res.headers['x-total-tidak-hadir'] ?? '0',
      };
    } else {
      throw Exception('Gagal ambil data absensi');
    }
  }

  static Future<bool> resetAllAbsensi() async {
    final headers = await AuthService.getAuthHeaders();
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/admin/absensi/reset'),
        headers: headers,
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
