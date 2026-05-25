import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({required this.baseUrl});

  Future<http.Response> get(
    String endpoint, {
    bool auth = false,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = {...?headers};

    if (auth) {
      final token = await _getAuthToken();
      if (token != null) {
        requestHeaders['Authorization'] = 'Bearer $token';
      }
    }

    try {
      return await http.get(url, headers: requestHeaders);
    } catch (e) {
      return http.Response('{"error": "$e"}', 500);
    }
  }

  Future<http.Response> post(
    String endpoint, {
    required dynamic body,
    bool auth = false,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = {'Content-Type': 'application/json', ...?headers};

    if (auth) {
      final token = await _getAuthToken();
      if (token != null) {
        requestHeaders['Authorization'] = 'Bearer $token';
      }
    }

    try {
      final bodyString = body is String ? body : _encodeBody(body);
      return await http.post(url, headers: requestHeaders, body: bodyString);
    } catch (e) {
      return http.Response('{"error": "$e"}', 500);
    }
  }

  Future<http.Response> put(
    String endpoint, {
    required dynamic body,
    bool auth = false,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = {'Content-Type': 'application/json', ...?headers};

    if (auth) {
      final token = await _getAuthToken();
      if (token != null) {
        requestHeaders['Authorization'] = 'Bearer $token';
      }
    }

    try {
      final bodyString = body is String ? body : _encodeBody(body);
      return await http.put(url, headers: requestHeaders, body: bodyString);
    } catch (e) {
      return http.Response('{"error": "$e"}', 500);
    }
  }

  Future<http.Response> delete(
    String endpoint, {
    bool auth = false,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = {...?headers};

    if (auth) {
      final token = await _getAuthToken();
      if (token != null) {
        requestHeaders['Authorization'] = 'Bearer $token';
      }
    }

    try {
      return await http.delete(url, headers: requestHeaders);
    } catch (e) {
      return http.Response('{"error": "$e"}', 500);
    }
  }

  String _encodeBody(dynamic body) {
    if (body is String) return body;
    if (body is Map) {
      try {
        return _jsonEncode(body as Map<String, dynamic>);
      } catch (_) {
        return '{}';
      }
    }
    return '{}';
  }

  String _jsonEncode(Map<String, dynamic> map) {
    final buffer = StringBuffer('{');
    final entries = map.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.write('"${entry.key}":');
      buffer.write(_encodeValue(entry.value));
      if (i < entries.length - 1) buffer.write(',');
    }
    buffer.write('}');
    return buffer.toString();
  }

  String _encodeValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) {
      return '"${value.replaceAll('"', '\\"')}"';
    }
    if (value is bool || value is num) return value.toString();
    if (value is List) {
      final items = value.map(_encodeValue).join(',');
      return '[$items]';
    }
    if (value is Map) {
      return _jsonEncode(value as Map<String, dynamic>);
    }
    return '"$value"';
  }

  Future<String?> _getAuthToken() async {
    try {
      final token = await AuthService.getToken();
      return token;
    } catch (_) {
      return null;
    }
  }
}
