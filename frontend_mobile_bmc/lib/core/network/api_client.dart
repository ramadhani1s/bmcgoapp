import 'dart:convert';
import 'package:frontend_mobile_bmc/core/session/app_session.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl;

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath').replace(
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      headers['Authorization'] = 'Bearer ${await AppSession.getAuthToken()}';
    }
    return headers;
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParameters,
    bool auth = false,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return http
        .get(
          _uri(path, queryParameters: queryParameters),
          headers: await _headers(auth: auth),
        )
        .timeout(timeout);
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    bool auth = false,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return http
        .post(
          _uri(path),
          headers: await _headers(auth: auth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(timeout);
  }

  Future<http.Response> put(
    String path, {
    Object? body,
    bool auth = false,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return http
        .put(
          _uri(path),
          headers: await _headers(auth: auth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(timeout);
  }

  Future<http.Response> delete(
    String path, {
    bool auth = false,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return http
        .delete(
          _uri(path),
          headers: await _headers(auth: auth),
        )
        .timeout(timeout);
  }
}