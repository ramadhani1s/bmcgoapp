import 'dart:convert';
import 'package:frontend_website_bmc/core/session/app_session.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class PengumumanService {
  static const _baseCandidates = [
    'http://127.0.0.1:8080',
    'http://localhost:8080',
    'http://172.27.66.99:8080',
  ];

  static Future<String> _getToken() async {
    return AppSession.getToken();
  }

  static Map<String, dynamic> _decodeResponse(http.Response res) {
    if (res.body.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'raw': decoded};
    } catch (_) {
      return {'raw': res.body};
    }
  }

  static Future<Map<String, dynamic>> createPengumuman(
    Map<String, dynamic> body,
  ) async {
    late final String token;
    try {
      token = await _getToken();
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Sesi login tidak valid, silakan login ulang',
        'detail': e.toString(),
      };
    }

    Object? lastNetworkError;
    for (final base in _baseCandidates) {
      final url = '$base/api/admin/pengumuman';
      try {
        final res = await http
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 15));

        final decoded = _decodeResponse(res);
        if (res.statusCode == 201 || res.statusCode == 200) {
          return {
            'status': 'success',
            'message': decoded['message'] ?? 'Pengumuman berhasil dibuat',
            'data': decoded['data'],
          };
        }

        // HTTP error means server is reachable; return immediately with real message.
        return {
          'status': 'error',
          'message':
              decoded['message'] ??
              decoded['error'] ??
              'Gagal membuat pengumuman',
          'detail': decoded['detail'] ?? decoded['raw'],
          'statusCode': res.statusCode,
          'url': url,
        };
      } catch (e) {
        lastNetworkError = e;
      }
    }

    return {
      'status': 'error',
      'message': 'Gagal konek ke server pengumuman',
      'detail': lastNetworkError?.toString(),
    };
  }

  static Future<List<dynamic>> getPengumumanList() async {
    for (final base in _baseCandidates) {
      try {
        final url = '$base/api/pengumuman';
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));
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

  static Future<Map<String, dynamic>> publishPengumuman(int id) async {
    final token = await _getToken();
    Object? lastNetworkError;
    for (final base in _baseCandidates) {
      try {
        final res = await http
            .post(
              Uri.parse('$base/api/admin/pengumuman/$id/publish'),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 15));

        final decoded = _decodeResponse(res);
        if (res.statusCode == 200) {
          return {
            'status': 'success',
            'message': decoded['message'] ?? 'Pengumuman berhasil diterbitkan',
            'data': decoded['data'],
          };
        }
        return {
          'status': 'error',
          'message':
              decoded['message'] ??
              decoded['error'] ??
              'Gagal publish pengumuman',
          'detail': decoded['detail'] ?? decoded['raw'],
          'statusCode': res.statusCode,
        };
      } catch (e) {
        lastNetworkError = e;
      }
    }
    return {
      'status': 'error',
      'message': 'Gagal konek ke server pengumuman',
      'detail': lastNetworkError?.toString(),
    };
  }

  static Future<Map<String, dynamic>> getPengumumanDetail(int id) async {
    Object? lastNetworkError;
    for (final base in _baseCandidates) {
      try {
        final url = '$base/api/pengumuman/$id';
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));
        if (res.statusCode == 200) {
          final decoded = _decodeResponse(res);
          return {'status': 'success', 'data': decoded['data']};
        }
        return {
          'status': 'error',
          'message': 'Pengumuman tidak ditemukan',
          'statusCode': res.statusCode,
        };
      } catch (e) {
        lastNetworkError = e;
      }
    }
    return {
      'status': 'error',
      'message': 'Gagal konek ke server pengumuman',
      'detail': lastNetworkError?.toString(),
    };
  }

  static Future<Map<String, dynamic>> updatePengumuman(
    int id,
    Map<String, dynamic> body,
  ) async {
    late final String token;
    try {
      token = await _getToken();
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Sesi login tidak valid, silakan login ulang',
        'detail': e.toString(),
      };
    }

    Object? lastNetworkError;
    for (final base in _baseCandidates) {
      final url = '$base/api/admin/pengumuman/$id';
      try {
        final res = await http
            .put(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 15));

        final decoded = _decodeResponse(res);
        if (res.statusCode == 200) {
          return {
            'status': 'success',
            'message': decoded['message'] ?? 'Pengumuman berhasil diperbarui',
            'data': decoded['data'],
          };
        }

        return {
          'status': 'error',
          'message':
              decoded['message'] ??
              decoded['error'] ??
              'Gagal memperbarui pengumuman',
          'detail': decoded['detail'] ?? decoded['raw'],
          'statusCode': res.statusCode,
        };
      } catch (e) {
        lastNetworkError = e;
      }
    }

    return {
      'status': 'error',
      'message': 'Gagal konek ke server pengumuman',
      'detail': lastNetworkError?.toString(),
    };
  }

  static Future<Map<String, dynamic>> deletePengumuman(int id) async {
    late final String token;
    try {
      token = await _getToken();
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Sesi login tidak valid, silakan login ulang',
        'detail': e.toString(),
      };
    }

    Object? lastNetworkError;
    for (final base in _baseCandidates) {
      final url = '$base/api/admin/pengumuman/$id';
      try {
        final res = await http
            .delete(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 15));

        final decoded = _decodeResponse(res);
        if (res.statusCode == 200) {
          return {
            'status': 'success',
            'message': decoded['message'] ?? 'Pengumuman berhasil dihapus',
            'data': decoded['data'],
          };
        }

        return {
          'status': 'error',
          'message':
              decoded['message'] ??
              decoded['error'] ??
              'Gagal menghapus pengumuman',
          'detail': decoded['detail'] ?? decoded['raw'],
          'statusCode': res.statusCode,
        };
      } catch (e) {
        lastNetworkError = e;
      }
    }

    return {
      'status': 'error',
      'message': 'Gagal konek ke server pengumuman',
      'detail': lastNetworkError?.toString(),
    };
  }
}
