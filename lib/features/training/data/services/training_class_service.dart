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
      // 1. Ambil data pelatihan utama
      final response = await client
          .get(
            Uri.parse(ApiConstants.pelatihan),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 6));

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

        if (list.isNotEmpty) {
          // 2. Ambil jadwal jika ada untuk mencocokkan id_jadwal
          Map<String, String> jadwalMap = {};
          try {
            final jadwalRes = await client
                .get(
                  Uri.parse(ApiConstants.jadwalPelatihan),
                  headers: _headers(token),
                )
                .timeout(const Duration(seconds: 4));
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
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Training Catalog API fallback: $e");
      }
    }

    return _getFallbackCatalog();
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

    final response = await client
        .post(
          Uri.parse(ApiConstants.kelasPelatihan),
          headers: _headers(token),
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 10));

    if (kDebugMode) {
      debugPrint("Enroll Training Status: ${response.statusCode}");
      debugPrint("Enroll Training Body: ${response.body}");
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      final decoded = json.decode(response.body);
      final msg = decoded['message'] ?? 'Gagal mendaftar pelatihan.';
      throw Exception(msg);
    }
  }

  /// Ambil kelas saya yang diikuti oleh user login
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
          .timeout(const Duration(seconds: 6));

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

  /// Ambil detail kelas tertentu
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

  /// Fallback Katalog Pelatihan Terakreditasi BNSP
  List<TrainingCatalogModel> _getFallbackCatalog() {
    return [
      TrainingCatalogModel(
        id: '1',
        jadwalId: '1',
        title: 'Desain Grafis & Visual Communication',
        description: 'Kuasai visual branding, motion animation untuk periklanan digital, typography, dan kurikulum standar industri SKKNI Desain Komunikasi Visual.',
        category: 'TIK & INFORMATIKA',
        skkniCode: 'SKKNI No. M.74100.001.02 • Lisensi BNSP Level 3',
        badge: 'BNSP Level 3',
        duration: '40 JP (Intensif)',
        location: 'BLK Jember, Jawa Timur',
        quota: 20,
        enrolledCount: 16,
        remainingQuota: 4,
        instructor: 'Dimas Wicaksono, M.Ds.',
        startDate: '01 September 2026',
        endDate: '30 Oktober 2026',
        benefitTitle: 'BEASISWA APBN',
        benefitDesc: '100% Gratis & Uang Saku Harian',
        imageUrl: 'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800&auto=format&fit=crop&q=80',
        status: 'tersedia',
      ),
      TrainingCatalogModel(
        id: '2',
        jadwalId: '2',
        title: 'Teknik Las Industri 3G/4G SMAW',
        description: 'Spesialisasi pengelasan pelat posisi 3G & 4G bersertifikasi BNSP dan uji standar ASME untuk kebutuhan industri galangan kapal, konstruksi, dan fabrikasi berat.',
        category: 'MANUFAKTUR & LAS',
        skkniCode: 'SKKNI No. C.25920.001.01 • Standar ASME Migas',
        badge: 'Sertifikasi Migas',
        duration: '320 JP (45 Hari Kerja)',
        location: 'BBVP Serang, Banten',
        quota: 16,
        enrolledCount: 8,
        remainingQuota: 8,
        instructor: 'Ir. Bambang Sugiarto, S.T.',
        startDate: '15 September 2026',
        endDate: '10 November 2026',
        benefitTitle: 'FASILITAS LENGKAP',
        benefitDesc: 'Asrama BBVP + APD & Sertifikasi Uji Las',
        imageUrl: 'https://images.unsplash.com/photo-1504917599217-d4dc5ebe6122?w=800&auto=format&fit=crop&q=80',
        status: 'tersedia',
      ),
      TrainingCatalogModel(
        id: '3',
        jadwalId: '3',
        title: 'Teknisi Kendaraan Listrik (EV) & Injeksi',
        description: 'Pelajari arsitektur baterai high-voltage motor listrik & mobil listrik, kalibrasi ECU injeksi cerdas, serta troubleshooting motor brushless DC modern.',
        category: 'OTOMOTIF MODERN',
        skkniCode: 'SKKNI No. G.45201.002.01 • Lisensi APMEV',
        badge: 'Standar APMEV',
        duration: '240 JP (Kurikulum Industri)',
        location: 'BLK Bekasi, Jawa Barat',
        quota: 16,
        enrolledCount: 13,
        remainingQuota: 3,
        instructor: 'Hendra Gunawan, S.T.',
        startDate: '20 September 2026',
        endDate: '15 November 2026',
        benefitTitle: 'PENYALURAN KERJA',
        benefitDesc: 'Didukung 14 Mitra Industri APM',
        imageUrl: 'https://images.unsplash.com/photo-1617788138017-80ad40651399?w=800&auto=format&fit=crop&q=80',
        status: 'tersedia',
      ),
      TrainingCatalogModel(
        id: '4',
        jadwalId: '4',
        title: 'Junior Web Developer (Fullstack PHP/Laravel)',
        description: 'Pelatihan pemrograman web modern, REST API, integrasi database relasional, dan deployment aplikasi sesuai standar SKKNI Software Development.',
        category: 'TIK & INFORMATIKA',
        skkniCode: 'SKKNI No. J.620100.004.01 • Fullstack Level 3',
        badge: 'BNSP Software Dev',
        duration: '160 JP (20 Hari Kerja)',
        location: 'BLK Jember, Jawa Timur',
        quota: 20,
        enrolledCount: 15,
        remainingQuota: 5,
        instructor: 'Bayu Pratama, S.Kom.',
        startDate: '05 Oktober 2026',
        endDate: '30 November 2026',
        benefitTitle: 'MITRA KERJA BLK',
        benefitDesc: 'Peluang Kerja di Tech Startup & BUMN',
        imageUrl: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=800&auto=format&fit=crop&q=80',
        status: 'tersedia',
      ),
    ];
  }

  /// Fallback Kelas yang Sedang Diikuti
  List<TrainingClassModel> _getFallbackClasses() {
    return [
      TrainingClassModel(
        id: '1',
        pelatihanId: '1',
        jadwalId: '1',
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
        pelatihanId: '4',
        jadwalId: '4',
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
    ];
  }
}
