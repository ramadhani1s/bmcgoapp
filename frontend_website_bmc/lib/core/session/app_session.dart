import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  static const String _tokenKey = 'token';
  static const String _userKey = 'user';

  static Future<SharedPreferences> _prefs() async {
    return SharedPreferences.getInstance();
  }

  static Future<void> save({
    required String token,
    required String userJson,
  }) async {
    final prefs = await _prefs();
    await prefs.setString(_tokenKey, token.trim());
    await prefs.setString(_userKey, userJson.trim());
  }

  static Future<String> getToken() async {
    final prefs = await _prefs();
    final token = (prefs.getString(_tokenKey) ?? prefs.getString('auth_token') ?? '').trim();
    if (token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }
    return token;
  }

  static Future<String?> getUserJson() async {
    final prefs = await _prefs();
    final userJson = prefs.getString(_userKey);
    if (userJson == null || userJson.trim().isEmpty) {
      return null;
    }
    return userJson;
  }

  static Future<void> clear() async {
    final prefs = await _prefs();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove('auth_token');
  }
}