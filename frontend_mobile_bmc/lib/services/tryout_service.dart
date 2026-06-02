import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/session/app_session.dart';

class TryOutService {
  static const String _base = 'http://10.0.2.2:8080';

  static Future<List<Map<String, dynamic>>> getPackages() async {
    try {
      final token = await AppSession.getAuthToken();
      final res = await http.get(Uri.parse('$_base/api/tryout/packages'), headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
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
      final res = await http.get(Uri.parse('$_base/api/tryout/$packageId/questions'), 
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
      final body = jsonEncode({'answers': answers.map((k, v) => MapEntry(k.toString(), v))});
      final res = await http.post(Uri.parse('$_base/api/tryout/$packageId/hasil'), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: body).timeout(const Duration(seconds: 15));
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
