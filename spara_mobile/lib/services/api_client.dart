import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Error dari API Laravel (validasi, 401, server error, dsb.).
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors});

  final String message;
  final int? statusCode;
  final Map<String, List<String>>? errors;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Client HTTP tipis untuk backend SPARA (Laravel + JWT).
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  /// Bisa dioverride saat run/build:
  /// `flutter run --dart-define=SPARA_API_BASE_URL=http://192.168.1.10:8000/api/`
  static const String _envBaseUrl = String.fromEnvironment(
    'SPARA_API_BASE_URL',
  );

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl.endsWith('/') ? _envBaseUrl : '$_envBaseUrl/';
    }
    if (kIsWeb) return 'http://127.0.0.1:8000/api/';
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Emulator Android memetakan host PC ke 10.0.2.2.
      return 'http://10.0.2.2:8000/api/';
    }
    return 'http://127.0.0.1:8000/api/';
  }

  http.Client _http = http.Client();

  /// Ganti client HTTP (dipakai widget/unit test untuk memalsukan response).
  @visibleForTesting
  set httpClient(http.Client client) => _http = client;

  /// Kembalikan client ke kondisi awal (khusus test).
  @visibleForTesting
  void resetForTesting() {
    _token = null;
    _http = http.Client();
  }

  String? _token;

  String? get token => _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<dynamic> get(String path) async {
    return _send(() => _http.get(_uri(path), headers: _headers));
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    return _send(
      () => _http.post(
        _uri(path),
        headers: _headers,
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    );
  }

  Uri _uri(String path) {
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$baseUrl$clean');
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response response;
    try {
      response = await request().timeout(const Duration(seconds: 20));
    } catch (e) {
      throw ApiException(
        'Tidak dapat terhubung ke server. Pastikan backend berjalan di '
        '$baseUrl.',
      );
    }

    dynamic decoded;
    final raw = response.body;
    if (raw.isNotEmpty) {
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        decoded = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    var message = 'Terjadi kesalahan (${response.statusCode}).';
    Map<String, List<String>>? errors;

    if (decoded is Map) {
      if (decoded['message'] is String && (decoded['message'] as String).isNotEmpty) {
        message = decoded['message'] as String;
      }
      final rawErrors = decoded['errors'];
      if (rawErrors is Map) {
        errors = rawErrors.map(
          (key, value) => MapEntry(
            '$key',
            value is List ? value.map((e) => '$e').toList() : ['$value'],
          ),
        );
        if (errors.isNotEmpty) {
          message = errors.values.first.first;
        }
      }
    }

    throw ApiException(
      message,
      statusCode: response.statusCode,
      errors: errors,
    );
  }
}
