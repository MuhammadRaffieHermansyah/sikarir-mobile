import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sikarir/core/constants/api_constants.dart';
import 'package:sikarir/features/partner/data/models/partner_model.dart';

class PartnerService {
  final http.Client client;

  PartnerService({http.Client? client}) : client = client ?? http.Client();

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

  /// Ambil mitra dari API. Gagal terhubung atau status bukan 200 → [PartnerApiException]
  /// agar layar menampilkan pesan dan "Coba lagi" (bukan data contoh).
  Future<List<PartnerModel>> getPartners([String? token]) async {
    final http.Response response;
    try {
      response = await client
          .get(
            Uri.parse(ApiConstants.mitra),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      if (kDebugMode) {
        debugPrint("PartnerService error: $e");
      }
      throw const PartnerApiException('Tidak dapat terhubung ke server BLK. Periksa koneksi lalu coba lagi.');
    }

    if (response.statusCode != 200) {
      throw PartnerApiException('Gagal memuat data mitra (Kode: ${response.statusCode}).');
    }

    final decoded = json.decode(response.body);
    final List list = decoded is List
        ? decoded
        : (decoded['data'] is List
            ? decoded['data']
            : (decoded['mitra'] is List ? decoded['mitra'] : []));

    return list.whereType<Map>().map((e) => PartnerModel.fromMap(Map<String, dynamic>.from(e))).toList();
  }
}

/// Kegagalan memuat data mitra dari server.
class PartnerApiException implements Exception {
  final String message;
  const PartnerApiException(this.message);

  @override
  String toString() => message;
}
