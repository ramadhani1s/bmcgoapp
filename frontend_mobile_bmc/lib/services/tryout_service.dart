import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/session/app_session.dart';
import 'package:frontend_mobile_bmc/config/api_config.dart';

class TryOutService {
  static final String _base = '${ApiConfig.baseUrl}';

  static Future<List<Map<String, dynamic>>> getPackages({String status = 'tersedia'}) async {
    try {
      final token = await AppSession.getAuthToken();
      print('TOKEN: ${await AppSession.getAuthToken()}');
      final res = await http.get(Uri.parse('$_base/api/siswa/tryout?status=$status'), headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['data'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getQuestions(int packageId) async {
    try {
      final token = await AppSession.getAuthToken();
      final res = await http.get(Uri.parse('$_base/api/siswa/tryout/$packageId/soal'), 
      headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['data'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> submitResult(int packageId, Map<int, String> answers) async {
    try {
      final token = await AppSession.getAuthToken();
      final body = jsonEncode({'jawaban': answers.map((k, v) => MapEntry(k.toString(), v))});
      final res = await http.post(Uri.parse('$_base/api/siswa/tryout/$packageId/submit'), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: body).timeout(const Duration(seconds: 15));
      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      if (res.statusCode != 200 && res.statusCode != 201) {
        return {'success': false, 'message': data['message'] ?? 'Gagal submit'};
      }
      return {'success': true, 'data': data['data'] ?? data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
