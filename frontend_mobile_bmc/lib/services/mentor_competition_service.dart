import 'dart:convert';

import 'package:frontend_mobile_bmc/core/network/api_client.dart';
import 'package:frontend_mobile_bmc/models/mentor_competition_item.dart';

class MentorCompetitionService {
  static final ApiClient _client = ApiClient(baseUrl: 'http://10.0.2.2:8080/api/mentor');

  static String _normalizeDateForApi(String value) {
    final raw = value.trim();
    if (raw.isEmpty) {
      return raw;
    }
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
      return raw;
    }

    final parts = raw.split('/');
    if (parts.length == 3) {
      final dd = parts[0].padLeft(2, '0');
      final mm = parts[1].padLeft(2, '0');
      final yyyy = parts[2];
      if (yyyy.length == 4) {
        return '$yyyy-$mm-$dd';
      }
    }
    return raw;
  }

  static int _extractDurationMinutes(String label) {
    final digits = RegExp(r'\d+').firstMatch(label)?.group(0);
    return int.tryParse(digits ?? '') ?? 0;
  }

  static Future<List<MentorCompetitionItem>> getByType(
    String type, {
    String? classLevel,
  }) async {
    final endpoint = type == 'olimpiade' ? 'olimpiade' : 'tryout';
    final response = await _client.get('/$endpoint', auth: true);

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat data $type (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (decoded['data'] as List<dynamic>? ?? const []);

    final items = list.whereType<Map<String, dynamic>>().map((row) {
      if (type == 'olimpiade') {
        final dateText = row['tanggal']?.toString() ?? '';
        return MentorCompetitionItem(
          id: row['id'].toString(),
          type: 'olimpiade',
          classLevel: row['class_level']?.toString().isNotEmpty == true
              ? row['class_level'].toString()
              : 'Kelas 12',
          title: row['nama']?.toString() ?? '',
          subject: row['lokasi']?.toString().isNotEmpty == true
              ? row['lokasi'].toString()
              : '-',
          totalQuestions: 0,
          durationLabel: '-',
          scheduleLabel: dateText,
          isPublished: true,
          createdAt: DateTime.tryParse(dateText) ?? DateTime.now(),
          categoryQuestions: const {},
        );
      }

      final dateText = row['tanggal']?.toString() ?? '';
      final duration = int.tryParse(row['durasi']?.toString() ?? '0') ?? 0;
      return MentorCompetitionItem(
        id: row['id'].toString(),
        type: 'tryout',
        classLevel: row['class_level']?.toString().isNotEmpty == true
            ? row['class_level'].toString()
            : 'Kelas 12',
        title: row['judul']?.toString() ?? '',
        subject: 'Try Out Online',
        totalQuestions: 0,
        durationLabel: duration.toString(),
        scheduleLabel: dateText,
        isPublished: true,
        createdAt: DateTime.tryParse(dateText) ?? DateTime.now(),
        categoryQuestions: const {},
      );
    }).toList();

    final filtered = items.where((e) {
      if (classLevel == null || classLevel == 'Semua Kelas') {
        return true;
      }
      return e.classLevel == classLevel;
    }).toList();

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  static Future<void> createOrUpdate(MentorCompetitionItem item) async {
    if (item.type == 'olimpiade') {
      final body = {
        'class_level': item.classLevel,
        'nama': item.title,
        'tanggal': _normalizeDateForApi(item.scheduleLabel),
        'lokasi': item.subject,
      };

      final isUpdate = int.tryParse(item.id) != null;
      final response = isUpdate
          ? await _client.put('/olimpiade/${item.id}', auth: true, body: body)
          : await _client.post('/olimpiade', auth: true, body: body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Gagal menyimpan olimpiade (${response.statusCode})');
      }
      return;
    }

    final body = {
      'paket_id': 1,
      'class_level': item.classLevel,
      'judul': item.title,
      'tanggal': _normalizeDateForApi(item.scheduleLabel),
      'durasi': _extractDurationMinutes(item.durationLabel),
    };

    final isUpdate = int.tryParse(item.id) != null;
    final response = isUpdate
      ? await _client.put('/tryout/${item.id}', auth: true, body: body)
      : await _client.post('/tryout', auth: true, body: body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal menyimpan tryout (${response.statusCode})');
    }
  }

  static Future<void> deleteById(String id, {String type = 'tryout'}) async {
    final endpoint = type == 'olimpiade' ? 'olimpiade' : 'tryout';
    final response = await _client.delete('/$endpoint/$id', auth: true);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal menghapus data (${response.statusCode})');
    }
  }
}
