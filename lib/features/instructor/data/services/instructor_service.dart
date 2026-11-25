import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sikarir/core/constants/api_constants.dart';
import 'package:sikarir/features/instructor/data/models/attendance_session_model.dart';
import 'package:sikarir/features/instructor/data/models/class_module_model.dart';
import 'package:sikarir/features/training/data/models/training_class_model.dart';

/// Akses API instruktur: kelas yang diampu serta modul & materi per pertemuan.
class InstructorService {
  final http.Client client;

  InstructorService({http.Client? client}) : client = client ?? http.Client();

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

  List _asList(dynamic decoded, [List<String> keys = const ['data']]) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      for (final k in keys) {
        if (decoded[k] is List) return decoded[k] as List;
      }
    }
    return const [];
  }

  Map<String, dynamic>? _asMap(dynamic decoded) {
    if (decoded is Map) {
      final data = decoded['data'] ?? decoded;
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Exception _error(http.Response res, String fallback) {
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
      if (kDebugMode) debugPrint('InstructorService ClientException: $e');
      throw Exception(
        'Tidak dapat terhubung ke server. Periksa jaringan Anda.',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('InstructorService error: $e');
      if (e is Exception) rethrow;
      throw Exception(fallback);
    }
  }

  /// Kelas yang diampu instruktur login.
  Future<List<TrainingClassModel>> getTeachingClasses(String? token) {
    return _guard(() async {
      final res = await client
          .get(
            Uri.parse(ApiConstants.instrukturKelas),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 404) return <TrainingClassModel>[];
      if (res.statusCode != 200) {
        throw _error(res, 'Gagal memuat kelas yang Anda ampu');
      }
      return _asList(_decode(res.body), const ['data', 'kelas'])
          .whereType<Map>()
          .map((e) => TrainingClassModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }, 'Terjadi kesalahan saat memuat kelas yang Anda ampu.');
  }

  /// Modul beserta materinya untuk sebuah kelas (dipakai peserta & instruktur).
  Future<List<ClassModule>> getModules(String classId, String? token) {
    return _guard(() async {
      final res = await client
          .get(
            Uri.parse(ApiConstants.modulKelas(classId)),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 404) return <ClassModule>[];
      if (res.statusCode != 200) throw _error(res, 'Gagal memuat modul kelas');
      return _asList(_decode(res.body), const ['data', 'modul'])
          .whereType<Map>()
          .map((e) => ClassModule.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }, 'Terjadi kesalahan saat memuat modul kelas.');
  }

  Future<ClassModule> createModule({
    required String classId,
    required String title,
    required String description,
    required int meetingNumber,
    String? token,
  }) {
    return _guard(() async {
      final res = await client
          .post(
            Uri.parse(ApiConstants.modulKelas(classId)),
            headers: _headers(token),
            body: json.encode({
              'judul': title,
              'deskripsi': description,
              'pertemuan_ke': meetingNumber,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw _error(res, 'Gagal menambahkan modul');
      }
      final map = _asMap(_decode(res.body)) ?? {};
      return ClassModule.fromMap({
        'id_kelas': classId,
        'judul': title,
        'deskripsi': description,
        'pertemuan_ke': meetingNumber,
        ...map,
      });
    }, 'Gagal menambahkan modul.');
  }

  Future<void> deleteModule(String moduleId, String? token) {
    return _guard(() async {
      final res = await client
          .delete(
            Uri.parse(ApiConstants.modul(moduleId)),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw _error(res, 'Gagal menghapus modul');
      }
    }, 'Gagal menghapus modul.');
  }

  /// Tambah materi ke modul. [filePath] untuk tipe file, [url] untuk link,
  /// [content] untuk catatan teks.
  Future<ModuleMaterial> addMaterial({
    required String moduleId,
    required String title,
    required MaterialKind kind,
    String? url,
    String? content,
    String? filePath,
    String? token,
  }) {
    return _guard(() async {
      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse(ApiConstants.materiModul(moduleId)),
            )
            ..headers.addAll(_headers(token, json: false))
            ..fields['judul'] = title
            ..fields['tipe'] = kind.apiValue;
      if (kind == MaterialKind.link) request.fields['url'] = url ?? '';
      if (kind == MaterialKind.text) request.fields['konten'] = content ?? '';
      if (kind == MaterialKind.file && filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw _error(res, 'Gagal menambahkan materi');
      }
      final map = _asMap(_decode(res.body)) ?? {};
      return ModuleMaterial.fromMap({
        'id_modul': moduleId,
        'judul': title,
        'tipe': kind.apiValue,
        'url': url,
        'konten': content,
        ...map,
      });
    }, 'Gagal menambahkan materi.');
  }

  Future<List<AttendanceSession>> getAttendanceSessions(
    String classId,
    String? token,
  ) {
    return _guard(() async {
      final res = await client
          .get(
            Uri.parse(ApiConstants.sesiPresensiKelas(classId)),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 404) return <AttendanceSession>[];
      if (res.statusCode != 200) {
        throw _error(res, 'Gagal memuat sesi presensi');
      }
      return _asList(_decode(res.body), const ['data', 'sesi'])
          .whereType<Map>()
          .map((e) => AttendanceSession.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }, 'Terjadi kesalahan saat memuat sesi presensi.');
  }

  Future<void> createAttendanceSession(
    String classId,
    AttendanceSessionInput input,
    String? token,
  ) {
    return _guard(() async {
      final res = await client
          .post(
            Uri.parse(ApiConstants.sesiPresensiKelas(classId)),
            headers: _headers(token),
            body: json.encode(input.toMap()),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw _error(res, 'Gagal membuat sesi presensi');
      }
    }, 'Gagal membuat sesi presensi.');
  }

  Future<void> setAttendanceSessionOpen(
    String sessionId,
    bool open,
    String? token,
  ) {
    return _guard(() async {
      final res = await client
          .patch(
            Uri.parse(ApiConstants.sesiPresensi(sessionId)),
            headers: _headers(token),
            body: json.encode({'absen_dibuka': open}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw _error(res, 'Gagal mengubah status presensi');
      }
    }, 'Gagal mengubah status presensi.');
  }

  Future<void> deleteAttendanceSession(String sessionId, String? token) {
    return _guard(() async {
      final res = await client
          .delete(
            Uri.parse(ApiConstants.sesiPresensi(sessionId)),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw _error(res, 'Gagal menghapus sesi presensi');
      }
    }, 'Gagal menghapus sesi presensi.');
  }

  Future<void> deleteMaterial(String materialId, String? token) {
    return _guard(() async {
      final res = await client
          .delete(
            Uri.parse(ApiConstants.materi(materialId)),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw _error(res, 'Gagal menghapus materi');
      }
    }, 'Gagal menghapus materi.');
  }
}
