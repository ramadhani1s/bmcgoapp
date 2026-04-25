import 'dart:convert';

import 'package:frontend_mobile_bmc/models/mentor_competition_item.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MentorCompetitionService {
  static const String _baseUrl = 'http://10.0.2.2:8080/api/mentor';

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    if (token.isEmpty) {
      throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
    }
    return token;
  }

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

  static Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<MentorCompetitionItem>> getByType(
    String type, {
    String? classLevel,
  }) async {
    final token = await _getToken();
    final endpoint = type == 'olimpiade' ? 'olimpiade' : 'tryout';
    final response = await http.get(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: _headers(token),
    );

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
    final token = await _getToken();

    if (item.type == 'olimpiade') {
      final body = {
        'class_level': item.classLevel,
        'nama': item.title,
        'tanggal': _normalizeDateForApi(item.scheduleLabel),
        'lokasi': item.subject,
      };

      final isUpdate = int.tryParse(item.id) != null;
      final uri = isUpdate
          ? Uri.parse('$_baseUrl/olimpiade/${item.id}')
          : Uri.parse('$_baseUrl/olimpiade');
      final response = isUpdate
          ? await http.put(
              uri,
              headers: _headers(token),
              body: jsonEncode(body),
            )
          : await http.post(
              uri,
              headers: _headers(token),
              body: jsonEncode(body),
            );

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
    final uri = isUpdate
        ? Uri.parse('$_baseUrl/tryout/${item.id}')
        : Uri.parse('$_baseUrl/tryout');
    final response = isUpdate
        ? await http.put(uri, headers: _headers(token), body: jsonEncode(body))
        : await http.post(
            uri,
            headers: _headers(token),
            body: jsonEncode(body),
          );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal menyimpan tryout (${response.statusCode})');
    }
  }

  static Future<void> deleteById(String id, {String type = 'tryout'}) async {
    final token = await _getToken();
    final endpoint = type == 'olimpiade' ? 'olimpiade' : 'tryout';
    final response = await http.delete(
      Uri.parse('$_baseUrl/$endpoint/$id'),
      headers: _headers(token),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal menghapus data (${response.statusCode})');
    }
  }
}
