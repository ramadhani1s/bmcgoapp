import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/soal_kompetisi.dart';
import 'auth_service.dart';

class SoalKompetisiService {
  static String get _baseUrl => AuthService.baseUrl;

  static Future<List<SoalKompetisi>> getSoalByKompetisi(
    int kompetisiId,
    String tipe,
  ) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/api/mentor/$tipe-soal?kompetisi_id=$kompetisiId',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      final List<dynamic> list = data['data'] ?? [];
      return list.map((item) => SoalKompetisi.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createSoal({
    required int kompetisiId,
    required String tipe,
    required String pertanyaan,
    required String pilihanA,
    required String pilihanB,
    required String pilihanC,
    required String pilihanD,
    String pilihanE = '',
    required String jawaban,
    String pembahasan = '',
    String kategori = '',
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final endpoint = tipe == 'olimpiade'
          ? '/api/mentor/olimpiade-soal'
          : '/api/mentor/tryout-soal';

      final response = await http
          .post(
            Uri.parse('$_baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode({
              'kompetisi_id': kompetisiId,
              'pertanyaan': pertanyaan,
              'pilihan_a': pilihanA,
              'pilihan_b': pilihanB,
              'pilihan_c': pilihanC,
              'pilihan_d': pilihanD,
              'pilihan_e': pilihanE,
              'jawaban': jawaban,
              'pembahasan': pembahasan,
              'kategori': kategori,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 201 && response.statusCode != 200) {
        String details = response.body;
        try {
          final parsed = jsonDecode(response.body);
          if (parsed is Map && parsed['error'] != null) {
            details = parsed['error'].toString();
          }
        } catch (_) {}
        if (kDebugMode) {
          debugPrint('createSoal error status=${response.statusCode} body=${response.body}');
        }

        return {
          'success': false,
          'message':
              'Endpoint tidak tersedia (HTTP ${response.statusCode}). Hubungi admin.',
          'statusCode': response.statusCode,
          'details': details,
        };
      }

      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': data['message'] ?? 'Soal berhasil dibuat',
        'data': data['data'] != null
            ? SoalKompetisi.fromJson(data['data'])
            : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> updateSoal({
    required int soalId,
    required String tipe,
    required String pertanyaan,
    required String pilihanA,
    required String pilihanB,
    required String pilihanC,
    required String pilihanD,
    String pilihanE = '',
    required String jawaban,
    String pembahasan = '',
    String kategori = '',
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final endpoint = tipe == 'olimpiade'
          ? '/api/mentor/olimpiade-soal/$soalId'
          : '/api/mentor/tryout-soal/$soalId';

      final response = await http
          .put(
            Uri.parse('$_baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode({
              'pertanyaan': pertanyaan,
              'pilihan_a': pilihanA,
              'pilihan_b': pilihanB,
              'pilihan_c': pilihanC,
              'pilihan_d': pilihanD,
              'pilihan_e': pilihanE,
              'jawaban': jawaban,
              'pembahasan': pembahasan,
              'kategori': kategori,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message':
              'Endpoint tidak tersedia (HTTP ${response.statusCode}). Hubungi admin.',
        };
      }

      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': data['message'] ?? 'Soal berhasil diupdate',
        'data': data['data'] != null
            ? SoalKompetisi.fromJson(data['data'])
            : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteSoal(
    int soalId,
    String tipe,
  ) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final endpoint = tipe == 'olimpiade'
          ? '/api/mentor/olimpiade-soal/$soalId'
          : '/api/mentor/tryout-soal/$soalId';

      final response = await http
          .delete(Uri.parse('$_baseUrl$endpoint'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message':
              'Endpoint tidak tersedia (HTTP ${response.statusCode}). Hubungi admin.',
        };
      }

      final data = jsonDecode(response.body);
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