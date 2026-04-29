// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_website_bmc/models/mentor.dart';
import '../models/user.dart';

class AuthService {
  // =====================================================
  // BASE URL
  // =====================================================
  static const String baseUrl = 'http://127.0.0.1:8080';

  // =====================================================
  // LOGIN
  // =====================================================
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim(),
              'password': password.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        final user = User.fromJson(data['user']);

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', data['token'].toString());
        await prefs.setString('user', jsonEncode(user.toJson()));

        return {
          'success': true,
          'user': user,
          'token': data['token'],
          'message': data['message'] ?? 'Login berhasil',
        };
      }

      return {'success': false, 'message': data['error'] ?? 'Login gagal'};
    } on TimeoutException {
      return {'success': false, 'message': 'Server timeout'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // =====================================================
  // LOGOUT
  // =====================================================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('user');
  }

  // =====================================================
  // GET CURRENT USER
  // =====================================================
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();

    final userJson = prefs.getString('user');

    if (userJson == null) {
      return null;
    }

    return User.fromJson(jsonDecode(userJson));
  }

  // =====================================================
  // TOKEN
  // =====================================================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }

  // =====================================================
  // HEADERS
  // =====================================================
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // =====================================================
  // VALIDATE TOKEN
  // =====================================================
  static Future<bool> validateToken() async {
    try {
      final headers = await getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/api/profile'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // =====================================================
  // CREATE MENTOR
  // =====================================================
  static Future<Map<String, dynamic>> createMentor({
    required String email,
    required String password,
    required String namaMentor,
    String mataPelajaran = '',
  }) async {
    try {
      final headers = await getAuthHeaders();

      final response = await http
          .post(
            Uri.parse('$baseUrl/mentor/'),
            headers: headers,
            body: jsonEncode({
              'email': email.trim(),
              'password': password.trim(),
              'nama_mentor': namaMentor.trim(),
              'mata_pelajaran': mataPelajaran.trim(),
              'status': 'Aktif',
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Mentor berhasil dibuat',
        };
      }

      return {
        'success': false,
        'message': data['error'] ?? 'Gagal membuat mentor',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // =====================================================
  // GET ALL MENTOR
  // =====================================================
  static Future<List<Mentor>> getMentors() async {
    try {
      final headers = await getAuthHeaders();

      final response = await http
          .get(Uri.parse('$baseUrl/mentor/'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print('getMentors error: ${response.statusCode} - ${response.body}');
        return [];
      }

      final body = jsonDecode(response.body);

      // Backend bisa mengirim array langsung atau object dengan "data" key
      List data;
      if (body is List) {
        data = body;
      } else if (body is Map && body['data'] is List) {
        data = body['data'];
      } else {
        print('getMentors: unexpected response format: $body');
        return [];
      }

      return data
          .map((item) => Mentor.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('getMentors exception: $e');
      return [];
    }
  }

  // =====================================================
  // UPDATE MENTOR
  // =====================================================
  static Future<Map<String, dynamic>> updateMentor(
    int id,
    String nama,
    String email,
    String mataPelajaran, {
    String password = '',
  }) async {
    try {
      final headers = await getAuthHeaders();

      final body = {
        'nama_mentor': nama.trim(),
        'email': email.trim(),
        'mata_pelajaran': mataPelajaran.trim(),
        'status': 'Aktif',
      };

      if (password.trim().isNotEmpty) {
        body['password'] = password.trim();
      }

      final response = await http.put(
        Uri.parse('$baseUrl/mentor/$id'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? data['error'] ?? 'Update selesai',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // =====================================================
  // DELETE MENTOR
  // =====================================================
  static Future<Map<String, dynamic>> deleteMentor(int mentorId) async {
    try {
      final headers = await getAuthHeaders();

      final response = await http
          .delete(Uri.parse('$baseUrl/mentor/$mentorId'), headers: headers)
          .timeout(const Duration(seconds: 15));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Mentor berhasil dihapus',
        };
      }

      return {
        'success': false,
        'message': data['error'] ?? 'Gagal hapus mentor',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
