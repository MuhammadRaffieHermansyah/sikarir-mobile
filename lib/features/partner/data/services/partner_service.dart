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

  Future<List<PartnerModel>> getPartners([String? token]) async {
    try {
      final response = await client
          .get(
            Uri.parse(ApiConstants.mitra),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List list = decoded is List
            ? decoded
            : (decoded['data'] is List
                ? decoded['data']
                : (decoded['mitra'] is List ? decoded['mitra'] : []));

        if (list.isNotEmpty) {
          return list.map((e) => PartnerModel.fromMap(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("PartnerService API fallback: $e");
      }
    }

    return _getFallbackPartners();
  }

  List<PartnerModel> _getFallbackPartners() {
    return [
      PartnerModel(
        id: '1',
        name: 'PT Midtrans Indonesia',
        industry: 'Fintech & Software Development',
        logo: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=100&auto=format&fit=crop&q=80',
        location: 'Jakarta Selatan',
        description: 'Perusahaan payment gateway terbesar di Asia Tenggara yang bermitra dengan BLK untuk penyerapan talent lulusan IT.',
        activeVacancies: 3,
        partnershipType: 'Penyalur Kerja & Guest Lecture',
        website: 'https://midtrans.com',
      ),
      PartnerModel(
        id: '2',
        name: 'PT Astra Daihatsu Motor',
        industry: 'Manufaktur & Otomotif',
        logo: 'https://images.unsplash.com/photo-1549923746-c502d488b3ea?w=100&auto=format&fit=crop&q=80',
        location: 'Sunter, Jakarta Utara',
        description: 'Pabrikan otomotif nasional penyedia program On the Job Training (OJT) dan perekrutan mekanik & draftsman.',
        activeVacancies: 5,
        partnershipType: 'Tempat Magang OJT & Rekrutmen',
        website: 'https://daihatsu.co.id',
      ),
      PartnerModel(
        id: '3',
        name: 'PT Kalbe Farma Tbk',
        industry: 'Farmasi & Logistik',
        logo: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=100&auto=format&fit=crop&q=80',
        location: 'Surabaya & Jakarta',
        description: 'Perusahaan farmasi terkemuka yang merekrut lulusan administrasi, pergudangan, dan quality control dari BLK.',
        activeVacancies: 2,
        partnershipType: 'Penyalur Kerja Resmi',
        website: 'https://kalbe.co.id',
      ),
    ];
  }
}
