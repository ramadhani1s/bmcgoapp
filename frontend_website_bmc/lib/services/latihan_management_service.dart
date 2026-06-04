import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/latihan.dart';
import 'auth_service.dart';

class LatihanManagementService {
  static String get _baseUrl => AuthService.baseUrl;

  // ==================== GET ALL LATIHAN ====================
  static Future<List<Latihan>> getLatihan() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/mentor/latihan'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      print('========== GET LATIHAN ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=================================');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['data'] ?? [];
        return list.map((item) => Latihan.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('ERROR getLatihan: $e');
      return [];
    }
  }

  // ==================== GET LATIHAN BY ID ====================
  static Future<Latihan?> getLatihanById(int latihanId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/mentor/latihan/$latihanId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latihanData = data['data'];
        if (latihanData != null) {
          return Latihan.fromJson(latihanData);
        }
      }
      return null;
    } catch (e) {
      print('ERROR getLatihanById: $e');
      return null;
    }
  }

  // ==================== CREATE LATIHAN ====================
  static Future<Map<String, dynamic>> createLatihan({
    required String title,
    required String mapel,
    required int totalSoal,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      
      final body = jsonEncode({
        'title': title,
        'mapel': mapel,
        'total_soal': totalSoal,
        'status': 'Draft',
      });

      print('========== CREATE LATIHAN ==========');
      print('Request Body: $body');
      print('=====================================');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/mentor/latihan'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      print('========== RESPONSE CREATE LATIHAN ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==============================================');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Latihan berhasil dibuat',
          'data': data['data'] != null ? Latihan.fromJson(data['data']) : null,
        };
      }

      return {
        'success': false,
        'message': data['details'] ?? data['error'] ?? 'Gagal membuat latihan',
      };
    } catch (e) {
      print('ERROR createLatihan: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // ==================== UPDATE LATIHAN ====================
  static Future<Map<String, dynamic>> updateLatihan({
    required int latihanId,
    required String title,
    required String mapel,
    required int totalSoal,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .put(
            Uri.parse('$_baseUrl/api/mentor/latihan/$latihanId'),
            headers: headers,
            body: jsonEncode({
              'title': title,
              'mapel': mapel,
              'total_soal': totalSoal,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Latihan berhasil diupdate',
          'data': data['data'] != null ? Latihan.fromJson(data['data']) : null,
        };
      }

      return {
        'success': false,
        'message': data['details'] ?? data['error'] ?? 'Gagal mengupdate latihan',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // ==================== PUBLISH LATIHAN ====================
  static Future<Map<String, dynamic>> publishLatihan(int latihanId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .put(
            Uri.parse('$_baseUrl/api/mentor/latihan/$latihanId/publish'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Latihan berhasil dipublikasikan',
        };
      }

      return {
        'success': false,
        'message': data['details'] ?? data['error'] ?? 'Gagal mempublikasikan',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // ==================== DELETE LATIHAN ====================
  static Future<Map<String, dynamic>> deleteLatihan(int latihanId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/api/mentor/latihan/$latihanId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Latihan berhasil dihapus',
        };
      }

      return {
        'success': false,
        'message': data['details'] ?? data['error'] ?? 'Gagal menghapus',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }
}