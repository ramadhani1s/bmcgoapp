import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  static const String _authTokenKey = 'auth_token';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';
  static const String _userStatusKey = 'user_status';

  static Future<SharedPreferences> _prefs() async {
    return SharedPreferences.getInstance();
  }

  static Future<void> saveAuthSession({
    required Map<String, dynamic> user,
    String? token,
    String? fallbackEmail,
  }) async {
    final prefs = await _prefs();

    final resolvedToken = (token ?? '').trim();
    if (resolvedToken.isNotEmpty) {
      await prefs.setString(_authTokenKey, resolvedToken);
    }

    await prefs.setString(
      _userNameKey,
      user['nama']?.toString().trim().isNotEmpty == true
          ? user['nama'].toString()
          : 'User',
    );
    await prefs.setString(
      _userEmailKey,
      user['email']?.toString().trim().isNotEmpty == true
          ? user['email'].toString()
          : (fallbackEmail ?? 'user@example.com'),
    );
    await prefs.setString(
      _userPhoneKey,
      user['whatsapp']?.toString().trim().isNotEmpty == true
          ? user['whatsapp'].toString()
          : '08xxxxxxxxxx',
    );
    await prefs.setString(
      _userStatusKey,
      user['status']?.toString().trim().isNotEmpty == true
          ? user['status'].toString()
          : 'inactive',
    );
  }

  static Future<void> saveUserStatus(String status) async {
    final prefs = await _prefs();
    await prefs.setString(
      _userStatusKey,
      status.trim().isNotEmpty ? status.trim() : 'inactive',
    );
  }

  // ✅ FIXED: return null kalau token tidak ada, bukan throw Exception
  static Future<String?> getAuthToken() async {
    final prefs = await _prefs();
    final token = prefs.getString(_authTokenKey)?.trim() ?? '';
    return token.isEmpty ? null : token;
  }

  static Future<String> getUserName() async {
    final prefs = await _prefs();
    return prefs.getString(_userNameKey) ?? 'User';
  }

  static Future<String> getUserEmail() async {
    final prefs = await _prefs();
    return prefs.getString(_userEmailKey) ?? 'user@example.com';
  }

  static Future<String> getUserPhone() async {
    final prefs = await _prefs();
    return prefs.getString(_userPhoneKey) ?? '08xxxxxxxxxx';
  }

  static Future<String> getUserStatus() async {
    final prefs = await _prefs();
    return prefs.getString(_userStatusKey) ?? 'inactive';
  }

  static Future<void> clear() async {
    final prefs = await _prefs();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userStatusKey);
  }
}