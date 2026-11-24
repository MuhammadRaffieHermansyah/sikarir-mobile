import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sikarir/core/constants/api_constants.dart';
import 'package:sikarir/features/attendance/data/models/attendance_model.dart';

enum AttendanceErrorType { network, timeout, unauthorized, server, validation }

/// Error terstruktur agar UI bisa membedakan "data kosong" dari "gagal memuat".
class AttendanceException implements Exception {
  final String message;
  final AttendanceErrorType type;
  final int? statusCode;

  const AttendanceException(this.message, this.type, [this.statusCode]);

  @override
  String toString() => message;
}

class AttendanceService {
  final http.Client client;

  AttendanceService({http.Client? client}) : client = client ?? http.Client();

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

  /// Jalankan request & ubah kegagalan jaringan menjadi [AttendanceException].
  Future<http.Response> _send(
    Future<http.Response> Function() request,
    Duration timeout,
  ) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw const AttendanceException(
        'Koneksi timeout. Periksa jaringan Anda lalu coba lagi.',
        AttendanceErrorType.timeout,
      );
    } on SocketException {
      throw const AttendanceException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        AttendanceErrorType.network,
      );
    } on http.ClientException {
      throw const AttendanceException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        AttendanceErrorType.network,
      );
    }
  }

  /// Pesan error dari body JSON (`message`) bila ada.
  String? _messageFrom(http.Response response) {
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return null;
  }

  AttendanceException _errorFromStatus(http.Response response, String fallback) {
    final code = response.statusCode;
    // 401 = sesi habis. 403 sengaja TIDAK dianggap sesi habis: backend memakai
    // 403 untuk presensi di luar radius lokasi (dengan pesan jarak).
    if (code == 401) {
      return AttendanceException(
        'Sesi Anda telah berakhir. Silakan login ulang.',
        AttendanceErrorType.unauthorized,
        code,
      );
    }
    if (code >= 500) {
      return AttendanceException(
        'Server sedang bermasalah ($code). Coba beberapa saat lagi.',
        AttendanceErrorType.server,
        code,
      );
    }
    return AttendanceException(
      _messageFrom(response) ?? fallback,
      AttendanceErrorType.validation,
      code,
    );
  }

  /// Ambil satu halaman riwayat presensi (backend: `paginate(15)`).
  /// Melempar [AttendanceException] jika gagal (bukan lagi mengembalikan []).
  Future<AttendancePage> getAttendancePage({int page = 1, String? token}) async {
    final uri = Uri.parse(ApiConstants.absen)
        .replace(queryParameters: {'page': page.toString()});
    final response = await _send(
      () => client.get(uri, headers: _headers(token)),
      const Duration(seconds: 8),
    );

    if (kDebugMode) {
      debugPrint('Get Attendance Response: ${response.statusCode}');
    }

    if (response.statusCode == 404) {
      return const AttendancePage(items: [], hasMore: false);
    }
    if (response.statusCode != 200) {
      throw _errorFromStatus(response, 'Gagal memuat riwayat presensi.');
    }

    final decoded = json.decode(response.body);
    List list = const [];
    var hasMore = false;

    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map) {
      if (decoded['data'] is List) {
        list = decoded['data'] as List;
      } else if (decoded['absen'] is List) {
        list = decoded['absen'] as List;
      }
      final meta = decoded['meta'];
      if (meta is Map) {
        final current = int.tryParse('${meta['current_page']}');
        final last = int.tryParse('${meta['last_page']}');
        hasMore = current != null && last != null && current < last;
      }
    }

    return AttendancePage(
      items: list
          .whereType<Map<String, dynamic>>()
          .map(AttendanceItem.fromMap)
          .toList(),
      hasMore: hasMore,
    );
  }

  /// Ambil presensi hari ini. `null` = memang belum absen hari ini.
  /// Melempar [AttendanceException] jika gagal memeriksa.
  Future<AttendanceItem?> getTodayAttendance([String? token]) async {
    final response = await _send(
      () => client.get(Uri.parse('${ApiConstants.absen}/today'),
          headers: _headers(token)),
      const Duration(seconds: 8),
    );

    if (kDebugMode) {
      debugPrint('Today Attendance Response: ${response.statusCode}');
    }

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw _errorFromStatus(response, 'Gagal memeriksa presensi hari ini.');
    }

    final decoded = json.decode(response.body);
    final data = decoded is Map ? (decoded['data'] ?? decoded) : null;
    if (data is Map<String, dynamic> && data.containsKey('id_absen')) {
      return AttendanceItem.fromMap(data);
    }
    return null;
  }

  /// Ambil rekap kehadiran & status kelayakan sertifikasi.
  /// Melempar [AttendanceException] jika gagal; `null` bila server tak punya data.
  Future<AttendanceRekap?> getAttendanceSummaryReport([String? token]) async {
    final response = await _send(
      () => client.get(Uri.parse('${ApiConstants.absen}/rekap'),
          headers: _headers(token)),
      const Duration(seconds: 8),
    );

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw _errorFromStatus(response, 'Gagal memuat rekap kehadiran.');
    }

    final decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
      return AttendanceRekap.fromMap(decoded['data'] as Map<String, dynamic>);
    }
    return null;
  }

  /// Submit presensi baru (dengan koordinat GPS)
  Future<AttendanceItem> submitAttendance(
    AttendanceSubmitRequest request, [
    String? token,
  ]) async {
    final body = json.encode(request.toMap());

    if (kDebugMode) {
      debugPrint('Submit Attendance Body: $body');
    }

    final response = await _send(
      () => client.post(
        Uri.parse(ApiConstants.absen),
        headers: _headers(token),
        body: body,
      ),
      const Duration(seconds: 10),
    );

    if (kDebugMode) {
      debugPrint('Submit Attendance Response: ${response.statusCode}');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = json.decode(response.body);
      final data = decoded is Map ? (decoded['data'] ?? decoded) : null;
      return AttendanceItem.fromMap(
        data is Map<String, dynamic> ? data : request.toMap(),
      );
    }
    throw _errorFromStatus(response, 'Gagal melakukan presensi');
  }
}
