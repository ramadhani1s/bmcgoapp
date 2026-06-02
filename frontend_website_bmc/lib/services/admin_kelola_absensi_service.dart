import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/admin_kelola_absensi.dart';

class AbsensiService {
  static String get baseUrl => AuthService.baseUrl;

  static Future<List<Absensi>> getAbsensi() async {
    final res = await http.get(Uri.parse('$baseUrl/api/absensi'));

    if (kDebugMode) {
      debugPrint(res.statusCode.toString());
      debugPrint(res.body);
    }

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Absensi.fromJson(e)).toList();
    } else {
      throw Exception('Gagal ambil data absensi');
    }
  }
}
