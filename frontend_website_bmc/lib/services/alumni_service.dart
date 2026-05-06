import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alumni.dart';
import 'auth_service.dart';

class AlumniService {
  static const String baseUrl = AuthService.baseUrl;

  static Future<List<Alumni>> getAllAlumni() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/api/admin/alumni'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        // debug log to help diagnose empty list issues
        try {
          print(
            'AlumniService.getAllAlumni: status=${response.statusCode} body=${response.body}',
          );
        } catch (_) {}
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (data['data'] as List<dynamic>? ?? const []);

      return list
          .map((item) => Alumni.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Alumni?> getAlumniById(int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/api/admin/alumni/$id'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Alumni.fromJson(data['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> createAlumni(Alumni alumni) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/admin/alumni'),
            headers: headers,
            body: jsonEncode(alumni.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        // debug log
        try {
          print('AlumniService.createAlumni: created id=${data['id']}');
        } catch (_) {}
        return {
          'success': true,
          'message': data['message'] ?? 'Alumni berhasil ditambahkan',
          'id': data['id'],
        };
      }

      // debug log for failure
      try {
        print(
          'AlumniService.createAlumni: status=${response.statusCode} body=${response.body}',
        );
      } catch (_) {}
      return {
        'success': false,
        'message':
            data['error'] ?? data['message'] ?? 'Gagal menambahkan alumni',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateAlumni(Alumni alumni) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/api/admin/alumni/${alumni.id}'),
            headers: headers,
            body: jsonEncode(alumni.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Alumni berhasil diperbarui',
        };
      }

      return {
        'success': false,
        'message':
            data['error'] ?? data['message'] ?? 'Gagal memperbarui alumni',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteAlumni(int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .delete(Uri.parse('$baseUrl/api/admin/alumni/$id'), headers: headers)
          .timeout(const Duration(seconds: 15));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Alumni berhasil dihapus',
        };
      }

      return {
        'success': false,
        'message': data['error'] ?? data['message'] ?? 'Gagal menghapus alumni',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
