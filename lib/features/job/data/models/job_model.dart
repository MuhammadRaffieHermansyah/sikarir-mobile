import 'package:sikarir/core/constants/api_constants.dart';

class JobVacancyModel {
  final String id;
  final String title;
  final String companyName;
  final String companyLogo;
  final String location;
  final String salary;
  final String qualification;
  final String type; // 'Full-Time', 'Magang', 'Kontrak'
  final String deadline;
  final List<String> badges;
  final String description;
  final bool isBookmarked;

  JobVacancyModel({
    required this.id,
    required this.title,
    required this.companyName,
    required this.companyLogo,
    required this.location,
    required this.salary,
    required this.qualification,
    required this.type,
    required this.deadline,
    this.badges = const [],
    required this.description,
    this.isBookmarked = false,
  });

  factory JobVacancyModel.fromMap(Map<String, dynamic> map) {
    final mitra = map['mitra'];

    // Nama Perusahaan
    String cName = 'Mitra BLK';
    if (mitra is Map) {
      cName = (mitra['nama_perusahaan'] ?? mitra['nama_mitra'] ?? mitra['nama'] ?? 'Mitra BLK').toString();
    } else {
      cName = (map['nama_perusahaan'] ?? map['perusahaan'] ?? map['company'] ?? 'Mitra BLK').toString();
    }

    // Logo Perusahaan
    String cLogo = '';
    if (mitra is Map) {
      cLogo = (mitra['logo_perusahaan'] ?? mitra['logo'] ?? mitra['logo_url'] ?? '').toString();
    }
    if (cLogo.isEmpty) {
      cLogo = (map['logo_perusahaan'] ?? map['logo'] ?? map['logo_url'] ?? '').toString();
    }
    if (cLogo.isNotEmpty && !cLogo.startsWith('http')) {
      cLogo = 'http://${ApiConstants.ipConfig}:8000/storage/$cLogo';
    }
    if (cLogo.isEmpty) {
      cLogo = 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=100&auto=format&fit=crop&q=80';
    }

    // Lokasi
    String loc = (map['lokasi'] ?? map['location'] ?? '').toString();
    if (loc.isEmpty && mitra is Map) {
      final kota = mitra['kota'] ?? '';
      final prov = mitra['provinsi'] ?? '';
      loc = [kota, prov].where((s) => s.toString().isNotEmpty).join(', ');
    }
    if (loc.isEmpty) loc = 'Indonesia';

    // Badges / Tags
    final rawBadges = map['badges'] ?? map['tag'] ?? [];
    List<String> bList = [];
    if (rawBadges is List) {
      bList = rawBadges
          .map((e) => e is Map ? (e['text'] ?? '').toString() : e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (bList.isEmpty) {
      if (map['status'] != null && map['status'].toString().isNotEmpty) {
        bList.add(map['status'] == 'aktif' ? '🟢 Rekrutmen Aktif' : 'Status: ${map['status']}');
      }
      bList.add('⚡ Jalur Khusus BLK');
    }

    // Deadline / Tanggal Posting
    String dl = (map['batas_lamaran'] ?? map['deadline'] ?? map['tanggal_kadaluarsa'] ?? '').toString();
    if (dl.isEmpty && map['tanggal_posting'] != null) {
      dl = 'Diposting: ${map['tanggal_posting']}';
    }
    if (dl.isEmpty) dl = '30 Hari Lagi';

    return JobVacancyModel(
      id: (map['id_lowongan'] ?? map['id'] ?? map['_id'] ?? '').toString(),
      title: (map['judul_lowongan'] ?? map['posisi'] ?? map['judul'] ?? map['title'] ?? 'Lowongan Pekerjaan').toString(),
      companyName: cName,
      companyLogo: cLogo,
      location: loc,
      salary: (map['gaji'] ?? map['salary'] ?? map['estimasi_gaji'] ?? 'Gaji Kompetitif').toString(),
      qualification: (map['kualifikasi'] ?? map['qualification'] ?? 'Lulusan pelatihan vokasi BLK').toString(),
      type: (map['tipe'] ?? map['type'] ?? map['jenis_pekerjaan'] ?? 'Full-Time').toString(),
      deadline: dl,
      badges: bList,
      description: (map['deskripsi'] ?? map['description'] ?? 'Peluang karir eksklusif bagi alumni dan peserta pelatihan BLK Connect.').toString(),
      isBookmarked: map['is_bookmarked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'posisi': title,
      'perusahaan': companyName,
      'logo': companyLogo,
      'lokasi': location,
      'gaji': salary,
      'kualifikasi': qualification,
      'tipe': type,
      'batas_lamaran': deadline,
      'badges': badges,
      'deskripsi': description,
    };
  }

  JobVacancyModel copyWith({bool? isBookmarked}) {
    return JobVacancyModel(
      id: id,
      title: title,
      companyName: companyName,
      companyLogo: companyLogo,
      location: location,
      salary: salary,
      qualification: qualification,
      type: type,
      deadline: deadline,
      badges: badges,
      description: description,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
