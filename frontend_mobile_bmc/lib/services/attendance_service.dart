import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceService {
  static const String _baseUrl = 'http://10.0.2.2:8080/api';

  static Future<String> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    if (token.isEmpty) {
      throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
    }
    return token;
  }

  static Future<Map<String, dynamic>> submitToken(String tokenValue) async {
    try {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/siswa/attendance/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'token': tokenValue.trim()}),
      );

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode == 200) {
        return {'success': true, ...body};
      }

      return {
        'success': false,
        'message': (body['error'] ?? 'Gagal kirim token absensi').toString(),
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<List<dynamic>> getHistory({
    String? className,
    DateTime? date,
  }) async {
    try {
      final token = await _getAuthToken();

      final query = <String, String>{};
      if (className != null && className.trim().isNotEmpty) {
        query['class_name'] = className.trim();
      }
      if (date != null) {
        final year = date.year.toString().padLeft(4, '0');
        final month = date.month.toString().padLeft(2, '0');
        final day = date.day.toString().padLeft(2, '0');
        query['date'] = '$year-$month-$day';
      }

      final uri = Uri.parse('$_baseUrl/siswa/attendance/history').replace(
        queryParameters: query.isEmpty ? null : query,
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200 || response.body.isEmpty) {
        return const [];
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['data'] as List<dynamic>? ?? const [];
    } catch (_) {
      return const [];
    }
  }
}
