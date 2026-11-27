import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sikarir/core/constants/api_constants.dart';
import 'package:sikarir/features/job/data/models/job_model.dart';

/// Exception khusus saat API tidak dapat dijangkau (fallback ke data lokal)
class JobApiException implements Exception {
  final String message;
  const JobApiException(this.message);
  @override
  String toString() => message;
}

class JobService {
  final http.Client client;

  JobService({http.Client? client}) : client = client ?? http.Client();

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

  /// Mengambil daftar lowongan dari API.
  /// - Jika API berhasil (200) dan mengembalikan data → return list dari API.
  /// - Jika API gagal / timeout / response kosong → throw [JobApiException]
  ///   sehingga caller (repository/provider) bisa handle (misal tampilkan error
  ///   atau pakai fallback lokal sesuai kebutuhan).
  Future<List<JobVacancyModel>> getJobs([String? token]) async {
    try {
      final response = await client
          .get(
            Uri.parse(ApiConstants.lowongan),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List list = decoded is List
            ? decoded
            : (decoded['data'] is List
                ? decoded['data']
                : (decoded['lowongan'] is List ? decoded['lowongan'] : []));

        if (list.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('JobService: Berhasil ambil ${list.length} lowongan dari API.');
          }
          return list
              .map((e) => JobVacancyModel.fromMap(e as Map<String, dynamic>))
              .toList();
        }

        // Response 200 tapi data kosong → kembalikan list kosong (bukan fallback)
        return [];
      }

      // Status code bukan 200
      throw JobApiException(
        'Gagal memuat lowongan (HTTP ${response.statusCode}). Silakan coba lagi.',
      );
    } on JobApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('JobService.getJobs error: $e');
      }
      throw const JobApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  /// Mengembalikan data contoh (offline / demo) tanpa menyentuh API.
  List<JobVacancyModel> getFallbackJobs() => _getFallbackJobs();

  /// Kirim lamaran kerja ke backend.
  /// Mengembalikan Map dengan `success`, `message`, dan optional `needProfileCompletion`.
  Future<Map<String, dynamic>> applyJob(String jobId, [String? token]) async {
    try {
      final response = await client
          .post(
            Uri.parse('${ApiConstants.lowongan}/$jobId/lamar'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 20));

      final decoded = json.decode(response.body) as Map<String, dynamic>? ?? {};
      final message = (decoded['message'] ?? '').toString();

      if (response.statusCode == 201) {
        return {'success': true, 'message': message};
      } else {
        final needProfile = decoded['need_profile_completion'] == true;
        return {
          'success': false,
          'message': message.isNotEmpty ? message : 'Gagal mengirim lamaran.',
          'need_profile_completion': needProfile,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("JobService.applyJob error: $e");
      }
      return {'success': false, 'message': 'Tidak dapat terhubung ke server.'};
    }
  }

  /// Ambil daftar riwayat lamaran peserta yang sedang login.
  Future<List<Map<String, dynamic>>> getMyApplications([String? token]) async {
    try {
      final response = await client
          .get(
            Uri.parse('${ApiConstants.lowongan}/my-applications'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List list = decoded is List
            ? decoded
            : (decoded['data'] is List ? decoded['data'] : []);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("JobService.getMyApplications error: $e");
      }
    }
    return [];
  }

  List<JobVacancyModel> _getFallbackJobs() {
    return [
      JobVacancyModel(
        id: '1',
        title: 'Junior Web & UI Developer',
        companyName: 'PT Midtrans Indonesia',
        companyLogo: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=100&auto=format&fit=crop&q=80',
        location: 'Jakarta Selatan (Hybrid)',
        salary: 'Rp 6,5 – 8,5 Juta/bln',
        qualification: 'Menguasai HTML, CSS/Tailwind, JavaScript dasar, portofolio proyek pelatihan BLK.',
        type: 'Full-Time',
        deadline: '30 Sep 2026',
        badges: ['⚡ Fast-Track Interview', '🎓 Alumni TIK BLK'],
        description: 'Membantu tim engineer mengembangkan antarmuka website dan aplikasi web payment gateway terdepan di Indonesia.',
      ),
      JobVacancyModel(
        id: '2',
        title: 'Draftsman AutoCAD 2D/3D & Desain Cetakan',
        companyName: 'PT Astra Daihatsu Motor',
        companyLogo: 'https://images.unsplash.com/photo-1549923746-c502d488b3ea?w=100&auto=format&fit=crop&q=80',
        location: 'Sunter, Jakarta Utara',
        salary: 'Rp 5,5 – 6,8 Juta + Bonus',
        qualification: 'Lulusan Otomotif/Teknik Mesin BLK, mampu membaca gambar teknik dan AutoCAD.',
        type: 'Full-Time',
        deadline: '15 Okt 2026',
        badges: ['⚡ Penempatan Cepat', '🛡 Sertifikat BNSP Drafting'],
        description: 'Membuat rancangan komponen manufaktur otomotif berkualitas tinggi sesuai standar pabrikasi Astra.',
      ),
      JobVacancyModel(
        id: '3',
        title: 'Staff Administrasi Gudang & Logistik',
        companyName: 'PT Kalbe Farma Tbk',
        companyLogo: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=100&auto=format&fit=crop&q=80',
        location: 'Surabaya, Jawa Timur',
        salary: 'Rp 4,9 – 5,9 Juta',
        qualification: 'Jurusan Bisnis Manajemen/Logistik BLK, teliti dalam audit stok dan input ERP.',
        type: 'Full-Time',
        deadline: '28 Sep 2026',
        badges: ['⏱ Fresh Graduate Welcomed', '📦 SAP Dasar'],
        description: 'Mengelola pencatatan keluar-masuk barang farmasi dan menjaga akurasi persediaan gudang distribusi.',
      ),
    ];
  }
}
