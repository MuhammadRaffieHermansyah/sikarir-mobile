import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sikarir/core/constants/api_constants.dart';
import 'package:sikarir/features/training/data/models/training_catalog_model.dart';
import 'package:sikarir/features/training/data/models/training_class_model.dart';

class TrainingClassService {
  final http.Client client;

  TrainingClassService({http.Client? client}) : client = client ?? http.Client();

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

  /// Ambil katalog pelatihan dari API (/api/pelatihan)
  Future<List<TrainingCatalogModel>> getCatalog([String? token]) async {
    try {
      final response = await client
          .get(
            Uri.parse(ApiConstants.pelatihan),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 20));

      if (kDebugMode) {
        debugPrint("Get Catalog Status: ${response.statusCode}");
        debugPrint("Get Catalog Body: ${response.body}");
      }

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List list = decoded is List
            ? decoded
            : (decoded['data'] is List
                ? decoded['data']
                : (decoded['pelatihan'] is List ? decoded['pelatihan'] : []));

        if (list.isEmpty) {
          return [];
        }

        // Ambil jadwal jika ada untuk memetakan id_jadwal aktif
        Map<String, String> jadwalMap = {};
        try {
          final jadwalRes = await client
              .get(
                Uri.parse(ApiConstants.jadwalPelatihan),
                headers: _headers(token),
              )
              .timeout(const Duration(seconds: 20));
          if (jadwalRes.statusCode == 200) {
            final decodedJadwal = json.decode(jadwalRes.body);
            final List jList = decodedJadwal is List
                ? decodedJadwal
                : (decodedJadwal['data'] is List ? decodedJadwal['data'] : []);
            for (final j in jList) {
              if (j is Map) {
                final pId = j['id_pelatihan']?.toString();
                final jId = j['id_jadwal']?.toString();
                if (pId != null && jId != null && !jadwalMap.containsKey(pId)) {
                  jadwalMap[pId] = jId;
                }
              }
            }
          }
        } catch (_) {}

        return list.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          final pId = (map['id_pelatihan'] ?? map['id'])?.toString();
          if (pId != null && jadwalMap.containsKey(pId) && map['id_jadwal'] == null) {
            map['id_jadwal'] = jadwalMap[pId];
          }
          return TrainingCatalogModel.fromMap(map);
        }).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        final decoded = json.decode(response.body);
        final msg = decoded is Map ? decoded['message'] : null;
        throw Exception(msg ?? 'Gagal memuat katalog pelatihan (Kode: ${response.statusCode}). Silakan coba lagi beberapa saat.');
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) debugPrint("ClientException in getCatalog: $e");
      throw Exception('Tidak dapat terhubung ke server. Silakan periksa jaringan Anda atau coba lagi beberapa saat.');
    } catch (e) {
      if (kDebugMode) debugPrint("Error in getCatalog: $e");
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat memuat katalog pelatihan. Silakan coba lagi beberapa saat.');
    }
  }

  /// Mendaftar ke kelas pelatihan melalui endpoint /api/kelas-pelatihan
  Future<bool> enrollTraining({
    required String jadwalId,
    String? pesertaId,
    String? token,
  }) async {
    final body = <String, dynamic>{
      'id_jadwal': jadwalId,
    };
    if (pesertaId != null && pesertaId.isNotEmpty) {
      body['id_peserta'] = pesertaId;
    }

    try {
      final response = await client
          .post(
            Uri.parse(ApiConstants.kelasPelatihan),
            headers: _headers(token),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (kDebugMode) {
        debugPrint("Enroll Training Status: ${response.statusCode}");
        debugPrint("Enroll Training Body: ${response.body}");
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final decoded = json.decode(response.body);
        final msg = decoded is Map ? decoded['message'] : null;
        throw Exception(msg ?? 'Gagal mendaftar pelatihan. Silakan coba lagi beberapa saat.');
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) debugPrint("ClientException in enrollTraining: $e");
      throw Exception('Tidak dapat terhubung ke server. Silakan coba lagi beberapa saat.');
    } catch (e) {
      if (kDebugMode) debugPrint("Error in enrollTraining: $e");
      if (e is Exception) rethrow;
      throw Exception('Gagal memproses pendaftaran pelatihan. Silakan coba lagi beberapa saat.');
    }
  }

  /// Ambil kelas saya yang diikuti oleh user login (/api/kelas-pelatihan/me)
  Future<List<TrainingClassModel>> getMyClasses([String? token]) async {
    try {
      final endpoint = (token != null && token.isNotEmpty)
          ? ApiConstants.kelasPelatihanMe
          : ApiConstants.kelasPelatihan;

      final response = await client
          .get(
            Uri.parse(endpoint),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 20));

      if (kDebugMode) {
        debugPrint("Get MyClasses Status: ${response.statusCode}");
        debugPrint("Get MyClasses Body: ${response.body}");
      }

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List list = decoded is List
            ? decoded
            : (decoded['data'] is List
                ? decoded['data']
                : (decoded['kelas'] is List ? decoded['kelas'] : []));

        return list
            .map((e) => TrainingClassModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        final decoded = json.decode(response.body);
        final msg = decoded is Map ? decoded['message'] : null;
        throw Exception(msg ?? 'Gagal memuat kelas pelatihan saya. Silakan coba lagi beberapa saat.');
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) debugPrint("ClientException in getMyClasses: $e");
      throw Exception('Tidak dapat terhubung ke server. Silakan periksa jaringan Anda atau coba lagi beberapa saat.');
    } catch (e) {
      if (kDebugMode) debugPrint("Error in getMyClasses: $e");
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat memuat kelas pelatihan saya. Silakan coba lagi beberapa saat.');
    }
  }

  /// Ambil detail kelas tertentu (/api/kelas-pelatihan/{id})
  Future<TrainingClassModel?> getClassDetail(String id, [String? token]) async {
    try {
      final response = await client
          .get(
            Uri.parse('${ApiConstants.kelasPelatihan}/$id'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = decoded['data'] ?? decoded;
        if (data is Map<String, dynamic>) {
          return TrainingClassModel.fromMap(data);
        }
      } else if (response.statusCode == 404) {
        return null;
      } else {
        final decoded = json.decode(response.body);
        final msg = decoded is Map ? decoded['message'] : null;
        throw Exception(msg ?? 'Gagal memuat detail kelas pelatihan. Silakan coba lagi beberapa saat.');
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) debugPrint("ClientException in getClassDetail: $e");
      throw Exception('Tidak dapat terhubung ke server. Silakan coba lagi beberapa saat.');
    } catch (e) {
      if (kDebugMode) debugPrint("Error in getClassDetail: $e");
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat memuat detail kelas pelatihan.');
    }
    return null;
  }
}
