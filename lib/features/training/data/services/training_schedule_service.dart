import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sikarir/core/constants/api_constants.dart';
import 'package:sikarir/features/training/data/models/training_schedule_model.dart';

class TrainingScheduleService {
  final http.Client client;

  TrainingScheduleService({http.Client? client}) : client = client ?? http.Client();

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

  /// Ambil jadwal dari API. Gagal → Exception agar beranda menampilkan
  /// "Gagal memuat" dan "Coba lagi", bukan jadwal contoh.
  Future<List<TrainingScheduleModel>> getSchedules([String? token]) async {
    final http.Response response;
    try {
      response = await client
          .get(
            Uri.parse(ApiConstants.jadwalPelatihan),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      if (kDebugMode) {
        debugPrint("TrainingScheduleService error: $e");
      }
      throw Exception('Tidak dapat terhubung ke server BLK. Periksa koneksi lalu coba lagi.');
    }

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat jadwal pelatihan (Kode: ${response.statusCode}).');
    }

    final decoded = json.decode(response.body);
    final List list = decoded is List
        ? decoded
        : (decoded['data'] is List
            ? decoded['data']
            : (decoded['jadwal'] is List ? decoded['jadwal'] : []));

    return list
        .whereType<Map>()
        .map((e) => TrainingScheduleModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
}
