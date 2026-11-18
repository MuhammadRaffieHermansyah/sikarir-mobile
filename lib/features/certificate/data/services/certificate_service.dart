import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sikarir/core/constants/api_constants.dart';
import 'package:sikarir/features/auth/data/services/auth_local_service.dart';
import 'package:sikarir/features/certificate/data/models/certificate_model.dart';

class CertificateApiException implements Exception {
  final String message;
  CertificateApiException(this.message);

  @override
  String toString() => message;
}

class CertificateService {
  final http.Client client;

  CertificateService({http.Client? client}) : client = client ?? http.Client();

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

  /// Mengambil daftar sertifikat yang diperoleh peserta dari endpoint API /api/sertifikat/me
  Future<List<CertificateModel>> getCertificates([String? token]) async {
    token ??= await AuthLocalService().getToken();

    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        debugPrint('CertificateService: Token auth tidak tersedia.');
      }
      return [];
    }

    try {
      final response = await client
          .get(
            Uri.parse(ApiConstants.sertifikatMe),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List list = decoded is List
            ? decoded
            : (decoded['data'] is List
                ? decoded['data']
                : (decoded['sertifikat'] is List
                    ? decoded['sertifikat']
                    : (decoded['sertifikasi'] is List ? decoded['sertifikasi'] : [])));

        if (kDebugMode) {
          debugPrint('CertificateService: Berhasil memuat ${list.length} sertifikat dari API.');
        }

        return list
            .map((e) => CertificateModel.fromMap(e as Map<String, dynamic>))
            .toList();
      }

      if (response.statusCode == 401) {
        throw CertificateApiException('Sesi login telah berakhir. Silakan login kembali.');
      }

      throw CertificateApiException(
        'Gagal memuat sertifikat (HTTP ${response.statusCode}). Silakan coba lagi.',
      );
    } on CertificateApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CertificateService.getCertificates error: $e');
      }
      throw CertificateApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }
}
