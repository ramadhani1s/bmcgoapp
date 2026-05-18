// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../models/materi_pembelajaran.dart';
import 'auth_service.dart';

class MateriService {
  static String get baseUrl => '${AuthService.baseUrl}/mentor/materi';

  static Future<List<MateriPembelajaran>> getMateri(int mentorId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?mentor_id=$mentorId'),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = switch (decoded) {
          List<dynamic> value => value,
          Map<String, dynamic> value => _extractMaterialList(value),
          _ => <dynamic>[],
        };

        return data
            .whereType<Map<String, dynamic>>()
            .map(MateriPembelajaran.fromJson)
            .toList();
      } else {
        throw Exception('Failed to load materi (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static List<dynamic> _extractMaterialList(Map<String, dynamic> json) {
    final candidates = [
      json['data'],
      json['items'],
      json['materi'],
      json['result'],
    ];

    for (final candidate in candidates) {
      if (candidate is List<dynamic>) {
        return candidate;
      }
    }

    return const <dynamic>[];
  }

  static Future<bool> uploadMateri({
    required int mentorId,
    required String title,
    required String description,
    required PlatformFile file,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields['mentor_id'] = mentorId.toString();
      request.fields['title'] = title;
      request.fields['description'] = description;

      if (file.bytes != null) {
        // Untuk Flutter Web, gunakan fromBytes
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (file.path != null) {
        // Fallback untuk platform selain web (meski ini frontend web)
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path!,
            filename: file.name,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Upload failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Upload error: $e');
      return false;
    }
  }

  static Future<bool> deleteMateri(int materiId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$materiId'));

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Delete failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }
}
