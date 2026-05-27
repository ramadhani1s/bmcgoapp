import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/soal_latihan.dart';
import 'auth_service.dart';

class LatihanSoalService {
  static String get _baseUrl => AuthService.baseUrl;

  static Future<List<SoalLatihan>> getSoalLatihan() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .get(Uri.parse('$_baseUrl/api/mentor/soal-latihan'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      final List<dynamic> list = data['data'] ?? [];
      return list.map((item) => SoalLatihan.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createSoalLatihan({
    required String pertanyaan,
    required String pilihanA,
    required String pilihanB,
    required String pilihanC,
    required String pilihanD,
    required String jawaban,
    String pembahasan = '',
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/mentor/soal-latihan'),
            headers: headers,
            body: jsonEncode({
              'pertanyaan': pertanyaan,
              'pilihan_a': pilihanA,
              'pilihan_b': pilihanB,
              'pilihan_c': pilihanC,
              'pilihan_d': pilihanD,
              'jawaban': jawaban,
              'pembahasan': pembahasan,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode != 201 && response.statusCode != 200) {
        return {
          'success': false,
          'message':
              data['error'] ??
              data['message'] ??
              'Gagal menambah soal latihan (HTTP ${response.statusCode})',
          'details': data['details'],
          'statusCode': response.statusCode,
        };
      }

      return {
        'success': true,
        'message': data['message'] ?? 'Soal berhasil dibuat',
        'data': data['data'] != null
            ? SoalLatihan.fromJson(data['data'])
            : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> updateSoalLatihan({
    required int soalId,
    required String pertanyaan,
    required String pilihanA,
    required String pilihanB,
    required String pilihanC,
    required String pilihanD,
    required String jawaban,
    String pembahasan = '',
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .put(
            Uri.parse('$_baseUrl/api/mentor/soal-latihan/$soalId'),
            headers: headers,
            body: jsonEncode({
              'pertanyaan': pertanyaan,
              'pilihan_a': pilihanA,
              'pilihan_b': pilihanB,
              'pilihan_c': pilihanC,
              'pilihan_d': pilihanD,
              'jawaban': jawaban,
              'pembahasan': pembahasan,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message':
              data['error'] ??
              data['message'] ??
              'Gagal update soal latihan (HTTP ${response.statusCode})',
          'details': data['details'],
          'statusCode': response.statusCode,
        };
      }

      return {
        'success': true,
        'message': data['message'] ?? 'Soal berhasil diupdate',
        'data': data['data'] != null
            ? SoalLatihan.fromJson(data['data'])
            : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteSoalLatihan(int soalId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/api/mentor/soal-latihan/$soalId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message':
              data['error'] ??
              data['message'] ??
              'Gagal hapus soal latihan (HTTP ${response.statusCode})',
          'details': data['details'],
          'statusCode': response.statusCode,
        };
      }

      return {
        'success': true,
        'message': data['message'] ?? 'Soal berhasil dihapus',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }
}