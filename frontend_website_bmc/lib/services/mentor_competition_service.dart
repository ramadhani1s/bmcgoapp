import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/mentor_competition_item.dart';
import 'auth_service.dart';

class MentorCompetitionService {
  static String get _baseUrl => AuthService.baseUrl;

  static int _extractDurationMinutes(String raw, {int fallback = 60}) {
    final onlyDigits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final minutes = int.tryParse(onlyDigits);
    if (minutes == null || minutes <= 0) {
      return fallback;
    }
    return minutes;
  }

  static String _extractError(
    dynamic data, {
    String fallback = 'Terjadi kesalahan',
  }) {
    if (data is Map<String, dynamic>) {
      final message = data['details'] ?? data['error'] ?? data['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    return fallback;
  }

  // ==================== GET BY TYPE (DIPERBAIKI) ====================
  static Future<List<MentorCompetitionItem>> getByType(
    String type, {
    String? classLevel,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final endpoint = type == 'olimpiade' ? 'olimpiade' : 'tryout';
      final response = await http
          .get(Uri.parse('$_baseUrl/api/mentor/$endpoint'), headers: headers)
          .timeout(const Duration(seconds: 15));

      print('========== GET BY TYPE ==========');
      print('URL: $_baseUrl/api/mentor/$endpoint');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==================================');

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (data['data'] as List<dynamic>? ?? const []);

      final items = <MentorCompetitionItem>[];
      
      for (final raw in list) {
        final row = raw as Map<String, dynamic>;
        final rawCategories = row['category_questions'];
        final parsedCategories = <String, int>{};
        if (rawCategories is Map) {
          for (final entry in rawCategories.entries) {
            parsedCategories['${entry.key}'] =
                int.tryParse('${entry.value}') ?? 0;
          }
        }

        // Ambil total_questions dari response API
        int totalQuestions = row['total_questions'] ?? 0;
        
        print('📊 ID: ${row['id']}, Total Soal dari response: $totalQuestions');
        
        items.add(MentorCompetitionItem.fromJson({
          'id': row['id'],
          'type': type,
          'class_level': row['class_level'],
          'title': row['judul'] ?? row['nama'],
          'subject': '-', // 🔥 SUBJEK DI SET MENJADI '-'
          'totalQuestions': totalQuestions,
          'soal_terbuat': row['soal_terbuat'] ?? 0,
          'durationLabel': row['durasi']?.toString() ?? (type == 'olimpiade' ? '120' : '60'),
          'scheduleLabel': row['tanggal'] ?? '',
          'isPublished': true,
          'createdAt': row['tanggal'] ?? DateTime.now().toIso8601String(),
          'categoryQuestions': parsedCategories,
        }));
      }

      final filtered = classLevel == null || classLevel == 'Semua Kelas'
          ? items
          : items.where((e) => e.classLevel == classLevel).toList();

      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    } catch (e) {
      print('ERROR getByType: $e');
      return [];
    }
  }

  // ==================== CREATE OR UPDATE ====================
  static Future<Map<String, dynamic>> createOrUpdate({
    required String type,
    int? id,
    required String classLevel,
    required String title,
    required String scheduleLabel,
    required String durationLabel,
    required int totalQuestions,
    Map<String, int> categoryQuestions = const {},
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final endpoint = type == 'olimpiade' ? 'olimpiade' : 'tryout';
      final isUpdate = id != null && id > 0;

      print('========== CREATE OR UPDATE ==========');
      print('Type: $type');
      print('Is Update: $isUpdate');
      print('Title: $title');
      print('Schedule: $scheduleLabel');
      print('Duration: $durationLabel');
      print('Total Questions: $totalQuestions');
      print('Class Level: $classLevel');
      print('=======================================');

      final body = type == 'olimpiade'
          ? {
              'class_level': classLevel,
              'nama': title,
              'tanggal': scheduleLabel,
              'total_questions': totalQuestions,
              'category_questions': categoryQuestions,
            }
          : {
              'paket_id': 0,
              'class_level': classLevel,
              'judul': title,
              'tanggal': scheduleLabel,
              'durasi': _extractDurationMinutes(
                durationLabel,
                fallback: totalQuestions > 0 ? totalQuestions : 60,
              ),
              'total_questions': totalQuestions,
              'category_questions': categoryQuestions,
            };

      print('Request Body: ${jsonEncode(body)}');

      final request = isUpdate
          ? await http.put(
              Uri.parse('$_baseUrl/api/mentor/$endpoint/$id'),
              headers: headers,
              body: jsonEncode(body),
            )
          : await http.post(
              Uri.parse('$_baseUrl/api/mentor/$endpoint'),
              headers: headers,
              body: jsonEncode(body),
            );

      print('Response Status: ${request.statusCode}');
      print('Response Body: ${request.body}');

      final data = request.body.isNotEmpty ? jsonDecode(request.body) : {};
      if (request.statusCode == 200 || request.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Berhasil disimpan',
        };
      }

      return {
        'success': false,
        'message': _extractError(data, fallback: 'Gagal menyimpan data'),
      };
    } catch (e) {
      print('ERROR createOrUpdate: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ==================== DELETE BY ID ====================
  static Future<Map<String, dynamic>> deleteById(String type, int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final endpoint = type == 'olimpiade' ? 'olimpiade' : 'tryout';
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/mentor/$endpoint/$id'),
        headers: headers,
      );

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Data berhasil dihapus',
        };
      }

      return {
        'success': false,
        'message': _extractError(data, fallback: 'Gagal menghapus data'),
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}