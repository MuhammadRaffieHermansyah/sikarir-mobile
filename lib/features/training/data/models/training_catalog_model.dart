import 'package:sikarir/core/constants/api_constants.dart';

class TrainingCatalogModel {
  final String id;
  final String? jadwalId;
  final String title;
  final String description;
  final String category;
  final String skkniCode;
  final String badge;
  final String duration;
  final String location;
  final int quota;
  final int enrolledCount;
  final int remainingQuota;
  final String instructor;
  final String startDate;
  final String endDate;
  final String benefitTitle;
  final String benefitDesc;
  final String imageUrl;
  final String status;
  final bool isEnrolled;

  TrainingCatalogModel({
    required this.id,
    this.jadwalId,
    required this.title,
    required this.description,
    required this.category,
    required this.skkniCode,
    required this.badge,
    required this.duration,
    required this.location,
    required this.quota,
    this.enrolledCount = 0,
    required this.remainingQuota,
    required this.instructor,
    required this.startDate,
    required this.endDate,
    this.benefitTitle = 'BEASISWA APBN',
    this.benefitDesc = '100% Gratis & Uang Saku Harian',
    required this.imageUrl,
    this.status = 'tersedia',
    this.isEnrolled = false,
  });

  factory TrainingCatalogModel.fromMap(Map<String, dynamic> map) {
    final idPelatihan = (map['id_pelatihan'] ?? map['id'] ?? map['_id'] ?? '').toString();

    // Check if jadwal relation or nested object is present
    Map<String, dynamic>? firstJadwal;
    if (map['jadwal'] is List && (map['jadwal'] as List).isNotEmpty) {
      firstJadwal = (map['jadwal'] as List).first as Map<String, dynamic>?;
    } else if (map['jadwal'] is Map<String, dynamic>) {
      firstJadwal = map['jadwal'] as Map<String, dynamic>?;
    }

    final idJadwal = (map['id_jadwal'] ?? firstJadwal?['id_jadwal'])?.toString();

    final durasiObj = map['durasi'];
    String durationStr = '40 JP (Intensif)';
    if (durasiObj is Map) {
      final hari = durasiObj['hari'];
      final jam = durasiObj['jam'];
      if (hari != null && jam != null) {
        durationStr = '$hari Hari ($jam JP)';
      } else if (durasiObj['durasi_label'] != null) {
        durationStr = durasiObj['durasi_label'].toString();
      }
    } else if (map['durasi_label'] != null) {
      durationStr = map['durasi_label'].toString();
    } else if (map['duration'] != null) {
      durationStr = map['duration'].toString();
    }

    final totalQuota = (map['kuota'] ?? map['quota'] ?? 20) as num;
    final terisi = (map['terisi'] ?? map['enrolled_count'] ?? (firstJadwal?['terisi'] ?? 0)) as num;
    final sisa = (map['sisa_kuota'] ?? map['remaining_quota'] ?? (totalQuota - terisi).clamp(0, totalQuota)).toInt();

    final instrukturObj = firstJadwal?['instruktur'] ?? map['instruktur'];
    String namaInstruktur = 'Instruktur Ahli BLK';
    if (instrukturObj is Map) {
      final user = instrukturObj['user'] as Map<String, dynamic>?;
      namaInstruktur = (user?['name'] ?? instrukturObj['nama'] ?? instrukturObj['name'] ?? 'Instruktur Ahli BLK').toString();
    } else if (instrukturObj != null && instrukturObj.toString().isNotEmpty) {
      namaInstruktur = instrukturObj.toString();
    }

    final rawImage = map['gambar_url'] ?? map['image'] ?? map['gambar'] ?? '';
    final defaultImage = _getDefaultImage(map['nama_pelatihan'] ?? map['title'] ?? '');

    final nama = (map['nama_pelatihan'] ?? map['title'] ?? 'Pelatihan BLK').toString();
    final kategori = (map['kategori'] ?? map['kejuruan'] ?? _guessCategory(nama)).toString();

    return TrainingCatalogModel(
      id: idPelatihan,
      jadwalId: idJadwal,
      title: nama,
      description: (map['deskripsi_pelatihan'] ?? map['deskripsi'] ?? map['desc'] ?? 'Pelatihan berbasis kompetensi industri standar SKKNI & BNSP.').toString(),
      category: kategori,
      skkniCode: (map['skkni_code'] ?? map['skkniCode'] ?? 'SKKNI Standar Kemnaker RI • Lisensi BNSP').toString(),
      badge: (map['badge'] ?? 'Sertifikasi BNSP').toString(),
      duration: durationStr,
      location: (firstJadwal?['tempat'] ?? map['tempat'] ?? map['location'] ?? 'BLK Jember, Jawa Timur').toString(),
      quota: totalQuota.toInt(),
      enrolledCount: terisi.toInt(),
      remainingQuota: sisa,
      instructor: namaInstruktur,
      startDate: (firstJadwal?['tanggal_mulai'] ?? map['tanggal_mulai'] ?? 'Segera').toString(),
      endDate: (firstJadwal?['tanggal_selesai'] ?? map['tanggal_selesai'] ?? '').toString(),
      benefitTitle: (map['benefit_title'] ?? map['benefitTitle'] ?? 'BEASISWA APBN').toString(),
      benefitDesc: (map['benefit_desc'] ?? map['benefitDesc'] ?? '100% Gratis & Uang Saku Harian').toString(),
      imageUrl: (rawImage != null && rawImage.toString().trim().isNotEmpty)
          ? ApiConstants.fullImageUrl(rawImage.toString())
          : defaultImage,
      status: (firstJadwal?['status'] ?? map['status'] ?? 'tersedia').toString().toLowerCase(),
      isEnrolled: map['is_enrolled'] == true,
    );
  }

