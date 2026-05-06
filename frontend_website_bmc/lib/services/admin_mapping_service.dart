import 'dart:convert';
import 'package:frontend_website_bmc/core/session/app_session.dart';
import 'package:http/http.dart' as http;

class AdminMappingService {
  static const _baseCandidates = [
    'http://127.0.0.1:8080',
    'http://localhost:8080',
    'http://172.27.66.99:8080',
  ];

  static Future<String> _getToken() async {
    return AppSession.getToken();
  }

  static Map<String, dynamic> _decodeResponse(http.Response res) {
    if (res.body.isEmpty) return {};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'raw': decoded};
    } catch (_) {
      return {'raw': res.body};
    }
  }

  static Future<List<dynamic>> getMappings() async {
    final token = await _getToken();
    for (final base in _baseCandidates) {
      try {
        final res = await http.get(
          Uri.parse('$base/api/admin/mappings'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (res.statusCode == 200) {
          final decoded = _decodeResponse(res);
          if (decoded['data'] is List<dynamic>) {
            return decoded['data'] as List<dynamic>;
          }
          return [];
        }
      } catch (_) {}
    }
    return [];
  }

  static Future<List<dynamic>> getUsers() async {
    final token = await _getToken();
    for (final base in _baseCandidates) {
      try {
        final res = await http.get(
          Uri.parse('$base/api/admin/mappings/users'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (res.statusCode == 200) {
          final decoded = _decodeResponse(res);
          if (decoded['data'] is List<dynamic>) {
            return decoded['data'] as List<dynamic>;
          }
          return [];
        }
      } catch (_) {}
    }
    return [];
  }

  static Future<Map<String, dynamic>> syncMappings() async {
    final token = await _getToken();
    for (final base in _baseCandidates) {
      try {
        final res = await http.post(
          Uri.parse('$base/api/admin/mappings/sync'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        final decoded = _decodeResponse(res);
        if (res.statusCode == 200) {
          return {
            'status': 'success',
            'message': decoded['message'] ?? 'Sinkron berhasil',
          };
        }
        return {
          'status': 'error',
          'message':
              decoded['message'] ?? decoded['error'] ?? 'Gagal sinkron mapping',
          'detail': decoded['detail'] ?? decoded['raw'],
        };
      } catch (e) {
        continue;
      }
    }
    return {'status': 'error', 'message': 'Gagal konek ke server mapping'};
  }

  static Future<Map<String, dynamic>> updateMapping(
    int adminId,
    int userId,
  ) async {
    final token = await _getToken();
    final body = jsonEncode({'user_id': userId});
    for (final base in _baseCandidates) {
      try {
        final res = await http.put(
          Uri.parse('$base/api/admin/mappings/$adminId'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body,
        );
        final decoded = _decodeResponse(res);
        if (res.statusCode == 200) {
          return {
            'status': 'success',
            'message': decoded['message'] ?? 'Mapping berhasil diperbarui',
          };
        }
        return {
          'status': 'error',
          'message':
              decoded['message'] ??
              decoded['error'] ??
              'Gagal memperbarui mapping',
          'detail': decoded['detail'] ?? decoded['raw'],
        };
      } catch (e) {
        continue;
      }
    }
    return {'status': 'error', 'message': 'Gagal konek ke server mapping'};
  }
}
