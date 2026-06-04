import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/soal_kompetisi.dart';
import 'auth_service.dart';

class SoalKompetisiService {
  static String get _baseUrl => AuthService.baseUrl;

  // ==================== GET SOAL ====================
  static Future<List<SoalKompetisi>> getSoalByKompetisi(
    int kompetisiId,
    String tipe,
  ) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final endpoint = tipe == 'olimpiade' ? 'olimpiade-soal' : 'tryout-soal';
      final url = '$_baseUrl/api/mentor/$endpoint?kompetisi_id=$kompetisiId';
      
      print('========== GET SOAL ==========');
      print('URL: $url');
      print('Tipe: $tipe, Kompetisi ID: $kompetisiId');
      
      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('============================================');

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      final List<dynamic> list = data['data'] ?? [];
      
      return list.map((item) => SoalKompetisi.fromJson(item)).toList();
    } catch (e) {
      print('ERROR getSoalByKompetisi: $e');
      return [];
    }
  }

  // ==================== CREATE SOAL ====================
  static Future<Map<String, dynamic>> createSoal({
    required int kompetisiId,
    required String tipe,
    required String pertanyaan,
    required String pilihanA,
    required String pilihanB,
    required String pilihanC,
    required String pilihanD,
    required String pilihanE,
    required String jawaban,
    required String pembahasan,
    String kategori = '',
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final endpoint = tipe == 'olimpiade' ? 'olimpiade-soal' : 'tryout-soal';
      final url = '$_baseUrl/api/mentor/$endpoint?kompetisi_id=$kompetisiId';
      
      final body = {
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
      };

      print('========== CREATE SOAL ==========');
      print('URL: $url');
      print('Tipe: $tipe, Kompetisi ID: $kompetisiId');
      print('Kategori: $kategori');
      print('Request Body: ${jsonEncode(body)}');
      print('==================================');

      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==================================');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Soal berhasil dibuat',
          'data': data['data'] != null ? SoalKompetisi.fromJson(data['data']) : null,
        };
      }

      return {
        'success': false,
        'message': 'Gagal membuat soal (HTTP ${response.statusCode})',
      };
    } catch (e) {
      print('ERROR createSoal: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // ==================== UPDATE SOAL ====================
  static Future<Map<String, dynamic>> updateSoal({
    required int soalId,
    required String tipe,
    required String pertanyaan,
    required String pilihanA,
    required String pilihanB,
    required String pilihanC,
    required String pilihanD,
    required String pilihanE,
    required String jawaban,
    required String pembahasan,
    String kategori = '',
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final endpoint = tipe == 'olimpiade' ? 'olimpiade-soal' : 'tryout-soal';
      final url = '$_baseUrl/api/mentor/$endpoint/$soalId';
      
      final body = {
        'pertanyaan': pertanyaan,
        'pilihan_a': pilihanA,
        'pilihan_b': pilihanB,
        'pilihan_c': pilihanC,
        'pilihan_d': pilihanD,
        'pilihan_e': pilihanE,
        'jawaban': jawaban,
        'pembahasan': pembahasan,
        'kategori': kategori,
      };

      print('========== UPDATE SOAL ==========');
      print('URL: $url');
      print('Soal ID: $soalId');
      print('Request Body: ${jsonEncode(body)}');
      print('=================================');

      final response = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=================================');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Soal berhasil diupdate',
        };
      }

      return {
        'success': false,
        'message': 'Gagal update soal (HTTP ${response.statusCode})',
      };
    } catch (e) {
      print('ERROR updateSoal: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // ==================== DELETE SOAL ====================
  static Future<Map<String, dynamic>> deleteSoal(
    int soalId,
    String tipe,
  ) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final endpoint = tipe == 'olimpiade' ? 'olimpiade-soal' : 'tryout-soal';
      final url = '$_baseUrl/api/mentor/$endpoint/$soalId';
      
      print('========== DELETE SOAL ==========');
      print('URL: $url');
      print('Soal ID: $soalId');
      print('=================================');

      final response = await http
          .delete(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      print('Status Code: ${response.statusCode}');
      print('=================================');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Soal berhasil dihapus',
        };
      }

      return {
        'success': false,
        'message': 'Gagal hapus soal (HTTP ${response.statusCode})',
      };
    } catch (e) {
      print('ERROR deleteSoal: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }
}