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
    final rawBadges = map['badges'] ?? map['tag'] ?? [];
    List<String> bList = [];
    if (rawBadges is List) {
      bList = rawBadges.map((e) => e is Map ? (e['text'] ?? '').toString() : e.toString()).toList();
    }

    return JobVacancyModel(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      title: (map['posisi'] ?? map['judul'] ?? map['title'] ?? 'Lowongan Pekerjaan').toString(),
      companyName: (map['perusahaan'] ?? map['nama_perusahaan'] ?? map['company'] ?? 'Mitra BLK').toString(),
      companyLogo: (map['logo'] ?? map['logo_url'] ?? 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=100&auto=format&fit=crop&q=80').toString(),
      location: (map['lokasi'] ?? map['location'] ?? 'Indonesia').toString(),
      salary: (map['gaji'] ?? map['salary'] ?? 'Gaji Kompetitif').toString(),
      qualification: (map['kualifikasi'] ?? map['qualification'] ?? 'Lulusan pelatihan vokasi BLK').toString(),
      type: (map['tipe'] ?? map['type'] ?? 'Full-Time').toString(),
      deadline: (map['batas_lamaran'] ?? map['deadline'] ?? '30 Hari Lagi').toString(),
      badges: bList.isNotEmpty ? bList : ['⚡ Jalur Khusus Peserta BLK', '🎓 Sertifikat BNSP'],
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
