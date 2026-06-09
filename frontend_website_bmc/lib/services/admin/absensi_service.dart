import 'dart:convert';
import '../../core/session/app_session.dart';
import '../../core/network/api_client.dart';
import '../../models/admin_laporan_absensi.dart';

class AbsensiService {
  static final ApiClient _client = ApiClient(
    baseUrl: 'http://localhost:8080/api',
  );

  // ignore: unused_element
  static Future<String> _getToken() async {
    return AppSession.getToken();
  }

  static Future<List<Absensi>> getAbsensi({
    String? filter,
    String? search,
  }) async {
    try {
      String endpoint = '/admin/absensi';
      final params = <String>[];

      if (filter != null && filter.isNotEmpty) {
        params.add('filter=$filter');
      }
      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }

      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }

      final response = await _client.get(endpoint, auth: true);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch absensi data');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (decoded['data'] as List<dynamic>?) ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(Absensi.fromJson)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getAbsensiDetail(String id) async {
    try {
      final response = await _client.get('/admin/absensi/$id', auth: true);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch absensi detail');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return (decoded['data'] as Map<String, dynamic>?) ?? {};
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateAbsensi(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.put(
        '/admin/absensi/$id',
        body: data,
        auth: true,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to update absensi');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteAbsensi(String id) async {
    try {
      final response = await _client.delete('/admin/absensi/$id', auth: true);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to delete absensi');
      }
    } catch (e) {
      rethrow;
    }
  }
}
