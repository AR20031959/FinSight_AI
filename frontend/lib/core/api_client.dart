import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static String _baseUrl = "http://127.0.0.1:8000/api";
  static String? _authToken;

  static String get baseUrl => _baseUrl;

  static void setBaseUrl(String url) {
    if (url.trim().isNotEmpty) {
      _baseUrl = url.trim();
    }
  }

  static void setAuthToken(String token) {
    _authToken = token;
  }

  static Map<String, String> _headers({bool isMultipart = false}) {
    final map = <String, String>{};
    if (!isMultipart) {
      map['Content-Type'] = 'application/json';
    }
    if (_authToken != null && _authToken!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_authToken';
    }
    return map;
  }

  static Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    Uri uri = Uri.parse("$baseUrl$path");
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }
    try {
      final res = await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 10));
      return _processResponse(res);
    } catch (e) {
      return null;
    }
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse("$baseUrl$path");
    try {
      final res = await http
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 12));
      return _processResponse(res);
    } catch (e) {
      return null;
    }
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse("$baseUrl$path");
    try {
      final res = await http
          .put(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 12));
      return _processResponse(res);
    } catch (e) {
      return null;
    }
  }

  static Future<dynamic> delete(String path) async {
    final uri = Uri.parse("$baseUrl$path");
    try {
      final res = await http.delete(uri, headers: _headers()).timeout(const Duration(seconds: 8));
      return _processResponse(res);
    } catch (e) {
      return null;
    }
  }

  static String? getAuthToken() => _authToken;

  static Future<List<int>?> getBytes(String path, {Map<String, String>? queryParams}) async {
    Uri uri = Uri.parse("$baseUrl$path");
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }
    try {
      final res = await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 30));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return res.bodyBytes;
      } else if (res.statusCode == 401) {
        throw Exception("Authentication required (HTTP 401). Please re-login.");
      } else {
        throw Exception("Server returned error HTTP ${res.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  static dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return true;
      return jsonDecode(response.body);
    }
    if (response.statusCode >= 400 && response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('detail')) {
          return {'error': decoded['detail']};
        }
      } catch (_) {}
    }
    return null;
  }
}
