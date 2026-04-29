// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../models/materi_pembelajaran.dart';

class MateriService {
  // Ganti dengan base URL API Anda jika berbeda
  static const String baseUrl = 'http://localhost:8080/mentor/materi';

  static Future<List<MateriPembelajaran>> getMateri(int mentorId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?mentor_id=$mentorId'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MateriPembelajaran.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load materi');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
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
