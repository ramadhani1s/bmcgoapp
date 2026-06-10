// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:frontend_website_bmc/core/session/app_session.dart';
import 'package:http/http.dart' as http;
import 'package:frontend_website_bmc/models/mentor.dart';
import '../models/user.dart';

class AuthService {
  // =====================================================
  // BASE URL
  // =====================================================
  static const String _defaultBaseUrl = 'http://127.0.0.1:8080';

  static String get baseUrl {
    final fromEnv = const String.fromEnvironment('API_BASE_URL').trim();
    if (fromEnv.isNotEmpty) {
      return _sanitizeBaseUrl(fromEnv);
    }

    if (kIsWeb) {
      final host = Uri.base.host.trim();
      if (host.isNotEmpty) {
        final scheme = Uri.base.scheme == 'https' ? 'https' : 'http';
        return '$scheme://$host:8080';
      }
    }

    return _defaultBaseUrl;
  }

  static String _sanitizeBaseUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return _defaultBaseUrl;
    }
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }

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
            Uri.parse('$baseUrl/api/auth/login'),
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

      // Try to parse JSON response safely and log raw body on failure
      dynamic data = {};
      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body);
        } catch (e) {
          print('AuthService.login: failed to parse JSON response');
          print('Status: ${response.statusCode}');
          print('Body: ${response.body}');
          return {
            'success': false,
            'message': 'Invalid server response: ${response.body}',
          };
        }
      }

      if (response.statusCode == 200) {
        final payload = data is Map<String, dynamic>
            ? data
            : const <String, dynamic>{};
        final userMap = payload['user'];
        final token = payload['token']?.toString() ?? '';

        if (userMap is! Map<String, dynamic> || token.isEmpty) {
          return {
            'success': false,
            'message': 'Respons login tidak lengkap dari server.',
          };
        }

        final user = User.fromJson(userMap);

        await AppSession.save(
          token: token,
          userJson: jsonEncode(user.toJson()),
        );

        return {
          'success': true,
          'user': user,
          'token': token,
          'message': payload['message'] ?? 'Login berhasil',
        };
      }

      final payload = data is Map<String, dynamic>
          ? data
          : const <String, dynamic>{};
      return {
        'success': false,
        'message': payload['error'] ?? payload['message'] ?? 'Login gagal',
      };
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
    await AppSession.clear();
  }

  // =====================================================
  // GET CURRENT USER
  // =====================================================
  static Future<User?> getCurrentUser() async {
    final userJson = await AppSession.getUserJson();

    if (userJson == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(userJson);
      if (decoded is Map<String, dynamic>) {
        return User.fromJson(decoded);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  // =====================================================
  // TOKEN
  // =====================================================
  static Future<String?> getToken() async {
    try {
      return await AppSession.getToken();
    } catch (_) {
      return null;
    }
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
  // UPDATE PROFILE
  // =====================================================
  static Future<Map<String, dynamic>> updateProfile({
    required String nama,
    required String email,
    String oldPassword = '',
    String newPassword = '',
  }) async {
    try {
      final headers = await getAuthHeaders();

      final response = await http
          .put(
            Uri.parse('$baseUrl/api/profile'),
            headers: headers,
            body: jsonEncode({
              'nama': nama.trim(),
              'email': email.trim(),
              if (oldPassword.trim().isNotEmpty)
                'old_password': oldPassword.trim(),
              if (newPassword.trim().isNotEmpty)
                'new_password': newPassword.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        final userMap = data['user'];
        if (userMap is Map<String, dynamic>) {
          final updatedUser = User.fromJson(userMap);
          final currentToken = await getToken();
          if (currentToken != null) {
            await AppSession.save(
              token: currentToken,
              userJson: jsonEncode(updatedUser.toJson()),
            );
          }
          return {
            'success': true,
            'message': data['message'] ?? 'Profil berhasil diperbarui',
            'user': updatedUser,
          };
        }
      }

      return {
        'success': false,
        'message': data['error'] ?? 'Gagal memperbarui profil',
      };
    } on TimeoutException {
      return {'success': false, 'message': 'Koneksi timeout'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
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

      // Debug logging to help trace why created mentor may not appear.
      print('AuthService.createMentor -> status: ${response.statusCode}');
      print('AuthService.createMentor -> body: ${response.body}');

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

      print('getMentors -> body: ${response.body}');

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
    String status = '',
  }) async {
    try {
      final headers = await getAuthHeaders();

      final body = {
        'nama_mentor': nama.trim(),
        'email': email.trim(),
        'mata_pelajaran': mataPelajaran.trim(),
        if (status.isNotEmpty) 'status': status,
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
