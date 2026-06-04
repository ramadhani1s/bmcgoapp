import 'dart:convert';
import 'package:frontend_mobile_bmc/core/network/api_client.dart';
import 'package:frontend_mobile_bmc/config/api_config.dart';

class AttendanceService {
  static final ApiClient _client = ApiClient(baseUrl: '${ApiConfig.baseUrl}/api');

  static Future<Map<String, dynamic>> submitToken(String tokenValue) async {
    try {
      final response = await _client.post(
        '/siswa/attendance/submit',
        auth: true,
        body: {'token': tokenValue.trim()},
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

      final response = await _client.get(
        '/siswa/attendance/history',
        auth: true,
        queryParameters: query.isEmpty ? null : query,
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

  static Future<Map<String, dynamic>> getActiveSessionForSiswa() async {
    try {
      final response = await _client.get(
        '/siswa/attendance/active',
        auth: true,
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
}
