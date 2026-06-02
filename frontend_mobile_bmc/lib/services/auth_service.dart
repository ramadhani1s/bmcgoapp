import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend_mobile_bmc/services/notification_service.dart';
import 'package:frontend_mobile_bmc/config/api_config.dart';

class AuthService {
  // Jika menjalankan Flutter di Android emulator, gunakan 10.0.2.2 untuk mengakses backend di localhost PC.
  // Jika menggunakan perangkat fisik, ganti dengan IP PC kamu, misalnya http://192.168.1.100:8080/auth

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final normalizedEmail = email.trim();
      final normalizedPassword = password.trim();

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': normalizedEmail,
              'password': normalizedPassword,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final user = body['user'];

        await NotificationService.saveTokenToBackend(user['id']);
        return body;
      } else if (response.statusCode == 401) {
        throw Exception((body['error'] ?? 'Email atau password salah').toString());
      } else {
        throw Exception((body['error'] ?? 'Login gagal: ${response.statusCode}').toString());
      }
    } on TimeoutException {
      throw Exception('Koneksi timeout. Cek backend atau internet kamu.');
    } on FormatException {
      throw Exception('Respons login tidak valid dari server.');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(e.toString());
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
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nama': nama,
              'kelas': kelas,
              'asal_sekolah': asalSekolah,
              'whatsapp': whatsapp,
              'alamat': alamat,
              'email': email,
              'password': password,
              'role_id': 3,
              'is_active': false,
            }),
          )
          .timeout(const Duration(seconds: 15));
          
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final error = (body['error'] ?? '').toString();
        final details = (body['details'] ?? '').toString();
        final errorMessage = details.isNotEmpty
            ? '$error ($details)'
            : (error.isNotEmpty
                  ? error
                  : 'Register gagal: ${response.statusCode}');
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      throw Exception(
        'Koneksi timeout. Backend mungkin belum jalan di port 8080.',
      );
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
