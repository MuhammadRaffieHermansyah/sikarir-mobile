import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sikarir/core/constants/api_constants.dart';
import 'package:sikarir/features/profile/data/models/instructor_profile_model.dart';

/// Akses API akun: ganti password dan profil instruktur.
class AccountService {
  final http.Client client;

  AccountService({http.Client? client}) : client = client ?? http.Client();

  Map<String, String> _headers(String? token, {bool json = true}) => {
    'Accept': 'application/json',
    if (json) 'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  dynamic _decode(String body) {
    try {
      return body.isEmpty ? null : json.decode(body);
    } catch (_) {
      return null;
    }
  }

  Exception _error(http.Response res, String fallback) {
    if (res.statusCode == 401) {
      return Exception('Sesi berakhir. Silakan login kembali.');
    }
    final decoded = _decode(res.body);
    String? msg = decoded is Map ? decoded['message']?.toString() : null;
    if (decoded is Map && decoded['errors'] is Map) {
      final errors = decoded['errors'] as Map;
      if (errors.isNotEmpty && errors.values.first is List) {
        msg = (errors.values.first as List).first.toString();
      }
    }
    return Exception(msg ?? '$fallback (Kode: ${res.statusCode}).');
  }

  Future<T> _guard<T>(Future<T> Function() action, String fallback) async {
    try {
      return await action();
    } on http.ClientException catch (e) {
      if (kDebugMode) debugPrint('AccountService ClientException: $e');
      throw Exception(
        'Tidak dapat terhubung ke server. Periksa jaringan Anda.',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('AccountService error: $e');
      if (e is Exception) rethrow;
      throw Exception(fallback);
    }
  }

  /// `PUT /profile/password`.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmation,
    String? token,
  }) {
    return _guard(() async {
      final res = await client
          .put(
            Uri.parse(ApiConstants.profilePassword),
            headers: _headers(token),
            body: json.encode({
              'password_lama': oldPassword,
              'password_baru': newPassword,
              'password_baru_confirmation': confirmation,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw _error(res, 'Gagal mengganti password');
      }
    }, 'Gagal mengganti password.');
  }

  /// `GET /instruktur/me`. `null` bila belum tersedia di server (404).
  Future<InstructorProfile?> getInstructorProfile(String? token) {
    return _guard(() async {
      final res = await client
          .get(Uri.parse(ApiConstants.instrukturMe), headers: _headers(token))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 404) return null;
      if (res.statusCode != 200) throw _error(res, 'Gagal memuat profil');
      final decoded = _decode(res.body);
      if (decoded is! Map) return null;
      return InstructorProfile.fromMap(Map<String, dynamic>.from(decoded));
    }, 'Terjadi kesalahan saat memuat profil.');
  }

  /// `POST /instruktur/me` (multipart agar foto opsional dapat ikut dikirim).
  Future<InstructorProfile> updateInstructorProfile({
    required String name,
    required String phone,
    required String bio,
    required String expertise,
    String? photoPath,
    String? token,
  }) {
    return _guard(() async {
      final request =
          http.MultipartRequest('POST', Uri.parse(ApiConstants.instrukturMe))
            ..headers.addAll(_headers(token, json: false))
            ..fields['nama'] = name
            ..fields['nomor_wa'] = phone
            ..fields['bio'] = bio
            ..fields['keahlian'] = expertise;
      if (photoPath != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', photoPath));
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw _error(res, 'Gagal menyimpan profil');
      }
      final decoded = _decode(res.body);
      if (decoded is Map && decoded['data'] is Map) {
        return InstructorProfile.fromMap(Map<String, dynamic>.from(decoded));
      }
      // Server hanya membalas pesan sukses: pakai data yang dikirim.
      return InstructorProfile(
        name: name,
        phone: phone,
        bio: bio,
        expertise: expertise,
      );
    }, 'Gagal menyimpan profil.');
  }
}
