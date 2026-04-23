import 'dart:convert';
import 'package:frontend_website_bmc/models/mentor.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:8080';

  // Login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);
        final token = data['token'];

        // Simpan token dan user data ke shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user', jsonEncode(user.toJson()));

        return {
          'success': true,
          'user': user,
          'token': token,
          'message': data['message'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['error'] ?? 'Login gagal'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // Get current user
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  // Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Get auth headers
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Validate token dengan backend
  static Future<bool> validateToken() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> createMentor({
    required String email,
    required String password,
    required String namaMentor,
    String spesialisasi = '',
    String bio = '',
  }) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/create-mentor'),
            headers: headers,
            body: jsonEncode({
              'email': email,
              'password': password,
              'nama_mentor': namaMentor,
              'spesialisasi': spesialisasi,
              'bio': bio,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Mentor berhasil dibuat',
        };
      }

      return {
        'success': false,
        'message': data['details'] ?? data['error'] ?? 'Gagal membuat mentor',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  static Future<List<Mentor>> getMentors() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/auth/mentors'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      final List<dynamic> list = data['data'] ?? [];
      return list.map((item) => Mentor.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> deleteMentor(int mentorId) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http
          .delete(
            Uri.parse('$baseUrl/auth/mentors/$mentorId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Mentor berhasil dihapus',
        };
      }

      return {
        'success': false,
        'message': data['details'] ?? data['error'] ?? 'Gagal menghapus mentor',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }
}
