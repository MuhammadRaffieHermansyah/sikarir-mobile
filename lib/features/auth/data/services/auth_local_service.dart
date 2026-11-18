import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sikarir/features/auth/data/models/auth_models.dart';

class AuthLocalService {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyName = 'auth_name';
  static const String _keyEmail = 'auth_email';
  static const String _keyUserData = 'auth_user_data';

  final SharedPreferences? prefs;

  AuthLocalService({this.prefs});

  Future<SharedPreferences> _getPrefs() async {
    return prefs ?? await SharedPreferences.getInstance();
  }

  /// Menyimpan sesi user (token & profil) ke SharedPreferences
  Future<void> saveUserSession(LoginResponse user) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_keyToken, user.token);
      await prefs.setString(_keyUserId, user.userId);
      await prefs.setString(_keyName, user.name);
      await prefs.setString(_keyEmail, user.email);
      await prefs.setString(_keyUserData, json.encode(user.toMap()));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving user session: $e');
      }
    }
  }

  /// Mengambil sesi user yang tersimpan di SharedPreferences
  Future<LoginResponse?> getUserSession() async {
    try {
      final prefs = await _getPrefs();
      final token = prefs.getString(_keyToken);

      if (token == null || token.isEmpty) {
        return null;
      }

      // Coba pulihkan dari JSON lengkap jika ada
      final rawUserData = prefs.getString(_keyUserData);
      if (rawUserData != null && rawUserData.isNotEmpty) {
        try {
          final Map<String, dynamic> data = json.decode(rawUserData);
          return LoginResponse.fromMap(data);
        } catch (_) {}
      }

      // Fallback menggunakan individual field
      final userId = prefs.getString(_keyUserId) ?? '';
      final name = prefs.getString(_keyName) ?? '';
      final email = prefs.getString(_keyEmail) ?? '';

      return LoginResponse(
        token: token,
        userId: userId,
        name: name,
        email: email,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting user session: $e');
      }
      return null;
    }
  }

  /// Mengambil token tersimpan
  Future<String?> getToken() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_keyToken);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting token: $e');
      }
      return null;
    }
  }

  /// Menghapus seluruh sesi user (dipanggil saat logout)
  Future<void> clearUserSession() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyName);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyUserData);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing user session: $e');
      }
    }
  }

  /// Memeriksa apakah sesi login tersimpan aktif
  Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
