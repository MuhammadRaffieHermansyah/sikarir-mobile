import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sikarir/features/auth/data/models/auth_models.dart';

class AuthLocalStorage {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyName = 'user_name';
  static const String _keyEmail = 'user_email';
  static const String _keyUserData = 'user_data';

  SharedPreferences? _prefs;

  AuthLocalStorage({SharedPreferences? prefs}) {
    if (prefs != null) {
      _prefs = prefs;
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Menyimpan token dan data login user ke SharedPreferences
  Future<void> saveLoginResponse(LoginResponse response) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_keyToken, response.token);
      await prefs.setString(_keyUserId, response.userId);
      await prefs.setString(_keyName, response.name);
      await prefs.setString(_keyEmail, response.email);
      await prefs.setString(_keyUserData, json.encode(response.toMap()));
      if (kDebugMode) {
        debugPrint('AuthLocalStorage: Token & data user berhasil disimpan.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthLocalStorage Error saving auth data: $e');
      }
    }
  }

  /// Menyimpan token dan data individual
  Future<void> saveAuthData({
    required String token,
    required String userId,
    required String name,
    required String email,
  }) async {
    final response = LoginResponse(
      token: token,
      userId: userId,
      name: name,
      email: email,
    );
    await saveLoginResponse(response);
  }

  /// Mengambil data login user yang tersimpan
  Future<LoginResponse?> getSavedAuthData() async {
    try {
      final prefs = await _getPrefs();
      final token = prefs.getString(_keyToken);

      if (token == null || token.trim().isEmpty) {
        return null;
      }

      final userId = prefs.getString(_keyUserId) ?? '';
      final name = prefs.getString(_keyName) ?? '';
      final email = prefs.getString(_keyEmail) ?? '';

      // Cek jika ada simpanan user_data json lengkap
      final rawData = prefs.getString(_keyUserData);
      if (rawData != null && rawData.isNotEmpty) {
        try {
          final map = json.decode(rawData);
          if (map is Map<String, dynamic>) {
            return LoginResponse.fromMap(map);
          }
        } catch (_) {}
      }

      return LoginResponse(
        token: token,
        userId: userId,
        name: name,
        email: email,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthLocalStorage Error reading auth data: $e');
      }
      return null;
    }
  }

  /// Mengambil token tersimpan saja
  Future<String?> getToken() async {
    try {
      final prefs = await _getPrefs();
      final token = prefs.getString(_keyToken);
      if (token != null && token.trim().isNotEmpty) {
        return token;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthLocalStorage Error reading token: $e');
      }
      return null;
    }
  }

  /// Mengecek apakah user sudah memiliki token aktif tersimpan
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Menghapus token dan semua data user saat logout
  Future<void> clearAuthData() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyName);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyUserData);
      if (kDebugMode) {
        debugPrint('AuthLocalStorage: Data session berhasil dibersihkan.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthLocalStorage Error clearing auth data: $e');
      }
    }
  }
}
