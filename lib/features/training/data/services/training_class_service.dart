import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sikarir/core/constants/api_constants.dart';
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

  Future<List<TrainingClassModel>> getMyClasses([String? token]) async {
    try {
      final response = await client
          .get(
            Uri.parse(ApiConstants.kelasPelatihan),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List list = decoded is List
            ? decoded
            : (decoded['data'] is List
                ? decoded['data']
                : (decoded['kelas'] is List ? decoded['kelas'] : []));

        if (list.isNotEmpty) {
          return list
              .map((e) => TrainingClassModel.fromMap(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("TrainingClass API fallback: $e");
      }
    }

    return _getFallbackClasses();
  }

  Future<TrainingClassModel?> getClassDetail(String id, [String? token]) async {
    try {
      final response = await client
          .get(
            Uri.parse('${ApiConstants.kelasPelatihan}/$id'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = decoded['data'] ?? decoded;
        if (data is Map<String, dynamic>) {
          return TrainingClassModel.fromMap(data);
        }
      }
    } catch (_) {}

    final all = _getFallbackClasses();
    return all.firstWhere((c) => c.id == id, orElse: () => all.first);
  }

  List<TrainingClassModel> _getFallbackClasses() {
    return [
      TrainingClassModel(
        id: '1',
        pelatihanId: '101',
        title: 'Desain Grafis & UI/UX Specialist',
        code: 'BLK-JBR-DG01',
        category: 'Bisnis & Kreatif',
        instructor: 'Dimas Wicaksono, M.Ds.',
        room: 'Lab Komputer 02 • BLK Jember',
        startDate: '01 September 2026',
        endDate: '30 Oktober 2026',
        totalSessions: 24,
        completedSessions: 16,
        progress: 0.68,
        status: 'berlangsung',
        description: 'Pelatihan komprehensif menguasai Adobe Illustrator, Figma, Design System, serta riset UX hingga siap uji kompetensi sertifikasi BNSP.',
        materials: [
          ClassMaterial(
            id: 'm1',
            title: 'Modul 01: Pengantar Desain Grafis & Teori Warna SKKNI',
            type: 'pdf',
            duration: '60 Menit',
            fileUrl: 'https://example.com/modul1.pdf',
            isCompleted: true,
          ),
          ClassMaterial(
            id: 'm2',
            title: 'Modul 02: Praktik Vector Art dengan Adobe Illustrator',
            type: 'pdf',
            duration: '90 Menit',
            fileUrl: 'https://example.com/modul2.pdf',
            isCompleted: true,
          ),
          ClassMaterial(
            id: 'm3',
            title: 'Modul 03: Wireframing & Prototyping Interaktif di Figma',
            type: 'pdf',
            duration: '120 Menit',
            fileUrl: 'https://example.com/modul3.pdf',
            isCompleted: true,
          ),
          ClassMaterial(
            id: 'm4',
            title: 'Modul 04: Studi Kasus Redesign Aplikasi Mobile & Web',
            type: 'assignment',
            duration: '180 Menit',
            fileUrl: 'https://example.com/tugas4.pdf',
            isCompleted: false,
          ),
          ClassMaterial(
            id: 'm5',
            title: 'Modul 05: Persiapan Portofolio & Uji Kompetensi BNSP',
            type: 'pdf',
            duration: '90 Menit',
            fileUrl: 'https://example.com/modul5.pdf',
            isCompleted: false,
          ),
        ],
      ),
      TrainingClassModel(
        id: '2',
        pelatihanId: '102',
        title: 'Junior Web Developer (Fullstack PHP/Laravel)',
        code: 'BLK-JBR-IT02',
        category: 'Teknologi Informasi (TIK)',
        instructor: 'Bayu Pratama, S.Kom.',
        room: 'Lab Pemrograman 01 • BLK Jember',
        startDate: '01 Agustus 2026',
        endDate: '15 September 2026',
        totalSessions: 30,
        completedSessions: 30,
        progress: 1.0,
        status: 'selesai',
        description: 'Pemrograman web modern, REST API, integrasi database MySQL, dan deployment web aplikasi sesuai standar SKKNI Software Development.',
        materials: [
          ClassMaterial(
            id: 'm10',
            title: 'Modul 01: HTML5, CSS3 Semantic & Bootstrap/Tailwind',
            type: 'pdf',
            duration: '60 Menit',
            fileUrl: '',
            isCompleted: true,
          ),
          ClassMaterial(
            id: 'm11',
            title: 'Modul 02: Laravel 11 CRUD, Auth & RESTful API',
            type: 'pdf',
            duration: '120 Menit',
            fileUrl: '',
            isCompleted: true,
          ),
        ],
      ),
      TrainingClassModel(
        id: '3',
        pelatihanId: '103',
        title: 'Digital Marketing & Content Strategy',
        code: 'BLK-JBR-DM03',
        category: 'Pemasaran Digital',
        instructor: 'Siti Rahmawati, S.E.',
        room: 'Lab Multimedia • BLK Jember',
        startDate: '10 November 2026',
        endDate: '20 Desember 2026',
        totalSessions: 20,
        completedSessions: 0,
        progress: 0.0,
        status: 'akan_datang',
        description: 'Strategi iklan berbayar (Meta Ads, Google Ads), SEO on-page/off-page, copywriting, dan analitik konversi penjualan bisnis digital.',
      ),
    ];
  }
}
