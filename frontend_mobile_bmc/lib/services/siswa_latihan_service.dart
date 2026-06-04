import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend_mobile_bmc/config/api_config.dart';
import '../core/session/app_session.dart';
import '../models/soal_model.dart';

class SiswaLatihanService {
  static Future<List<SoalModel>> getSoalBySubject(String subject) async {
    try {
      final token = await AppSession.getAuthToken();

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/siswa/latihan')
          .replace(queryParameters: {'subject': subject});

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final List<dynamic> list = data['data'] ?? [];
      
      return list.map((json) => SoalModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getSoalBySubject: $e');
      return [];
    }
  }
}