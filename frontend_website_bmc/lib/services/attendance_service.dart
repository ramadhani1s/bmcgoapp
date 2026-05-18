import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AttendanceService {
  static String get _baseUrl => '${AuthService.baseUrl}/api';

  static Future<Map<String, dynamic>> startSession({
    required String className,
    String subject = '',
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/mentor/attendance/start'),
        headers: headers,
        body: jsonEncode({
          'class_name': className.trim(),
          'subject': subject.trim(),
        }),
      );

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, ...body};
      }

      return {
        'success': false,
        'message': (body['error'] ?? 'Gagal memulai absensi').toString(),
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> getActiveSession() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/mentor/attendance/active'),
        headers: headers,
      );

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode == 200) {
        return {'success': true, ...body};
      }

      return {
        'success': false,
        'message': (body['error'] ?? 'Gagal mengambil sesi aktif').toString(),
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSessionSummary(int sessionId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/mentor/attendance/sessions/$sessionId/summary'),
        headers: headers,
      );

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode == 200) {
        return {'success': true, ...body};
      }

      return {
        'success': false,
        'message': (body['error'] ?? 'Gagal mengambil ringkasan absensi').toString(),
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
