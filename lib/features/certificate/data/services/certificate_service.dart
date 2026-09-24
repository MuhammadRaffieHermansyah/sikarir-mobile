import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sikarir/core/constants/api_constants.dart';
import 'package:sikarir/features/certificate/data/models/certificate_model.dart';

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

  Future<List<CertificateModel>> getCertificates([String? token]) async {
    try {
      final response = await client
          .get(
            Uri.parse(ApiConstants.sertifikasi),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List list = decoded is List
            ? decoded
            : (decoded['data'] is List
                ? decoded['data']
                : (decoded['sertifikasi'] is List ? decoded['sertifikasi'] : []));

        if (list.isNotEmpty) {
          return list.map((e) => CertificateModel.fromMap(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("CertificateService API fallback: $e");
      }
    }

    return _getFallbackCertificates();
  }

  List<CertificateModel> _getFallbackCertificates() {
    return [
      CertificateModel(
        id: '1',
        title: 'Junior Graphic Designer (Level 3)',
        issuer: 'Badan Nasional Sertifikasi Profesi (BNSP)',
        issueDate: '12 Jan 2026',
        validUntil: '12 Jan 2029',
        certificateNumber: 'BNSP-TIK-2026-88910',
        status: 'aktif',
        fileUrl: 'https://example.com/sertifikat-bnsp.pdf',
        category: 'Bisnis & Desain Kreatif',
      ),
      CertificateModel(
        id: '2',
        title: 'Pelatihan Berbasis Kompetensi Desain Grafis',
        issuer: 'Balai Latihan Kerja (BLK) Jember',
        issueDate: '20 Des 2025',
        validUntil: 'Seumur Hidup',
        certificateNumber: 'BLK-JBR-PBK-7712',
        status: 'aktif',
        fileUrl: 'https://example.com/sertifikat-blk.pdf',
        category: 'Pelatihan Kejuruan',
      ),
      CertificateModel(
        id: '3',
        title: 'Junior Web Programmer (Level 3)',
        issuer: 'Lembaga Sertifikasi Profesi (LSP) Telematika',
        issueDate: 'Dalam Proses Uji',
        validUntil: '-',
        certificateNumber: 'REG-PROSES-9912',
        status: 'proses',
        fileUrl: '',
        category: 'Teknologi Informasi (TIK)',
      ),
    ];
  }
}
