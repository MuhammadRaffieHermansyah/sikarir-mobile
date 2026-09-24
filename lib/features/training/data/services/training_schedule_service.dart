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

  Future<List<TrainingScheduleModel>> getSchedules([String? token]) async {
    try {
      final response = await client
          .get(
            Uri.parse(ApiConstants.jadwalPelatihan),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List list = decoded is List
            ? decoded
            : (decoded['data'] is List
                ? decoded['data']
                : (decoded['jadwal'] is List ? decoded['jadwal'] : []));

        if (list.isNotEmpty) {
          return list
              .map((e) => TrainingScheduleModel.fromMap(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("TrainingSchedule API fallback: $e");
      }
    }

    return _getFallbackSchedules();
  }

  List<TrainingScheduleModel> _getFallbackSchedules() {
    return [
      TrainingScheduleModel(
        id: 's1',
        classId: '1',
        className: 'Desain Grafis & UI/UX',
        sessionNumber: 17,
        title: 'Sesi 17: User Flow & Wireframing Lanjutan',
        topic: 'Pembuatan low-fidelity wireframe dan arsitektur informasi aplikasi e-commerce.',
        date: 'Hari Ini, 24 September 2026',
        startTime: '08:00',
        endTime: '15:00',
        room: 'Lab Komputer 02 • BLK Jember',
        instructor: 'Dimas Wicaksono, M.Ds.',
        type: 'tatap_muka',
        status: 'berlangsung',
        isAttendanceOpen: true,
        myAttendanceStatus: 'hadir',
      ),
      TrainingScheduleModel(
        id: 's2',
        classId: '1',
        className: 'Desain Grafis & UI/UX',
        sessionNumber: 18,
        title: 'Sesi 18: High-Fidelity UI Design & Design Token',
        topic: 'Eksplorasi warna, typography token, dan auto-layout responsive di Figma.',
        date: 'Besok, 25 September 2026',
        startTime: '08:00',
        endTime: '15:00',
        room: 'Lab Komputer 02 • BLK Jember',
        instructor: 'Dimas Wicaksono, M.Ds.',
        type: 'tatap_muka',
        status: 'akan_datang',
        isAttendanceOpen: false,
      ),
      TrainingScheduleModel(
        id: 's3',
        classId: '1',
        className: 'Desain Grafis & UI/UX',
        sessionNumber: 19,
        title: 'Sesi 19: Mentoring Industri & Guest Lecture',
        topic: 'Best practice UI/UX di startup nasional bersama Lead Designer PT Midtrans.',
        date: 'Senin, 28 September 2026',
        startTime: '09:00',
        endTime: '12:00',
        room: 'Online (Zoom Meeting)',
        instructor: 'Rian Hidayat (Lead Designer Midtrans)',
        type: 'online',
        status: 'akan_datang',
        meetUrl: 'https://zoom.us/j/sikarir-blk-jember',
        isAttendanceOpen: false,
      ),
      TrainingScheduleModel(
        id: 's4',
        classId: '1',
        className: 'Desain Grafis & UI/UX',
        sessionNumber: 20,
        title: 'Sesi 20: Persiapan Uji Kompetensi BNSP Desain Grafis',
        topic: 'Review portofolio, simulasi wawancara asesor, dan checklist dokumen asesmen.',
        date: 'Rabu, 30 September 2026',
        startTime: '08:00',
        endTime: '15:00',
        room: 'Lab Komputer 02 • BLK Jember',
        instructor: 'Dimas Wicaksono, M.Ds.',
        type: 'tatap_muka',
        status: 'akan_datang',
        isAttendanceOpen: false,
      ),
    ];
  }
}
