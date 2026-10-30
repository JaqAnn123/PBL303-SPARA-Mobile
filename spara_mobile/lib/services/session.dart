import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import 'api_client.dart';

/// Menyimpan token JWT + data user agar sesi tetap aktif setelah app ditutup.
class Session {
  Session._();

  static final Session instance = Session._();

  static const String _tokenKey = 'spara_access_token';
  static const String _userKey = 'spara_current_user';

  AppUser? _user;
  bool _loaded = false;

  AppUser? get user => _user;

  bool get isLoggedIn =>
      _loaded && ApiClient.instance.token != null && _user != null;

  bool get hasSession => isLoggedIn;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final rawUser = prefs.getString(_userKey);
    if (token != null && token.isNotEmpty) {
      ApiClient.instance.setToken(token);
      if (rawUser != null) {
        try {
          final decoded = jsonDecode(rawUser);
          if (decoded is Map) {
            _user = AppUser.fromJson(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {
          // Abaikan data korup.
        }
      }
    }
    _loaded = true;
  }

  Future<void> save({required String token, required AppUser user}) async {
    ApiClient.instance.setToken(token);
    _user = user;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Kosongkan sesi in-memory tanpa menyentuh storage (khusus test).
  @visibleForTesting
  void resetForTesting() {
    _user = null;
    _loaded = false;
    ApiClient.instance.setToken(null);
  }

  Future<void> updateUser(AppUser user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    ApiClient.instance.setToken(null);
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
