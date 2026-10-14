import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiClient {
  static String get defaultBaseUrl {
    if (kIsWeb) return "http://127.0.0.1:8000/api";
    try {
      if (Platform.isAndroid) {
        // Android emulator loopback alias to host machine
        return "http://10.0.2.2:8000/api";
      }
    } catch (_) {}
    return "http://127.0.0.1:8000/api";
  }

  static String _baseUrl = defaultBaseUrl;
  static String? _authToken;

  static String get baseUrl => _baseUrl;

  static void setBaseUrl(String url) {
    if (url.trim().isNotEmpty) {
      _baseUrl = url.trim();
    }
  }

  /// Tests connection to the backend and auto-selects working endpoint on Android (10.0.2.2 vs 127.0.0.1 via adb reverse)
  static Future<bool> checkHealth() async {
    final candidates = <String>[_baseUrl];
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          if (!_baseUrl.contains("10.0.2.2")) candidates.add("http://10.0.2.2:8000/api");
          if (!_baseUrl.contains("127.0.0.1")) candidates.add("http://127.0.0.1:8000/api");
        }
      } catch (_) {}
    }

    for (final candidate in candidates) {
      try {
        final hostRoot = candidate.replaceAll(RegExp(r'/api/?$'), '');
        final healthUri = Uri.parse('$hostRoot/api/health');
        final res = await http.get(healthUri).timeout(const Duration(milliseconds: 1500));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          _baseUrl = candidate;
          return true;
        }
      } catch (_) {
        try {
          final hostRoot = candidate.replaceAll(RegExp(r'/api/?$'), '');
          final rootUri = Uri.parse('$hostRoot/');
          final res = await http.get(rootUri).timeout(const Duration(milliseconds: 1500));
          if (res.statusCode >= 200 && res.statusCode < 300) {
            _baseUrl = candidate;
            return true;
          }
        } catch (_) {}
      }
    }
    return false;
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
      return {
        'error': 'Unable to connect to backend server. Please ensure the backend is running.',
        'connectionError': true,
      };
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
      return {
        'error': 'Unable to connect to backend server. Please ensure the backend is running.',
        'connectionError': true,
      };
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
      return {
        'error': 'Unable to connect to backend server. Please ensure the backend is running.',
        'connectionError': true,
      };
    }
  }

  static Future<dynamic> delete(String path) async {
    final uri = Uri.parse("$baseUrl$path");
    try {
      final res = await http.delete(uri, headers: _headers()).timeout(const Duration(seconds: 8));
      return _processResponse(res);
    } catch (e) {
      return {
        'error': 'Unable to connect to backend server. Please ensure the backend is running.',
        'connectionError': true,
      };
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
        if (decoded is Map) {
          if (decoded.containsKey('detail')) {
            final detail = decoded['detail'];
            if (detail is String) return {'error': detail};
            if (detail is List && detail.isNotEmpty) {
              final msg = detail.map((e) => e['msg'] ?? e.toString()).join(', ');
              return {'error': msg};
            }
            return {'error': detail.toString()};
          }
          if (decoded.containsKey('error')) {
            return {'error': decoded['error'].toString()};
          }
        }
      } catch (_) {}
    }
    return {'error': 'Server returned status code ${response.statusCode}'};
  }
}