  static String _guessCategory(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('web') ||
        lower.contains('desain') ||
        lower.contains('ui/ux') ||
        lower.contains('data') ||
        lower.contains('komputer') ||
        lower.contains('it') ||
        lower.contains('flutter') ||
        lower.contains('android') ||
        lower.contains('program') ||
        lower.contains('coding') ||
        lower.contains('software') ||
        lower.contains('developer')) {
      return 'TIK & INFORMATIKA';
    } else if (lower.contains('las') ||
        lower.contains('mesin') ||
        lower.contains('manufaktur') ||
        lower.contains('bubut') ||
        lower.contains('welding')) {
      return 'MANUFAKTUR & LAS';
    } else if (lower.contains('motor') ||
        lower.contains('mobil') ||
        lower.contains('otomotif') ||
        lower.contains('listrik') ||
        lower.contains('ev')) {
      return 'OTOMOTIF MODERN';
    } else if (lower.contains('bisnis') ||
        lower.contains('pemasaran') ||
        lower.contains('marketing') ||
        lower.contains('administrasi') ||
        lower.contains('manajemen')) {
      return 'BISNIS & MANAJEMEN';
    }
    return 'PELATIHAN VOKASI';
  }

  static String _getDefaultImage(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('las') || lower.contains('welding')) {
      return 'https://images.unsplash.com/photo-1504917599217-d4dc5ebe6122?w=800&auto=format&fit=crop&q=80';
    } else if (lower.contains('otomotif') || lower.contains('kendaraan') || lower.contains('motor') || lower.contains('listrik')) {
      return 'https://images.unsplash.com/photo-1617788138017-80ad40651399?w=800&auto=format&fit=crop&q=80';
    } else if (lower.contains('web') || lower.contains('programming') || lower.contains('coding')) {
      return 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=800&auto=format&fit=crop&q=80';
    } else if (lower.contains('desain') || lower.contains('grafis') || lower.contains('ui/ux')) {
      return 'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800&auto=format&fit=crop&q=80';
    }
    return 'https://images.unsplash.com/photo-1524178232363-1fb2b075b655?w=800&auto=format&fit=crop&q=80';
  }

  TrainingCatalogModel copyWith({
    String? id,
    String? jadwalId,
    String? title,
    String? description,
    String? category,
    String? skkniCode,
    String? badge,
    String? duration,
    String? location,
    int? quota,
    int? enrolledCount,
    int? remainingQuota,
    String? instructor,
    String? startDate,
    String? endDate,
    String? benefitTitle,
    String? benefitDesc,
    String? imageUrl,
    String? status,
    bool? isEnrolled,
  }) {
    return TrainingCatalogModel(
      id: id ?? this.id,
      jadwalId: jadwalId ?? this.jadwalId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      skkniCode: skkniCode ?? this.skkniCode,
      badge: badge ?? this.badge,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      quota: quota ?? this.quota,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      remainingQuota: remainingQuota ?? this.remainingQuota,
      instructor: instructor ?? this.instructor,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      benefitTitle: benefitTitle ?? this.benefitTitle,
      benefitDesc: benefitDesc ?? this.benefitDesc,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      isEnrolled: isEnrolled ?? this.isEnrolled,
    );
  }
}
