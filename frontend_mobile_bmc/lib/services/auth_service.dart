import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Jika menjalankan Flutter di Android emulator, gunakan 10.0.2.2 untuk mengakses backend di localhost PC.
  // Jika menggunakan perangkat fisik, ganti dengan IP PC kamu, misalnya http://192.168.1.100:8080/auth
  static const String baseUrl = 'http://10.0.2.2:8080/auth';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Email atau password salah');
      } else {
        throw Exception('Login gagal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> register(
    String nama,
    String kelas,
    String asalSekolah,
    String whatsapp,
    String alamat,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nama': nama,
          'kelas': kelas,
          'asal_sekolah': asalSekolah,
          'whatsapp': whatsapp,
          'alamat': alamat,
          'email': email,
          'password': password,
          'role_id': 2,
          'is_active': false,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = jsonDecode(response.body);
        final errorMessage = body['error'] ?? 'Register gagal: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
