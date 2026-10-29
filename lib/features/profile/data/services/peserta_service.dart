import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:sikarir/core/constants/api_constants.dart';
import 'package:sikarir/features/profile/data/models/peserta_profile_model.dart';

class PesertaService {
  final http.Client client;

  PesertaService({http.Client? client}) : client = client ?? http.Client();

  Map<String, String> _headers([String? token]) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, String> _headersMultipart([String? token]) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Ambil data profil peserta yang sedang login
  Future<PesertaProfile?> getMyProfile([String? token]) async {
    try {
      final response = await client
          .get(
            Uri.parse(ApiConstants.pesertaMe),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 8));

      if (kDebugMode) {
        debugPrint("Get Peserta Profile Status: ${response.statusCode}");
        debugPrint("Get Peserta Profile Response: ${response.body}");
      }

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = decoded['data'] ?? decoded;
        return PesertaProfile.fromMap(data);
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Get Peserta Profile Error: $e");
    }
    return null;
  }

  /// Update / lengkapi data diri peserta (support upload pas_foto)
  Future<PesertaProfile> updateMyProfile(
    Map<String, dynamic> body, [
    String? token,
    File? pasFotoFile,
  ]) async {
    // Jika ada file foto, gunakan multipart request
    if (pasFotoFile != null) {
      final uri = Uri.parse(ApiConstants.pesertaMe);
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_headersMultipart(token));

      // Tambahkan semua field teks
      body.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Tambahkan file foto
      final ext = pasFotoFile.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png'
          ? 'image/png'
          : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
      request.files.add(await http.MultipartFile.fromPath(
        'pas_foto',
        pasFotoFile.path,
        contentType: MediaType.parse(mimeType),
      ));

      if (kDebugMode) debugPrint("Upload Pas Foto: ${pasFotoFile.path}");

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);

      if (kDebugMode) {
        debugPrint("Update Peserta (multipart) Status: ${response.statusCode}");
        debugPrint("Update Peserta (multipart) Body: ${response.body}");
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        final data = decoded['data'] ?? decoded;
        return PesertaProfile.fromMap(data);
      } else {
        final decoded = json.decode(response.body);
        final msg = decoded['message'] ?? 'Gagal memperbarui data diri.';
        throw Exception(msg);
      }
    }

    // Tanpa foto: request JSON biasa
    final response = await client
        .post(
          Uri.parse(ApiConstants.pesertaMe),
          headers: _headers(token),
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 10));

    if (kDebugMode) {
      debugPrint("Update Peserta Profile Status: ${response.statusCode}");
      debugPrint("Update Peserta Profile Body: ${response.body}");
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = json.decode(response.body);
      final data = decoded['data'] ?? decoded;
      return PesertaProfile.fromMap(data);
    } else {
      final decoded = json.decode(response.body);
      final msg = decoded['message'] ?? 'Gagal memperbarui data diri.';
      throw Exception(msg);
    }
  }

  /// Daftarkan peserta ke kelas pelatihan (kelas-pelatihan)
  Future<bool> enrollTraining({
    required String jadwalId,
    String? pesertaId,
    String? token,
  }) async {
    final response = await client
        .post(
          Uri.parse(ApiConstants.kelasPelatihan),
          headers: _headers(token),
          body: json.encode({
            'id_jadwal': jadwalId,
            if (pesertaId != null && pesertaId.isNotEmpty) 'id_peserta': pesertaId,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (kDebugMode) {
      debugPrint("Enroll Training Status: ${response.statusCode}");
      debugPrint("Enroll Training Response: ${response.body}");
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      final decoded = json.decode(response.body);
      final msg = decoded['message'] ?? 'Gagal mendaftar pelatihan.';
      throw Exception(msg);
    }
  }
}
