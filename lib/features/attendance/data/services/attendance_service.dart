import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sikarir/core/constants/api_constants.dart';
import 'package:sikarir/features/attendance/data/models/attendance_model.dart';

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

  /// Ambil riwayat presensi peserta (semua)
  Future<List<AttendanceItem>> getAttendanceList([String? token]) async {
    try {
      final response = await client
          .get(
            Uri.parse(ApiConstants.absen),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 8));

      if (kDebugMode) {
        debugPrint('Get Attendance Response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List list = decoded is List
            ? decoded
            : (decoded['data'] is List
                ? decoded['data']
                : (decoded['absen'] is List ? decoded['absen'] : []));

        if (list.isNotEmpty) {
          return list
              .map((e) => AttendanceItem.fromMap(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Attendance API error: $e');
    }
    return [];
  }

  /// Ambil presensi hari ini untuk peserta yang login
  Future<AttendanceItem?> getTodayAttendance([String? token]) async {
    try {
      final response = await client
          .get(
            Uri.parse('${ApiConstants.absen}/today'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 8));

      if (kDebugMode) {
        debugPrint('Today Attendance Response: ${response.statusCode} ${response.body}');
      }

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = decoded['data'] ?? decoded;
        if (data is Map<String, dynamic> && data.containsKey('id_absen')) {
          return AttendanceItem.fromMap(data);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Today Attendance error: $e');
    }
    return null;
  }

  /// Ambil ringkasan rekapitulasi kehadiran dan status kelayakan sertifikasi
  Future<Map<String, dynamic>?> getAttendanceSummaryReport([String? token]) async {
    try {
      final response = await client
          .get(
            Uri.parse('${ApiConstants.absen}/rekap'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          return decoded['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Attendance Rekap API error: $e');
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

    final response = await client
        .post(
          Uri.parse(ApiConstants.absen),
          headers: _headers(token),
          body: body,
        )
        .timeout(const Duration(seconds: 10));

    if (kDebugMode) {
      debugPrint('Submit Attendance Response: ${response.statusCode} ${response.body}');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = json.decode(response.body);
      final data = decoded['data'] ?? decoded;
      return AttendanceItem.fromMap(
        data is Map<String, dynamic> ? data : request.toMap(),
      );
    } else {
      final decoded = json.decode(response.body);
      final msg = decoded['message'] ?? 'Gagal melakukan presensi';
      throw Exception(msg);
    }
  }

  String formatDate(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String formatTimeHm(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
