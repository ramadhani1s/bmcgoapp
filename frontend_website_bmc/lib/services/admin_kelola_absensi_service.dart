import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin_kelola_absensi.dart';

class AbsensiService {
  static const String baseUrl = 'http://localhost:8080';

  static Future<List<Absensi>> getAbsensi() async {
    final res = await http.get(Uri.parse('$baseUrl/api/absensi'));

    print(res.statusCode);
    print(res.body);

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Absensi.fromJson(e)).toList();
    } else {
      throw Exception('Gagal ambil data absensi');
    }
  }
}