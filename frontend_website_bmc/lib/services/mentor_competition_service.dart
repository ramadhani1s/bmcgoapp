import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/mentor_competition_item.dart';
import 'auth_service.dart';

class MentorCompetitionService {
  static const String _baseUrl = AuthService.baseUrl;

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

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (data['data'] as List<dynamic>? ?? const []);

      final items = list.map((raw) {
        final row = raw as Map<String, dynamic>;
        return MentorCompetitionItem.fromJson({
          'id': row['id'],
          'type': type,
          'class_level': row['class_level'],
          'title': row['judul'] ?? row['nama'],
          'subject': row['lokasi'] ?? 'Try Out Online',
          'totalQuestions': row['total_questions'] ?? 0,
          'durationLabel': row['durasi'] ?? '-',
          'scheduleLabel': row['tanggal'] ?? '',
          'isPublished': true,
          'createdAt': row['tanggal'] ?? DateTime.now().toIso8601String(),
          'categoryQuestions': row['categoryQuestions'] ?? const {},
        });
      }).toList();

      final filtered = classLevel == null || classLevel == 'Semua Kelas'
          ? items
          : items.where((e) => e.classLevel == classLevel).toList();

      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createOrUpdate({
    required String type,
    int? id,
    required String classLevel,
    required String title,
    required String subject,
    required String scheduleLabel,
    required String durationLabel,
    required int totalQuestions,
    Map<String, int> categoryQuestions = const {},
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final endpoint = type == 'olimpiade' ? 'olimpiade' : 'tryout';
      final isUpdate = id != null && id > 0;

      final body = type == 'olimpiade'
          ? {
              'class_level': classLevel,
              'nama': title,
              'tanggal': scheduleLabel,
              'lokasi': subject,
            }
          : {
              'paket_id': 1,
              'class_level': classLevel,
              'judul': title,
              'tanggal': scheduleLabel,
              'durasi': int.tryParse(durationLabel) ?? totalQuestions,
            };

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

      final data = request.body.isNotEmpty ? jsonDecode(request.body) : {};
      if (request.statusCode == 200 || request.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Berhasil disimpan',
        };
      }

      return {
        'success': false,
        'message': data['error'] ?? 'Gagal menyimpan data',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

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
        'message': data['error'] ?? 'Gagal menghapus data',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
