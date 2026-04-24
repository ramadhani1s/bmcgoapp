import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/soal_latihan.dart';
import 'auth_service.dart';

class LatihanSoalService {
  static const String _baseUrl = AuthService.baseUrl;

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
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Soal berhasil dibuat',
          'data': data['data'] != null
              ? SoalLatihan.fromJson(data['data'])
              : null,
        };
      }

      return {
        'success': false,
        'message': data['details'] ?? data['error'] ?? 'Gagal membuat soal',
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
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Soal berhasil diupdate',
          'data': data['data'] != null
              ? SoalLatihan.fromJson(data['data'])
              : null,
        };
      }

      return {
        'success': false,
        'message': data['details'] ?? data['error'] ?? 'Gagal mengupdate soal',
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

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Soal berhasil dihapus',
        };
      }

      return {
        'success': false,
        'message': data['details'] ?? data['error'] ?? 'Gagal menghapus soal',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }
}
